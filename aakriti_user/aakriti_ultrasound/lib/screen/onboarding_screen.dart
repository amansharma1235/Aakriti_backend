import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();

  int currentPage = 0;

  final List<Map<String, dynamic>> onboardingData = [
    {
      "icon": Icons.health_and_safety_rounded,
      "title": "Advanced Ultrasound Care",
      "description":
          "Get reliable ultrasound and diagnostic services with modern technology and professional care.",
    },
    {
      "icon": Icons.calendar_month_rounded,
      "title": "Book Your Appointment",
      "description":
          "Choose your preferred service, date and time and book your appointment easily.",
    },
    {
      "icon": Icons.description_rounded,
      "title": "Your Reports, Anytime",
      "description":
          "Access your diagnostic reports digitally and keep your health records organized.",
    },
  ];

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  void nextPage() {
    if (currentPage < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToLogin();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Button -> Takes user directly to Login Screen
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(
                  right: 20,
                  top: 8,
                  bottom: 4,
                ),
                child: TextButton(
                  onPressed: _navigateToLogin,
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      color: Color(0xFF0B8FAC),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            // Pages with responsive layout and scroll view to prevent any overflow
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: (index) {
                  setState(() {
                    currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = onboardingData[index];

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final availableHeight = constraints.maxHeight;
                      final isCompact = availableHeight < 550;
                      final circleSize = isCompact ? 160.0 : (availableHeight < 650 ? 190.0 : 220.0);
                      final innerBoxSize = isCompact ? 100.0 : (availableHeight < 650 ? 115.0 : 135.0);
                      final iconSize = isCompact ? 52.0 : (availableHeight < 650 ? 60.0 : 70.0);
                      final spacing = isCompact ? 20.0 : (availableHeight < 650 ? 28.0 : 40.0);

                      return Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Illustration Container
                                Container(
                                  height: circleSize,
                                  width: circleSize,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0B8FAC).withValues(alpha: 0.12),
                                        blurRadius: 30,
                                        spreadRadius: 6,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      height: innerBoxSize,
                                      width: innerBoxSize,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0B8FAC),
                                        borderRadius: BorderRadius.circular(34),
                                      ),
                                      child: Icon(
                                        item["icon"],
                                        size: iconSize,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                SizedBox(height: spacing),

                                // Title
                                Text(
                                  item["title"],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isCompact ? 22 : 26,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF123B52),
                                    height: 1.25,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                // Description
                                Text(
                                  item["description"],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isCompact ? 13.5 : 14.5,
                                    color: Colors.grey.shade600,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Page Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) {
                  bool isActive = currentPage == index;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: isActive ? 28 : 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF0B8FAC)
                          : const Color(0xFFD5E8ED),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Next / Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B8FAC),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF0B8FAC).withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentPage == onboardingData.length - 1
                            ? "Get Started"
                            : "Next",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 21,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
