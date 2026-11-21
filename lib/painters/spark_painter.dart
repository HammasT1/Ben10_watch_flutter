import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/effect_seeds.dart';

class SparkPainter extends CustomPainter {
  const SparkPainter({
    required this.sparks,
    required this.progress,
    this.color = const Color(0xFF7BFFB4),
  });

  final List<SparkSeed> sparks;
  final double progress;
  final Color color;

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
        ..color = color.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(center + offset, spark.size * (0.55 + spread), paint);
    }
  }

  @override
  bool shouldRepaint(covariant SparkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.sparks != sparks ||
        oldDelegate.color != color;
  }
}
