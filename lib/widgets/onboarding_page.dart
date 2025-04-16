import 'package:flutter/material.dart';

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

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.08),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image container
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

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenSize.height * 0.02),

          // Subtitle
          Text(
            subtitle,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenSize.height * 0.04),
        ],
      ),
    );
  }
}
