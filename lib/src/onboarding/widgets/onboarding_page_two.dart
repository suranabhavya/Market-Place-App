import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/const/resource.dart';

class OnboardingScreenTwo extends StatelessWidget {
  const OnboardingScreenTwo({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background image - using fit: BoxFit.cover is efficient
          Positioned.fill(
            child: Image.asset(
              R.ASSETS_IMAGES_WISHLIST_WEBP,
              fit: BoxFit.cover,
            ),
          ),
          
          // Bottom content container with flexible height
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              // Use percentage of screen height with min/max constraints
              height: screenHeight * 0.35, // 40% of screen height
              constraints: BoxConstraints(
                minHeight: 280.h, // Minimum height for small screens
                maxHeight: 400.h, // Maximum height for large screens
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    
                    // Title text with responsive font size
                    Flexible(
                      flex: 2,
                      child: Text(
                        AppText.kOnboardingHeader2,
                        textAlign: TextAlign.center,
                        style: appStyle(
                          screenWidth > 400 ? 24.sp : 20.sp, // Responsive font size
                          Kolors.kPrimary, 
                          FontWeight.bold
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 30.h),
                    
                    // Description text with responsive constraints
                    Flexible(
                      flex: 3,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: screenWidth * 0.85, // 85% of screen width
                        ),
                        child: Text(
                          AppText.kOnboardingMessage2,
                          textAlign: TextAlign.center,
                          style: appStyle(
                            screenWidth > 400 ? 13.sp : 11.sp, // Responsive font size
                            Kolors.kGray, 
                            FontWeight.normal
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 30.h),
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