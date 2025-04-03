import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/const/resource.dart';

class OnboardingScreenOne extends StatelessWidget {
  const OnboardingScreenOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image - using fit: BoxFit.cover is efficient
        Image.asset(
          R.ASSETS_IMAGES_EXPERIENCE_WEBP,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
        
        // Bottom content container
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: 320.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                
                // Title text
                Text(
                  AppText.kOnboardingHeader1,
                  textAlign: TextAlign.center,
                  style: appStyle(24, Kolors.kPrimary, FontWeight.bold),
                ),
                
                SizedBox(height: 30.h),
                
                // Description text with constrained width
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ScreenUtil().screenWidth - 100),
                  child: Text(
                    AppText.kOnboardingMessage1,
                    textAlign: TextAlign.center,
                    style: appStyle(11, Kolors.kGray, FontWeight.normal),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}