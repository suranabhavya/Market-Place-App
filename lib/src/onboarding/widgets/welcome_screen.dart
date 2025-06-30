import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/const/resource.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              R.ASSETS_IMAGES_GETSTARTED_WEBP,
              fit: BoxFit.cover,
            ),
          ),
          
          // Bottom content container with flexible height
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              // Use percentage of screen height with min/max constraints
              height: screenHeight * 0.35, // 45% of screen height (slightly more for buttons)
              constraints: BoxConstraints(
                minHeight: 320.h, // Minimum height for small screens
                maxHeight: 450.h, // Maximum height for large screens
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16.w, // Reduced from screenWidth * 0.05
                vertical: 20.h,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.r),
                  topRight: Radius.circular(40.r),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Title text with responsive font size
                    Flexible(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppText.kWelcomeHeader,
                            textAlign: TextAlign.center,
                            style: appStyle(
                              screenWidth > 400 ? 24.sp : 20.sp,
                              Kolors.kPrimary, 
                              FontWeight.bold
                            ),
                          ),
                          
                          SizedBox(height: 20.h),
                          
                          // Description text with responsive constraints
                          Container(
                            constraints: BoxConstraints(
                              maxWidth: screenWidth * 0.85, // 85% of screen width
                            ),
                            child: Text(
                              AppText.kWelcomeMessage, 
                              textAlign: TextAlign.center,
                              style: appStyle(
                                screenWidth > 400 ? 13.sp : 11.sp,
                                Kolors.kGray, 
                                FontWeight.normal
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                    
                    // Buttons section
                    Flexible(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Get Started button with responsive width
                          CustomButton(
                            text: AppText.kGetStarted,
                            btnHeight: screenHeight > 700 ? 45.h : 40.h, // Responsive height
                            radius: 20.r,
                            btnWidth: screenWidth * 0.75, // 85% of screen width
                            onTap: () {
                              Storage().setBool('firstOpen', true);
                              context.go('/home');
                            },
                          ),

                          SizedBox(height: 15.h),

                          // Sign in option with responsive layout
                          Flexible(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  "Already have an Account? ",
                                  style: appStyle(
                                    screenWidth > 400 ? 12.sp : 10.sp,
                                    Kolors.kDark, 
                                    FontWeight.normal
                                  )
                                ),
                                GestureDetector(
                                  onTap: () => context.go('/check-email'),
                                  child: Text(
                                    "Sign In",
                                    style: appStyle(
                                      screenWidth > 400 ? 12.sp : 10.sp,
                                      Colors.blue, 
                                      FontWeight.bold
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}