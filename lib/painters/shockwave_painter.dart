import 'package:flutter/material.dart';

/// A single ring that blasts outward from the screen center.
class ShockwavePainter extends CustomPainter {
  const ShockwavePainter({required this.progress, required this.color});

  /// 0..1 over the life of the wave.
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final eased = Curves.easeOutCubic.transform(progress);
    final radius = size.longestSide * 0.95 * eased;
    final fade = (1 - progress).clamp(0.0, 1.0);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34 * fade + 6
      ..color = color.withValues(alpha: 0.35 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, radius, glow);

    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8 * fade + 1.5
      ..color = Colors.white.withValues(alpha: 0.85 * fade);
    canvas.drawCircle(center, radius, core);
  }

  @override
  bool shouldRepaint(covariant ShockwavePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
