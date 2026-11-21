import 'package:flutter/material.dart';

import 'screens/omnitrix_screen.dart';

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
