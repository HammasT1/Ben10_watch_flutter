import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../models/effect_seeds.dart';
import '../models/watch_phase.dart';
import '../painters/bubble_painter.dart';
import '../painters/ring_pulse_painter.dart';
import '../painters/shockwave_painter.dart';
import '../painters/spark_painter.dart';
import '../widgets/transformed_view.dart';

class OmnitrixScreen extends StatefulWidget {
  const OmnitrixScreen({super.key});

  @override
  State<OmnitrixScreen> createState() => _OmnitrixScreenState();
}

class _OmnitrixScreenState extends State<OmnitrixScreen>
    with TickerProviderStateMixin {
  static const _watchAsset = 'assets/images/classic_watch.jpg';

  static const _transformDuration = Duration(milliseconds: 1400);
  static const _timeoutDuration = Duration(seconds: 15);
  static const _rechargeDuration = Duration(seconds: 8);

  /// Point in the transform animation where the flash peaks and the
  /// transformed view replaces the watch.
  static const _transformPeak = 0.47;

  /// Tap radius of the core, as a fraction of the watch size.
  static const _coreTapRadius = 0.2;

  /// Flicks slower than this (rad/s) just snap to the nearest slot.
  static const _minFlingVelocity = 1.2;

  /// Hard cap on flick speed so a wild swipe can't spin forever.
  static const _maxFlingVelocity = 24.0;

  /// Friction used to project where a flick would coast to. Lower = coasts
  /// further (a 10 rad/s flick travels roughly 10 / -ln(drag) radians).
  static const _dialDrag = 0.06;

  /// Spring that carries the flick and settles on a slot with a small
  /// overshoot, like a detent clicking into place.
  static final _dialSpring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 34,
    ratio: 0.78,
  );

  static const _green = Color(0xFF1FFF8B);
  static const _red = Color(0xFFFF3B3B);

  final List<String> _aliens = List.generate(
    11,
    (i) => 'assets/images/${i + 1}.png',
  );

  final math.Random _random = math.Random();
  final List<SparkSeed> _sparks = [];
  final List<BubbleSeed> _bubbles = [];

  late final AnimationController _changeController;
  late final AnimationController _pulseController;
  late final AnimationController _ambientController;
  late final AnimationController _titleController;
  late final AnimationController _transformController;
  late final AnimationController _timeoutController;
  late final AnimationController _rechargeController;

  /// Unbounded controller whose value is the dial angle while it coasts.
  late final AnimationController _dialController;
  late final Animation<double> _flashAnimation;

  WatchPhase _phase = WatchPhase.idle;
  double _dialAngle = 0;
  double _previousDragAngle = 0;
  Offset _lastDragPosition = Offset.zero;

  /// True when a touch landed on a coasting dial: that touch catches the
  /// dial and must not also count as a core tap.
  bool _touchCaughtSpin = false;
  int _selectedAlien = 0;

  @override
  void initState() {
    super.initState();
    _changeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 430),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5200),
    )..repeat();
    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _transformController = AnimationController(
      vsync: this,
      duration: _transformDuration,
    )..addListener(_onTransformTick);
    _timeoutController =
        AnimationController(vsync: this, duration: _timeoutDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed &&
                _phase == WatchPhase.transformed) {
              _enterRecharge();
            }
          });
    _rechargeController =
        AnimationController(vsync: this, duration: _rechargeDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed &&
                _phase == WatchPhase.recharging) {
              setState(() => _phase = WatchPhase.idle);
            }
          });

    _dialController = AnimationController.unbounded(vsync: this)
      ..addListener(_onDialTick);

    _flashAnimation = CurvedAnimation(
      parent: _changeController,
      curve: Curves.easeOutCubic,
    );

    _resetSparkSeeds();
    _resetBubbleSeeds();
  }

  @override
  void dispose() {
    _changeController.dispose();
    _pulseController.dispose();
    _ambientController.dispose();
    _titleController.dispose();
    _transformController.dispose();
    _timeoutController.dispose();
    _rechargeController.dispose();
    _dialController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Phase transitions
  // ---------------------------------------------------------------------------

  void _startTransform() {
    if (_phase != WatchPhase.idle) return;
    setState(() => _phase = WatchPhase.transforming);
    _resetSparkSeeds();
    _changeController.forward(from: 0);
    _transformController.forward(from: 0);
  }

  void _onTransformTick() {
    if (_phase == WatchPhase.transforming &&
        _transformController.value >= _transformPeak) {
      setState(() => _phase = WatchPhase.transformed);
      _timeoutController.forward(from: 0);
    }
  }

  void _revert() {
    if (_phase != WatchPhase.transformed) return;
    _timeoutController.stop();
    setState(() => _phase = WatchPhase.idle);
  }

  void _enterRecharge() {
    setState(() => _phase = WatchPhase.recharging);
    _rechargeController.forward(from: 0);
  }

  /// 0..1 charge-up before the flash peak; 0 outside the transform.
  double get _charge {
    if (_phase != WatchPhase.transforming) return 0;
    return (_transformController.value / _transformPeak).clamp(0.0, 1.0);
  }

  // ---------------------------------------------------------------------------
  // Seeds
  // ---------------------------------------------------------------------------

  void _resetSparkSeeds() {
    _sparks
      ..clear()
      ..addAll(
        List.generate(
          24,
          (_) => SparkSeed(
            angle: _random.nextDouble() * math.pi * 2,
            radiusFactor: 0.45 + (_random.nextDouble() * 0.7),
            size: 2 + (_random.nextDouble() * 4),
          ),
        ),
      );
  }

  void _resetBubbleSeeds() {
    _bubbles
      ..clear()
      ..addAll(
        List.generate(
          30,
          (_) => BubbleSeed(
            xFactor: _random.nextDouble(),
            phase: _random.nextDouble(),
            speed: 0.45 + (_random.nextDouble() * 0.95),
            size: 3 + (_random.nextDouble() * 10),
            sway: 8 + (_random.nextDouble() * 22),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------

  void _onPanStart(DragStartDetails details, Size size) {
    // Grabbing a coasting dial catches it where it is.
    _touchCaughtSpin = false;
    _dialController.stop();
    _lastDragPosition = details.localPosition;
    _previousDragAngle = _pointerAngle(
      details.localPosition,
      size.center(Offset.zero),
    );
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_phase != WatchPhase.idle) return;
    final center = size.center(Offset.zero);
    final currentDragAngle = _pointerAngle(details.localPosition, center);
    final delta = _normalizeAngle(currentDragAngle - _previousDragAngle);
    _previousDragAngle = currentDragAngle;
    _lastDragPosition = details.localPosition;

    setState(() {
      _dialAngle += delta;
    });

    _updateAlienSelection();
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    if (_phase != WatchPhase.idle) return;

    // Angular velocity = (r x v) / |r|^2, using the last pointer position
    // relative to the dial centre. Same sign convention as atan2 above.
    final r = _lastDragPosition - size.center(Offset.zero);
    final v = details.velocity.pixelsPerSecond;
    final r2 = r.distanceSquared;
    var omega = r2 < 1 ? 0.0 : ((r.dx * v.dy) - (r.dy * v.dx)) / r2;
    if (omega.abs() < _minFlingVelocity) omega = 0;
    omega = omega.clamp(-_maxFlingVelocity, _maxFlingVelocity);

    _settleDial(velocity: omega);
  }

  /// A touch that never became a drag (a tap). Flutter reports this before
  /// the tap itself, so this is where we learn the dial was still moving.
  void _onPanCancel() {
    if (_phase != WatchPhase.idle) return;
    _touchCaughtSpin = _dialController.isAnimating;
    _settleDial();
  }

  /// Springs the dial from its current angle to a slot, carrying [velocity].
  void _settleDial({double velocity = 0}) {
    final coastTo = velocity == 0
        ? _dialAngle
        : FrictionSimulation(_dialDrag, _dialAngle, velocity).finalX;
    final target = _nearestSlotAngle(coastTo);

    // Already resting on a slot (e.g. a plain tap reports as a cancelled
    // pan): don't start a zero-length spring that would block the core tap.
    if (velocity == 0 && (target - _dialAngle).abs() < 1e-3) {
      _dialController.stop();
      return;
    }

    _dialController.value = _dialAngle;
    _dialController.animateWith(
      SpringSimulation(_dialSpring, _dialAngle, target, velocity),
    );
  }

  void _onDialTick() {
    setState(() => _dialAngle = _dialController.value);
    _updateAlienSelection();
  }

  double get _slice => (math.pi * 2) / _aliens.length;

  double _nearestSlotAngle(double angle) {
    return (angle / _slice).round() * _slice;
  }

  void _onTapUp(TapUpDetails details, Size size) {
    // The dial has to come to rest before the core will trigger; a tap on a
    // spinning dial just catches it.
    final caught = _touchCaughtSpin || _dialController.isAnimating;
    _touchCaughtSpin = false;
    if (caught) return;
    final distance =
        (details.localPosition - size.center(Offset.zero)).distance;
    if (distance <= size.width * _coreTapRadius) {
      _startTransform();
    }
  }

  double _pointerAngle(Offset point, Offset center) {
    final vector = point - center;
    return math.atan2(vector.dy, vector.dx);
  }

  double _normalizeAngle(double value) {
    if (value > math.pi) {
      return value - (math.pi * 2);
    }
    if (value < -math.pi) {
      return value + (math.pi * 2);
    }
    return value;
  }

  void _updateAlienSelection() {
    final normalized = _dialAngle % (math.pi * 2);
    var index = (-normalized / _slice).round() % _aliens.length;
    if (index < 0) {
      index += _aliens.length;
    }

    if (index != _selectedAlien) {
      setState(() {
        _selectedAlien = index;
      });
      _resetSparkSeeds();
      _changeController.forward(from: 0);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [Color(0xFF113C25), Color(0xFF081A10), Color(0xFF010302)],
          ),
        ),
        child: Stack(
          children: [
            // Only the bubble layer repaints on the ambient tick.
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) => CustomPaint(
                    painter: BubblePainter(
                      bubbles: _bubbles,
                      t: _ambientController.value,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: _phase == WatchPhase.transformed
                  ? TransformedView(
                      alienAsset: _aliens[_selectedAlien],
                      label: 'ALIEN ${_selectedAlien + 1}',
                      timeout: _timeoutController,
                      totalSeconds: _timeoutDuration.inSeconds,
                      onRevert: _revert,
                    )
                  : _buildWatchLayout(),
            ),
            Positioned.fill(child: IgnorePointer(child: _buildScreenEffects())),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final watchSize =
            math.min(constraints.maxWidth, constraints.maxHeight) * 0.86;
        final watchBox = Size.square(watchSize);
        // Built once per setState (dial turn), not once per frame.
        final watchImage = RepaintBoundary(
          child: _buildWatchImage(size: watchSize),
        );

        return Column(
          children: [
            const SizedBox(height: 12),
            _buildTitle(),
            Expanded(
              child: Center(
                child: GestureDetector(
                  key: const Key('watch-dial'),
                  onPanStart: (d) => _onPanStart(d, watchBox),
                  onPanUpdate: (d) => _onPanUpdate(d, watchBox),
                  onPanEnd: (d) => _onPanEnd(d, watchBox),
                  onPanCancel: _onPanCancel,
                  onTapUp: (d) => _onTapUp(d, watchBox),
                  child: SizedBox(
                    width: watchSize,
                    height: watchSize,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        _pulseController,
                        _changeController,
                        _transformController,
                        _rechargeController,
                      ]),
                      child: watchImage,
                      builder: (context, watch) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            watch!,
                            _buildRechargeTint(size: watchSize),
                            _buildPulseRings(size: watchSize),
                            _buildAlienView(size: watchSize),
                            _buildEnergySparks(size: watchSize),
                            _buildFlashCore(size: watchSize),
                            _buildHudText(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            _buildHint(),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _titleController,
      builder: (context, _) {
        final v = _titleController.value;
        final glow = 0.35 + (v * 0.65);
        final slideY = (1 - Curves.easeOut.transform(v)) * 18;
        return Transform.translate(
          offset: Offset(0, slideY),
          child: Opacity(
            opacity: 0.7 + (v * 0.3),
            child: Text(
              'BEN 10 WATCH',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: const Color(0xFF9BFFAE),
                shadows: [
                  Shadow(
                    color: const Color(0xFF17FF73).withValues(alpha: glow),
                    blurRadius: 24,
                  ),
                  Shadow(
                    color: const Color(0xFF17FF73).withValues(alpha: 0.5),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWatchImage({required double size}) {
    final spin = _dialAngle * 0.18;
    return Transform.rotate(
      angle: spin,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.24),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipOval(child: Image.asset(_watchAsset, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildRechargeTint({required double size}) {
    if (_phase != WatchPhase.recharging) return const SizedBox.shrink();
    final pulse = 0.5 + 0.5 * math.sin(_pulseController.value * math.pi * 2);
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _red.withValues(alpha: 0.22 + (pulse * 0.14)),
          boxShadow: [
            BoxShadow(
              color: _red.withValues(alpha: 0.25 + (pulse * 0.2)),
              blurRadius: 30,
              spreadRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlienView({required double size}) {
    final flash = _flashAnimation.value;
    final charge = _charge;
    final recharging = _phase == WatchPhase.recharging;

    // Idle shows a dark silhouette; charging lights it up; recharge is red.
    final tint = recharging
        ? const Color(0xFF3A0A0A)
        : Color.lerp(const Color(0xFF03140A), const Color(0xFFD8FFE4), charge)!;

    return Align(
      alignment: const Alignment(0.0, 0.01),
      child: SizedBox(
        width: size * 0.33,
        height: size * 0.33,
        child: Opacity(
          opacity: recharging ? 0.6 : 1,
          child: Transform.scale(
            scale: 1.12 + (flash * 0.05) + (charge * 0.22),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
              child: Image.asset(
                _aliens[_selectedAlien],
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.question_mark,
                      color: Color(0xFF7FFF9E),
                      size: 34,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRings({required double size}) {
    final recharging = _phase == WatchPhase.recharging;
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: RingPulsePainter(
          t: _pulseController.value,
          intensity: math.max(_flashAnimation.value, _charge),
          color: recharging ? _red : _green,
        ),
      ),
    );
  }

  Widget _buildFlashCore({required double size}) {
    final flash = math.max(_flashAnimation.value, _charge);
    if (flash <= 0.01) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Container(
        width: size * (0.30 + (flash * 0.06)),
        height: size * (0.30 + (flash * 0.06)),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF98FFB7).withValues(alpha: 0.55 * flash),
              const Color(0xFF22FF81).withValues(alpha: 0.35 * flash),
              Colors.transparent,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildEnergySparks({required double size}) {
    if (_changeController.value == 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: SparkPainter(sparks: _sparks, progress: _flashAnimation.value),
      ),
    );
  }

  Widget _buildHudText() {
    final String text;
    final Color color;
    switch (_phase) {
      case WatchPhase.transforming:
        text = 'TRANSFORMING';
        color = const Color(0xFFD8FFE4);
      case WatchPhase.recharging:
        final remaining =
            (1 - _rechargeController.value) * _rechargeDuration.inSeconds;
        text = 'RECHARGING ${remaining.ceil()}s';
        color = const Color(0xFFFF8A8A);
      case WatchPhase.idle:
      case WatchPhase.transformed:
        text = 'ALIEN ${_selectedAlien + 1}';
        color = const Color(0xFF91FFA8);
    }
    return Positioned(
      bottom: 18,
      child: Opacity(
        opacity: 0.9,
        child: Text(
          text,
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildHint() {
    return AnimatedOpacity(
      opacity: _phase == WatchPhase.idle ? 0.75 : 0,
      duration: const Duration(milliseconds: 250),
      child: const Text(
        'TURN THE DIAL  •  TAP THE CORE',
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 2.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF91FFA8),
        ),
      ),
    );
  }

  /// Full-screen flash + shockwave during transform, red flash on timeout.
  Widget _buildScreenEffects() {
    return AnimatedBuilder(
      animation: Listenable.merge([_transformController, _rechargeController]),
      builder: (context, _) {
        final layers = <Widget>[];

        if (_transformController.isAnimating) {
          final v = _transformController.value;
          final distance = ((v - _transformPeak).abs() / 0.22).clamp(0.0, 1.0);
          final flash = 1 - (distance * distance);
          final wave = ((v - 0.4) / 0.6).clamp(0.0, 1.0);

          if (wave > 0 && wave < 1) {
            layers.add(
              CustomPaint(
                painter: ShockwavePainter(progress: wave, color: _green),
              ),
            );
          }
          if (flash > 0) {
            layers.add(
              ColoredBox(
                color: const Color(0xFFCCFFDD).withValues(alpha: flash * 0.9),
              ),
            );
          }
        }

        if (_phase == WatchPhase.recharging) {
          final redFlash = (1 - (_rechargeController.value * 10)).clamp(
            0.0,
            1.0,
          );
          if (redFlash > 0) {
            layers.add(
              ColoredBox(color: _red.withValues(alpha: redFlash * 0.55)),
            );
          }
        }

        return Stack(fit: StackFit.expand, children: layers);
      },
    );
  }
}
