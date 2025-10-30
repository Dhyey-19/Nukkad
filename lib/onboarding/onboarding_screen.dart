import 'package:flutter/material.dart';
import 'package:nukkad/utils/app_colors.dart';
import 'package:nukkad/login/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int currentIndex = 0;
  
  final List<Map<String, String>> pages = [
    {
      "title": "Find the Best Services Around You",
      "subtitle": "Explore shops, restaurants, and professionals in your city at your fingertips.",
      "gif": "assets/images/onboarding1.gif",
    },
    {
      "title": "Search & Filter with Ease",
      "subtitle": "Quickly find exactly what you need by type, location, or rating.",
      "gif": "assets/images/onboarding2.gif",
    },
    {
      "title": "Contact, Navigate & Review",
      "subtitle": "Call, get directions, and leave reviews for businesses you trust.",
      "gif": "assets/images/onboarding3.gif",
    },
    {
      "title": "Get Featured & Grow Your Business",
      "subtitle": "Business owners can showcase their services to more customers with premium listings.",
      "gif": "assets/images/onboarding4.gif",
    },
  ];

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isOnboarded', true);

    // Navigate to Login Screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void nextPage() {
    if (currentIndex < pages.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.ease);
    } else {
      // Navigate to home page or main app screen
      completeOnboarding();
    }
  }

  void skip() {
    _controller.animateToPage(
      pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.ease,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (index) => setState(() => currentIndex = index),
              itemBuilder: (context, index) {
                final data = pages[index];
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Image.asset(data['gif']!, fit: BoxFit.contain),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              data['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              data['subtitle']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            // Pagination dots
            Positioned(
              bottom: 45,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
                  bool isActive = index == currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    height: 12,
                    width: isActive ? 28 : 12,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.gray,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  );
                }),
              ),
            ),
            // Skip button
            Positioned(
              bottom: 30,
              left: 24,
              child: currentIndex < pages.length - 1
                  ? TextButton(
                      onPressed: skip,
                      child: const Text("Skip", style: TextStyle(color: Colors.black, fontSize: 16)),
                    )
                  : const SizedBox.shrink(),
            ),
            // Next button
            Positioned(
              bottom: 30,
              right: 24,
              child: ElevatedButton(
                onPressed: nextPage,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16),
                  backgroundColor: AppColors.primary,
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
