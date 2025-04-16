import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingPage extends StatelessWidget {
  final String imagePath;
  final String title;
  final String subtitle;

  const OnboardingPage({
    super.key,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 350;
    final double screenHeight = screenSize.height;

    // Adaptive top spacing
    double topSpacing;
    if (screenHeight < 600) {
      topSpacing = screenHeight * 0.03; // was 0.02
    } else if (screenHeight < 800) {
      topSpacing = screenHeight * 0.05;  // was 0.04
    } else {
      topSpacing = screenHeight * 0.07;  // was 0.06
    }

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: topSpacing), // 👈 dynamic spacing here

            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: screenSize.height * 0.45,
                width: screenSize.width * 0.84,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: screenSize.height * 0.04),

            Text(
              title,
              style:  GoogleFonts.poppins(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenSize.height * 0.02),

            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenSize.height * 0.04),
          ],
        ),
      ),
    );
  }
}
