/// Random parameters for one floating background bubble.
class BubbleSeed {
  const BubbleSeed({
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

/// Random parameters for one energy spark burst particle.
class SparkSeed {
  const SparkSeed({
    required this.angle,
    required this.radiusFactor,
    required this.size,
  });

  final double angle;
  final double radiusFactor;
  final double size;
}
