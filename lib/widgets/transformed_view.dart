import 'package:flutter/material.dart';

/// Full-screen view shown while an alien is active, with the timeout
/// countdown and a manual revert button.
class TransformedView extends StatelessWidget {
  const TransformedView({
    super.key,
    required this.alienAsset,
    required this.label,
    required this.timeout,
    required this.totalSeconds,
    required this.onRevert,
  });

  final String alienAsset;
  final String label;

  /// Runs 0 -> 1 over the transformation's lifetime.
  final Animation<double> timeout;
  final int totalSeconds;
  final VoidCallback onRevert;

  static const _green = Color(0xFF1FFF8B);
  static const _red = Color(0xFFFF3B3B);
  static const _warningSeconds = 3;

  @override
  Widget build(BuildContext context) {
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
                label,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Color(0xFFB8FFD0),
                  shadows: [Shadow(color: _green, blurRadius: 24)],
                ),
              ),
              Expanded(child: Center(child: _buildAlien(alienSize))),
              _buildCountdown(),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRevert,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9BFFAE),
                  side: const BorderSide(color: _green, width: 1.4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.power_settings_new),
                label: const Text(
                  'REVERT',
                  style: TextStyle(
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          );
        },
      ),
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
            _green.withValues(alpha: 0.35),
            _green.withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
      ),
      padding: EdgeInsets.all(size * 0.08),
      child: Image.asset(
        alienAsset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.question_mark, color: Color(0xFF7FFF9E), size: 64),
      ),
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
        final color = warning ? _red : _green;

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
