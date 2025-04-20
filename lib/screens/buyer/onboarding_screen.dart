import 'package:flutter/material.dart';
import '/widgets/onboarding_page.dart'; // custom widget
import 'welcome_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'image': 'assets/images/onboarding1.jpg',
      'title': 'Curated for You',
      'subtitle': 'Explore timeless, handpicked pieces that match your vibe. Style meets intention with every scroll.',
    },
    {
      'image': 'assets/images/onboarding1.jpg',
      'title': 'Effortless Search',
      'subtitle': 'Quickly filter by size, style, and category. Find what you love without the hassle',
    },
    {
      'image': 'assets/images/onboarding1.jpg',
      'title': 'Exclusive Bidding',
      'subtitle': 'Bid on limited finds before they\'re gone. Compete, win, and claim one-of-a-kind pieces.',
    },
    {
      'image': 'assets/images/onboarding1.jpg',
      'title': 'Checkout, Simplified',
      'subtitle': 'From cart to closet in just a few taps. A seamless experience, every time you shop.',
    },
  ];

  void _nextPage() {
    if (_currentIndex < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isSmallScreen = screenSize.width < 350;
    final bool isShortScreen = screenSize.height < 600;
    
    // Calculate adaptive padding
    final double horizontalPadding = screenSize.width * 0.06;
    final double verticalPadding = isShortScreen ? 12 : 24;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: isShortScreen ? 0 : 1),
                child: Image.asset(
                  'assets/haul_logo_.png',
                  height: screenSize.height * (isShortScreen ? 0.04 : 0.05),
                  width: screenSize.width * 0.2,
                  fit: BoxFit.contain,
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: onboardingData.length,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                  },
                  itemBuilder: (context, index) {
                    final data = onboardingData[index];
                    return OnboardingPage(
                      imagePath: data['image']!,
                      title: data['title']!,
                      subtitle: data['subtitle']!,
                    );
                  },
                ),
              ),
              SizedBox(height: isShortScreen ? 10 : 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingData.length,
                  (index) => AnimatedContainer(
                    margin: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
                    duration: const Duration(milliseconds: 200),
                    width: _currentIndex == index ? (isSmallScreen ? 10 : 12) : (isSmallScreen ? 6 : 8),
                    height: isSmallScreen ? 6 : 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.black
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              SizedBox(height: isShortScreen ? 16 : 24),      
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isShortScreen ? 10 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    _currentIndex == onboardingData.length - 1
                        ? 'Get Started'
                        : 'Next',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isShortScreen ? 10 : 16),
            ],
          ),
        ),
      ),
    );
  }
}