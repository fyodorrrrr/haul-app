import 'package:flutter/material.dart';
import 'package:haul/providers/product_provider.dart';
import 'package:haul/screens/buyer/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'providers/wishlist_providers.dart';
import 'providers/cart_providers.dart';
import 'providers/auth_provider.dart';
import 'providers/user_registration_provider.dart';
import '/screens/buyer/forgot_password_screen.dart';
import '/providers/edit_profile_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/seller_registration_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'providers/checkout_provider.dart';
import 'providers/address_provider.dart';
import 'providers/order_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/inventory_provider.dart';
import 'screens/buyer/login_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // FIXED: Initialize Firebase with proper options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // FIXED: Safe .env loading
  try {
    await dotenv.load();
  } catch (e) {
    print('Warning: .env file not found or could not be loaded: $e');
  }
  
  // Initialize App Check
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
  );
  
  // FIXED: Removed duplicate ChangeNotifierProvider wrapper
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // FIXED: Added CheckoutProvider here instead of duplicate wrapper
        ChangeNotifierProvider(create: (_) => CheckoutProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => UserRegistrationProvider()),
        Provider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EditProfileProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => SellerRegistrationProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => SellerOrdersProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
      ],
      child: MaterialApp(
        title: 'Haul',
        theme: AppTheme.lightTheme(),
        home: const WelcomeScreen(),
        routes: {
          '/login': (context) => LoginScreen(), // Add this line
        },
        debugShowCheckedModeBanner: false,
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
