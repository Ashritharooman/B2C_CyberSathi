import 'package:flutter/material.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const CyberSaathiApp());
}

class CyberSaathiApp extends StatelessWidget {
  const CyberSaathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberSaathi',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const LoginScreen(),
    );
  }
}
