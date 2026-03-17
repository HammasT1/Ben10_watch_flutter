import 'dart:math' as math;

import 'package:flutter/material.dart';

void main() {
  runApp(const OmnitrixApp());
}

class OmnitrixApp extends StatelessWidget {
  const OmnitrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ben 10 Watch',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030706),
        useMaterial3: true,
      ),
      home: const OmnitrixScreen(),
    );
  }
}

class OmnitrixScreen extends StatefulWidget {
  const OmnitrixScreen({super.key});

  @override
  State<OmnitrixScreen> createState() => _OmnitrixScreenState();
}

class _OmnitrixScreenState extends State<OmnitrixScreen>
    with TickerProviderStateMixin {
  static const _watchAsset = 'assets/images/classic watch.jpg';

  final List<String> _aliens = List.generate(
    11,
    (i) => 'assets/images/${i + 1}.png',
  );

  final math.Random _random = math.Random();
  final List<_SparkSeed> _sparks = [];
  final List<_BubbleSeed> _bubbles = [];

  late final AnimationController _changeController;
  late final AnimationController _pulseController;
  late final AnimationController _ambientController;
  late final AnimationController _titleController;
  late final Animation<double> _flashAnimation;

  double _dialAngle = 0;
  double _previousDragAngle = 0;
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
    super.dispose();
  }

  void _resetSparkSeeds() {
    _sparks
      ..clear()
      ..addAll(
        List.generate(
          24,
          (_) => _SparkSeed(
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
          (_) => _BubbleSeed(
            xFactor: _random.nextDouble(),
            phase: _random.nextDouble(),
            speed: 0.45 + (_random.nextDouble() * 0.95),
            size: 3 + (_random.nextDouble() * 10),
            sway: 8 + (_random.nextDouble() * 22),
          ),
        ),
      );
  }

  void _onPanStart(DragStartDetails details, Size size) {
    _previousDragAngle = _pointerAngle(
      details.localPosition,
      size.center(Offset.zero),
    );
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    final center = size.center(Offset.zero);
    final currentDragAngle = _pointerAngle(details.localPosition, center);
    final delta = _normalizeAngle(currentDragAngle - _previousDragAngle);
    _previousDragAngle = currentDragAngle;

    setState(() {
      _dialAngle += delta;
    });

    _updateAlienSelection();
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
    final slice = (math.pi * 2) / _aliens.length;
    final normalized = _dialAngle % (math.pi * 2);
    var index = (-normalized / slice).round() % _aliens.length;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.2,
            colors: [Color(0xFF113C25), Color(0xFF081A10), Color(0xFF010302)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final watchSize =
                  math.min(constraints.maxWidth, constraints.maxHeight) * 0.86;
              return AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _BubblePainter(
                            bubbles: _bubbles,
                            t: _ambientController.value,
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 12),
                          _buildTitle(),
                          Expanded(
                            child: Center(
                              child: GestureDetector(
                                onPanStart: (details) => _onPanStart(
                                  details,
                                  Size.square(watchSize),
                                ),
                                onPanUpdate: (details) => _onPanUpdate(
                                  details,
                                  Size.square(watchSize),
                                ),
                                child: SizedBox(
                                  width: watchSize,
                                  height: watchSize,
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _pulseController,
                                      _changeController,
                                      _ambientController,
                                    ]),
                                    builder: (context, _) {
                                      return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          _buildWatchImage(size: watchSize),
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
                          const SizedBox(height: 16),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
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
              color: const Color(0xFF0FFF6A).withValues(alpha: 0.24),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: ClipOval(child: Image.asset(_watchAsset, fit: BoxFit.cover)),
      ),
    );
  }

  Widget _buildAlienView({required double size}) {
    final flash = _flashAnimation.value;
    return Align(
      alignment: const Alignment(0.0, 0.01),
      child: SizedBox(
        width: size * 0.33,
        height: size * 0.33,
        child: Transform.scale(
          scale: 1.12 + (flash * 0.05),
          child: Image.asset(
            _aliens[_selectedAlien],
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) {
              return const ColoredBox(
                color: Colors.transparent,
                child: Center(
                  child: Icon(
                    Icons.question_mark,
                    color: Color(0xFF7FFF9E),
                    size: 34,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPulseRings({required double size}) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _RingPulsePainter(
          t: _pulseController.value,
          flash: _flashAnimation.value,
        ),
      ),
    );
  }

  Widget _buildFlashCore({required double size}) {
    final flash = _flashAnimation.value;
    if (flash <= 0.01) {
      return const SizedBox.shrink();
    }
    return Container(
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
    );
  }

  Widget _buildEnergySparks({required double size}) {
    if (_changeController.value == 0) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: CustomPaint(
        size: Size.square(size),
        painter: _SparkPainter(
          sparks: _sparks,
          progress: _flashAnimation.value,
        ),
      ),
    );
  }

  Widget _buildHudText() {
    return Positioned(
      bottom: 18,
      child: Opacity(
        opacity: 0.9,
        child: Text(
          'ALIEN ${_selectedAlien + 1}',
          style: const TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: Color(0xFF91FFA8),
          ),
        ),
      ),
    );
  }
}

class _BubbleSeed {
  const _BubbleSeed({
    required this.xFactor,
    required this.phase,
    required this.speed,
    required this.size,
    required this.sway,
  });

  final double xFactor;
  final double phase;
  final double speed;
  final double size;
  final double sway;
}

class _SparkSeed {
  const _SparkSeed({
    required this.angle,
    required this.radiusFactor,
    required this.size,
  });

  final double angle;
  final double radiusFactor;
  final double size;
}

class _BubblePainter extends CustomPainter {
  const _BubblePainter({required this.bubbles, required this.t});

  final List<_BubbleSeed> bubbles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    for (final bubble in bubbles) {
      final cycle = ((t * bubble.speed) + bubble.phase) % 1.0;
      final y = size.height * (1 - cycle);
      final drift =
          math.sin((cycle * math.pi * 2) + bubble.phase) * bubble.sway;
      final x = (size.width * bubble.xFactor) + drift;
      final alpha = (0.08 + (0.25 * (1 - cycle))).clamp(0.0, 1.0);

      final fillPaint = Paint()
        ..color = const Color(0xFF4CFF97).withValues(alpha: alpha)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(Offset(x, y), bubble.size, fillPaint);

      final ringPaint = Paint()
        ..color = const Color(0xFF98FFBE).withValues(alpha: alpha * 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9;
      canvas.drawCircle(Offset(x, y), bubble.size * 1.35, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.bubbles != bubbles;
  }
}

class _RingPulsePainter extends CustomPainter {
  const _RingPulsePainter({required this.t, required this.flash});

  final double t;
  final double flash;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.width * 0.13;

    for (var i = 0; i < 3; i++) {
      final localT = ((t + (i * 0.26)) % 1.0);
      final radius = baseRadius + (size.width * 0.12 * localT);
      final alpha = (1 - localT) * (0.2 + (flash * 0.72));
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 - localT
        ..color = const Color(
          0xFF1FFF8B,
        ).withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPulsePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.flash != flash;
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.sparks, required this.progress});

  final List<_SparkSeed> sparks;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final spread = Curves.easeOutQuart.transform(progress);

    for (final spark in sparks) {
      final distance = size.width * 0.13 * spark.radiusFactor * spread;
      final offset = Offset(
        math.cos(spark.angle) * distance,
        math.sin(spark.angle) * distance,
      );
      final alpha = (1 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = const Color(0xFF7BFFB4).withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(center + offset, spark.size * (0.55 + spread), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.sparks != sparks;
  }
}
