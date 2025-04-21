import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 350;

    final loginTextStyle = GoogleFonts.poppins(
      fontSize: isSmallScreen ? 12 : 14,
      fontWeight: FontWeight.w400,
      color: Colors.white,
    );

    final registerTextStyle = GoogleFonts.poppins(
      fontSize: isSmallScreen ? 12 : 14,
      fontWeight: FontWeight.w400,
      color: Colors.black,
    );

    final linkTextStyle = GoogleFonts.poppins(
      fontSize: isSmallScreen ? 14 : 16,
      fontWeight: FontWeight.w500,
      color: const Color.fromARGB(255, 114, 114, 114),
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Hero image with blur effect
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  // Base image
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/welcome_screen.jpg',
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  
                  // Blur overlay
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 4.0),
                      child: Container(
                        color: Colors.black.withOpacity(0.15), // Darkens the blurred image
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Logo and buttons container
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/haul_logo_.png',
                      height: size.height * 0.06,
                    ),
             
                    // Buttons container
                    Column(
                      children: [
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('Login', style: loginTextStyle),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const RegisterScreen()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(color: Colors.black),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('Register',style: registerTextStyle),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Continue as Guest
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => HomeScreen(userData: {})),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black87,
                          ),
                          child: Text('Continue as Guest', style: linkTextStyle),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}