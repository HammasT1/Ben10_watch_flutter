import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Whether the 3D viewer can run here (it needs a WebView or the browser).
bool get supportsIntro3d =>
    kIsWeb ||
    defaultTargetPlatform == TargetPlatform.android ||
    defaultTargetPlatform == TargetPlatform.iOS;

/// Opening screen: a spinnable 3D watch and an ACTIVATE button that leads
/// into the watch screen built by [next].
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.next, this.model});

  final WidgetBuilder next;

  /// Replaces the 3D viewer (tests can't host a WebView).
  final Widget? model;

  static const modelAsset = 'assets/models/omnitrix_watch_ben10.glb';

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  static const _green = Color(0xFF1FFF8B);

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  bool _leaving = false;

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  void _activate() {
    if (_leaving) return;
    _leaving = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, _, _) => widget.next(context),
        transitionsBuilder: (context, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 1.15, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: [Color(0xFF113C25), Color(0xFF081A10), Color(0xFF010302)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 28),
              _buildTitle(),
              const SizedBox(height: 6),
              const Text(
                'DRAG TO INSPECT THE WATCH',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.5,
                  color: Color(0xAA91FFA8),
                ),
              ),
              Expanded(child: widget.model ?? _buildModel()),
              _buildActivateButton(),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, _) => Text(
        'BEN 10 WATCH',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          letterSpacing: 4,
          color: const Color(0xFF9BFFAE),
          shadows: [
            Shadow(
              color: _green.withValues(alpha: 0.35 + (_glow.value * 0.6)),
              blurRadius: 26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModel() {
    return const ModelViewer(
      src: IntroScreen.modelAsset,
      alt: '3D model of the watch',
      backgroundColor: Colors.transparent,
      loading: Loading.eager,
      autoRotate: true,
      autoRotateDelay: 0,
      rotationPerSecond: '30deg',
      cameraControls: true,
      disableZoom: true,
      disablePan: true,
      interactionPrompt: InteractionPrompt.none,
      shadowIntensity: 1,
      exposure: 1.1,
      debugLogging: false,
    );
  }

  Widget _buildActivateButton() {
    return AnimatedBuilder(
      animation: _glow,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: _green.withValues(alpha: 0.2 + (_glow.value * 0.35)),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: child,
      ),
      child: FilledButton.icon(
        key: const Key('activate'),
        onPressed: _activate,
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          foregroundColor: const Color(0xFF02140A),
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        ),
        icon: const Icon(Icons.power_settings_new),
        label: const Text(
          'ACTIVATE',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
