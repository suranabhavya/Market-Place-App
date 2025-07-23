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
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            children: [
              // Header section at the top
              Container(
                padding: EdgeInsets.only(top: 60.h),
                child: Text(
                  AppText.kOnboardingHeader2,
                  textAlign: TextAlign.center,
                  style: appStyle(
                    screenWidth > 400 ? 24.sp : 20.sp,
                    Kolors.kPrimary, 
                    FontWeight.bold
                  ),
                ),
              ),
              
              // SVG Image section in the middle
              Expanded(
                flex: 3,
                child: Center(
                  child: SvgPicture.asset(
                    R.ASSETS_IMAGES_ONBOARDING_TWO_SVG,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              // Message section at the bottom
              Container(
                padding: EdgeInsets.only(
                  top: 30.h,
                  bottom: 100.h, // Bottom padding to avoid navigation overlap
                ),
                child: Text(
                  AppText.kOnboardingMessage2,
                  textAlign: TextAlign.center,
                  style: appStyle(
                    screenWidth > 400 ? 13.sp : 11.sp,
                    Kolors.kGray, 
                    FontWeight.normal
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}