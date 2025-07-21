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
import 'package:flutter_svg/flutter_svg.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // SVG Image taking most of the space
          Expanded(
            flex: 2,
            child: Transform.translate(
              offset: Offset(0, 80.h),
              child: SvgPicture.asset(
                R.ASSETS_IMAGES_ONBOARDING_THREE_SVG,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Content at the bottom
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title and description
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
                  // Description text
                  Text(
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
                  SizedBox(height: 20.h),
                  // Get Started button
                  CustomButton(
                    text: AppText.kGetStarted,
                    btnHeight: screenHeight > 700 ? 45.h : 40.h,
                    radius: 20.r,
                    btnWidth: screenWidth * 0.75,
                    onTap: () {
                      Storage().setBool('firstOpen', true);
                      context.go('/home');
                    },
                  ),
                  SizedBox(height: 15.h),
                  // Sign in option
                  Wrap(
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}