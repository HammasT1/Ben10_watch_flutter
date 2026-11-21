import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Everything the watch can make the user hear or feel.
enum WatchEvent {
  /// Dial passed an alien slot.
  dialTick,

  /// Core tapped: charge-up into the transform flash.
  transformStart,

  /// Flash peak, alien is now active.
  transformed,

  /// One of the last few seconds of the countdown.
  timeoutWarning,

  /// Countdown ran out, watch locks.
  timedOut,

  /// Recharge finished, watch usable again.
  rechargeReady,

  /// User reverted manually.
  reverted,

  /// Core tapped while the watch is locked.
  denied,
}

/// Plays sound + haptics for [WatchEvent]s. Swappable so tests (and a future
/// settings screen) can replace or silence it.
abstract class WatchFeedback {
  bool get muted;
  set muted(bool value);

  void play(WatchEvent event);

  Future<void> dispose();
}

/// Feedback that does nothing; useful for tests.
class SilentWatchFeedback implements WatchFeedback {
  SilentWatchFeedback();

  final List<WatchEvent> played = [];

  @override
  bool muted = false;

  @override
  void play(WatchEvent event) => played.add(event);

  @override
  Future<void> dispose() async {}
}

/// Real implementation: short sound effects via audioplayers + platform
/// haptics. Sound files live in `assets/sounds/` and can be replaced with
/// real recordings without touching code.
class DeviceWatchFeedback implements WatchFeedback {
  DeviceWatchFeedback() {
    unawaited(_init());
  }

  static const _files = {
    WatchEvent.dialTick: 'sounds/dial_click.wav',
    WatchEvent.transformStart: 'sounds/transform.wav',
    WatchEvent.timeoutWarning: 'sounds/warning_beep.wav',
    WatchEvent.timedOut: 'sounds/timeout.wav',
    WatchEvent.rechargeReady: 'sounds/recharge_ready.wav',
    WatchEvent.reverted: 'sounds/revert.wav',
    WatchEvent.denied: 'sounds/denied.wav',
  };

  /// Dial ticks can fire many times a second during a flick, so they get a
  /// few players to overlap and a minimum gap so they don't turn into noise.
  static const _tickPlayers = 4;
  static const _minTickGap = Duration(milliseconds: 35);

  final Map<WatchEvent, List<AudioPlayer>> _players = {};
  final Map<WatchEvent, int> _nextPlayer = {};
  final Stopwatch _sinceTick = Stopwatch()..start();
  bool _ready = false;
  bool _disposed = false;

  @override
  bool muted = false;

  Future<void> _init() async {
    try {
      // Mix with the user's music instead of pausing it.
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
      await AudioCache.instance.loadAll(_files.values.toList());
      for (final event in _files.keys) {
        final count = event == WatchEvent.dialTick ? _tickPlayers : 1;
        _players[event] = [
          for (var i = 0; i < count; i++) await _createPlayer(),
        ];
        _nextPlayer[event] = 0;
      }
      _ready = !_disposed;
    } catch (error) {
      // Audio is a nice-to-have; never let it break the watch.
      debugPrint('WatchFeedback: audio unavailable ($error)');
    }
  }

  Future<AudioPlayer> _createPlayer() async {
    final player = AudioPlayer();
    await player.setPlayerMode(PlayerMode.lowLatency);
    await player.setReleaseMode(ReleaseMode.stop);
    return player;
  }

  @override
  void play(WatchEvent event) {
    if (event == WatchEvent.dialTick) {
      if (_sinceTick.elapsed < _minTickGap) return;
      _sinceTick.reset();
    }
    _haptic(event);
    if (!muted) _sound(event);
  }

  void _haptic(WatchEvent event) {
    switch (event) {
      case WatchEvent.dialTick:
        HapticFeedback.selectionClick();
      case WatchEvent.transformStart:
      case WatchEvent.rechargeReady:
      case WatchEvent.reverted:
        HapticFeedback.mediumImpact();
      case WatchEvent.transformed:
        HapticFeedback.heavyImpact();
      case WatchEvent.timeoutWarning:
        HapticFeedback.lightImpact();
      case WatchEvent.denied:
        HapticFeedback.heavyImpact();
      case WatchEvent.timedOut:
        HapticFeedback.heavyImpact();
        Future.delayed(
          const Duration(milliseconds: 180),
          HapticFeedback.heavyImpact,
        );
    }
  }

  void _sound(WatchEvent event) {
    final file = _files[event];
    final pool = _players[event];
    if (!_ready || file == null || pool == null) return;

    final index = _nextPlayer[event]!;
    _nextPlayer[event] = (index + 1) % pool.length;
    pool[index].play(AssetSource(file)).catchError((Object error) {
      debugPrint('WatchFeedback: failed to play $file ($error)');
    });
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _ready = false;
    for (final pool in _players.values) {
      for (final player in pool) {
        await player.dispose();
      }
    }
    _players.clear();
  }
}
