import 'package:flutter/material.dart';

import '../models/alien.dart';
import 'alien_image.dart';

/// Full-screen view shown while an alien is active, with the timeout
/// countdown, an info button and a manual revert button.
class TransformedView extends StatelessWidget {
  const TransformedView({
    super.key,
    required this.alien,
    required this.timeout,
    required this.totalSeconds,
    required this.onRevert,
    required this.onInfo,
  });

  final Alien alien;

  /// Runs 0 -> 1 over the transformation's lifetime.
  final Animation<double> timeout;
  final int totalSeconds;
  final VoidCallback onRevert;
  final VoidCallback onInfo;

  static const _red = Color(0xFFFF3B3B);
  static const _warningSeconds = 3;

  @override
  Widget build(BuildContext context) {
    final color = alien.color;
    final highlight = alienHighlight(color);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutBack,
      builder: (context, entry, child) {
        return Opacity(
          opacity: entry.clamp(0.0, 1.0),
          child: Transform.scale(scale: 0.6 + (entry * 0.4), child: child),
        );
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final alienSize =
              (constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth
                  : constraints.maxHeight) *
              0.62;
          return Column(
            children: [
              const SizedBox(height: 24),
              Text(
                alien.name.toUpperCase(),
                key: const Key('transformed-name'),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: highlight,
                  shadows: [Shadow(color: color, blurRadius: 24)],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                alien.species.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 3,
                  color: highlight.withValues(alpha: 0.7),
                ),
              ),
              Expanded(child: Center(child: _buildAlien(alienSize))),
              _buildCountdown(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onRevert,
                    style: _buttonStyle(color, highlight),
                    icon: const Icon(Icons.power_settings_new),
                    label: const Text(
                      'REVERT',
                      style: TextStyle(
                        letterSpacing: 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    key: const Key('transformed-info'),
                    onPressed: onInfo,
                    style: _buttonStyle(color, highlight),
                    child: const Icon(Icons.info_outline),
                  ),
                ],
              ),
              const SizedBox(height: 28),
            ],
          );
        },
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color, Color highlight) {
    return OutlinedButton.styleFrom(
      foregroundColor: highlight,
      side: BorderSide(color: color, width: 1.4),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
    );
  }

  Widget _buildAlien(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            alien.color.withValues(alpha: 0.35),
            alien.color.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: AlienImage(alien: alien, tint: alienHighlight(alien.color)),
    );
  }

  Widget _buildCountdown() {
    return AnimatedBuilder(
      animation: timeout,
      builder: (context, _) {
        final remaining = (1 - timeout.value).clamp(0.0, 1.0);
        final seconds = (remaining * totalSeconds).ceil();
        final warning = seconds <= _warningSeconds;
        // Blink twice per second during the warning window.
        final blinkOn = ((timeout.value * totalSeconds * 4).floor()).isEven;
        final color = warning ? _red : alien.color;

        return Opacity(
          opacity: warning && !blinkOn ? 0.35 : 1,
          child: SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CircularProgressIndicator(
                    value: remaining,
                    strokeWidth: 5,
                    color: color,
                    backgroundColor: color.withValues(alpha: 0.15),
                  ),
                ),
                Text(
                  '$seconds',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
