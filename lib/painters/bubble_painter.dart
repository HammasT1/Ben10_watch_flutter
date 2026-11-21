import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/effect_seeds.dart';

class BubblePainter extends CustomPainter {
  const BubblePainter({required this.bubbles, required this.t});

  final List<BubbleSeed> bubbles;
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
  bool shouldRepaint(covariant BubblePainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.bubbles != bubbles;
  }
}
