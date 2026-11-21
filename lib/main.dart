import 'package:flutter/material.dart';

import 'screens/omnitrix_screen.dart';
import 'services/watch_feedback.dart';

void main() {
  runApp(const OmnitrixApp());
}

class OmnitrixApp extends StatelessWidget {
  const OmnitrixApp({super.key, this.feedback});

  /// Sound/haptics override; defaults to the real device feedback.
  final WatchFeedback? feedback;

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
      home: OmnitrixScreen(feedback: feedback),
    );
  }
}
