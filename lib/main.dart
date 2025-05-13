import 'package:flutter/material.dart';
import 'package:haul/providers/product_provider.dart';
import 'package:haul/screens/buyer/welcome_screen.dart';
// import 'screens/buyer/onboarding_screen.dart';     //TEMPORARY CHANGE
import 'theme/app_theme.dart';
// import 'screens/buyer/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart'; // Import the generated file for Firebase options
import 'providers/wishlist_providers.dart'; // Import your provider
import 'providers/cart_providers.dart';  // Import your provider
import 'providers/auth_provider.dart'; // Import your provider
import 'providers/user_registration_provider.dart'; // Import your provider
import '/screens/buyer/forgot_password_screen.dart';
import '/providers/edit_profile_provider.dart'; // Import your provider
import 'providers/user_profile_provider.dart'; // Add the new provider import
import 'package:haul/screens/seller/seller_registration_screen.dart';
import 'providers/seller_registration_provider.dart'; // Import the new provider
//import 'providers/product_provider.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure that Flutter bindings are initialized
  await Firebase.initializeApp(); // Initialize Firebase
  await dotenv.load();
  
  // Initialize App Check and register a provider
  await FirebaseAppCheck.instance.activate(
    // Use debug provider during development
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  
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
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => UserRegistrationProvider()),
        Provider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EditProfileProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()), // Add the new provider
        ChangeNotifierProvider(create: (_) => SellerRegistrationProvider()), // Add the new provider
        ChangeNotifierProvider(create: (_) => ProductProvider()),
      ],
      child: 
      MaterialApp(
      title: 'Haul',
      theme: AppTheme.lightTheme(),
      home: const WelcomeScreen(), // Change to OnboardingScreen() for onboarding
      debugShowCheckedModeBanner: false,
      navigatorObservers: [routeObserver],
       ),
    ); 
  }
}
