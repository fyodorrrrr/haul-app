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
      'image': 'assets/onboarding1.png',
      'title': 'Curated for You',
      'subtitle': 'Explore timeless, handpicked pieces that match your vibe.',
    },
    {
      'image': 'assets/onboarding2.png',
      'title': 'Sustainable Style',
      'subtitle': 'Shop thrift, save the planet, and look good doing it.',
    },
    {
      'image': 'assets/onboarding3.png',
      'title': 'Your Closet, Your Rules',
      'subtitle': 'Sell pre-loved pieces and make space for the new.',
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                "HAUL",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
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
                      borderRadius: BorderRadius.circular(10),
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
