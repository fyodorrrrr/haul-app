import 'package:flutter/material.dart';
import '../widgets/onboarding_page.dart'; // custom widget

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
      'subtitle': 'Bid on limited finds before they’re gone. Compete, win, and claim one-of-a-kind pieces.',
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
        MaterialPageRoute(builder: (_) => const Placeholder()), // change to Home/Login
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
             Padding(
                padding: const EdgeInsets.only(bottom: 1), // reduce space below the logo
                child: Image.asset(
                  'assets/haul_logo_.png',
                  height: screenSize.height * 0.05,
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
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingData.length,
                  (index) => AnimatedContainer(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    duration: const Duration(milliseconds: 200),
                    width: _currentIndex == index ? 12 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? Colors.black
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),      
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  child: Text(
                    _currentIndex == onboardingData.length - 1
                        ? 'Get Started'
                        : 'Next',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
