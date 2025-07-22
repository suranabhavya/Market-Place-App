import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/const/resource.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OnboardingScreenTwo extends StatelessWidget {
  const OnboardingScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // SVG Image taking most of the space
          Expanded(
            flex: 3,
            child: Transform.translate(
              offset: Offset(0, 80.h),
              child: SvgPicture.asset(
                R.ASSETS_IMAGES_ONBOARDING_TWO_SVG,
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Text content at the bottom
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 50.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    Text(
                      AppText.kOnboardingHeader2,
                      textAlign: TextAlign.center,
                      style: appStyle(
                        screenWidth > 400 ? 24.sp : 20.sp,
                        Kolors.kPrimary, 
                        FontWeight.bold
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      AppText.kOnboardingMessage2,
                      textAlign: TextAlign.center,
                      style: appStyle(
                        screenWidth > 400 ? 13.sp : 11.sp,
                        Kolors.kGray, 
                        FontWeight.normal
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
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