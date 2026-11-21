import 'package:flutter/material.dart';

class RingPulsePainter extends CustomPainter {
  const RingPulsePainter({
    required this.t,
    required this.intensity,
    this.color = const Color(0xFF1FFF8B),
  });

  final double t;

  /// 0..1, boosts ring brightness (alien change flash or transform charge).
  final double intensity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.width * 0.13;

    for (var i = 0; i < 3; i++) {
      final localT = ((t + (i * 0.26)) % 1.0);
      final radius = baseRadius + (size.width * 0.12 * localT);
      final alpha = (1 - localT) * (0.2 + (intensity * 0.72));
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 - localT
        ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant RingPulsePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.intensity != intensity ||
        oldDelegate.color != color;
  }
}
