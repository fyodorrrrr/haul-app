import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haul',
      theme: AppTheme.lightTheme(),
      home: const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
