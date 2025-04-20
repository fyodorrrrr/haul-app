import 'package:flutter/material.dart';
import 'screens/buyer/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'screens/buyer/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that Flutter bindings are initialized
  await Firebase.initializeApp(); // Initialize Firebase
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
