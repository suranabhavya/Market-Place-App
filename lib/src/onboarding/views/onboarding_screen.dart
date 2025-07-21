import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/src/onboarding/controllers/onboarding_notifier.dart';
import 'package:marketplace_app/src/onboarding/widgets/onboarding_page_one.dart';
import 'package:marketplace_app/src/onboarding/widgets/onboarding_page_two.dart';
import 'package:marketplace_app/src/onboarding/widgets/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: context.read<OnboardingNotifier>().selectedPage
    );
  }

   // Dispose controller to prevent memory leaks
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _navigateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeIn
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboardingNotifier = context.watch<OnboardingNotifier>();
    final currentPage = onboardingNotifier.selectedPage;
    
    return Scaffold(
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            PageView(
              controller: _pageController,
              onPageChanged: (page) {
                context.read<OnboardingNotifier>().setSelectedPage = page;
              },
              children: const [
                OnboardingScreenOne(),
                OnboardingScreenTwo(),
                WelcomeScreen(),
              ],
            ),
            
            // Only show navigation controls on pages 0 and 1
            if (currentPage != 2)
              Positioned(
                bottom: 10.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  width: ScreenUtil().screenWidth,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Back button (hidden on first page)
                      currentPage == 0 
                        ? const SizedBox(width: 25)
                        : GestureDetector(
                            onTap: () => _navigateToPage(currentPage - 1),
                            child: const Icon(
                              AntDesign.leftcircleo,
                              color: Kolors.kPrimary,
                              size: 30
                            ),
                          ),
                      // Page indicator dots
                      SizedBox(
                        width: ScreenUtil().screenWidth * 0.7,
                        height: 30.h,
                        child: PageViewDotIndicator(
                          currentItem: currentPage,
                          count: 3,
                          unselectedColor: Colors.black26,
                          selectedColor: Kolors.kPrimary,
                          duration: const Duration(milliseconds: 200),
                          onItemClicked: _navigateToPage,
                        ),
                      ),
                      // Forward button
                      GestureDetector(
                        onTap: () => _navigateToPage(currentPage + 1),
                        child: const Icon(
                          AntDesign.rightcircleo,
                          color: Kolors.kPrimary,
                          size: 25,
                        ),
                      ),
                    ],
                  ),
                )
              )
          ]
        )
      )
    );
  }
}