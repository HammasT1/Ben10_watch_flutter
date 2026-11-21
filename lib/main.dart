import 'package:flutter/material.dart';

import 'screens/intro_screen.dart';
import 'screens/omnitrix_screen.dart';
import 'services/watch_feedback.dart';

void main() {
  runApp(const OmnitrixApp());
}

class OmnitrixApp extends StatelessWidget {
  const OmnitrixApp({super.key, this.feedback, this.showIntro = true});

  /// Sound/haptics override; defaults to the real device feedback.
  final WatchFeedback? feedback;

  /// Show the 3D intro first (skipped automatically where 3D isn't
  /// supported, e.g. Linux/Windows desktop).
  final bool showIntro;

  @override
  Widget build(BuildContext context) {
    Widget watch(BuildContext context) => OmnitrixScreen(feedback: feedback);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ben 10 Watch',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030706),
        useMaterial3: true,
      ),
      home: showIntro && supportsIntro3d
          ? IntroScreen(next: watch)
          : Builder(builder: watch),
    );
  }
}
