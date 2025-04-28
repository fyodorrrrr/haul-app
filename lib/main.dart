import 'package:flutter/material.dart';
import 'package:haul/screens/buyer/welcome_screen.dart';
// import 'screens/buyer/onboarding_screen.dart';     //TEMPORARY CHANGE
import 'theme/app_theme.dart';
// import 'screens/buyer/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // Import the generated file for Firebase options
import 'providers/wishlist_providers.dart'; // Import your provider


void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that Flutter bindings are initialized
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return 
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: 
      MaterialApp(
      title: 'Haul',
      theme: AppTheme.lightTheme(),
      home: const WelcomeScreen(), // Change to OnboardingScreen() for onboarding
      debugShowCheckedModeBanner: false,
       ),
    ); 
  }
}
