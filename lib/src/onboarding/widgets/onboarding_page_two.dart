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
    return SizedBox(
      width: ScreenUtil().screenWidth,
      height: ScreenUtil().screenHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              R.ASSETS_IMAGES_WISHLIST_PNG,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: 360.h,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 20.h,
                  ),

                  Text(
                    AppText.kOnboardingHeader2,
                    textAlign: TextAlign.center,
                    style: appStyle(24, Kolors.kPrimary, FontWeight.bold),
                  ),

                  SizedBox(
                    height: 30.h,
                  ),

                  SizedBox(
                    width: ScreenUtil().screenWidth -100,
                    child: Text(
                      AppText.kOnboardingMessage2, 
                      textAlign: TextAlign.center,
                      style: appStyle(11, Kolors.kGray, FontWeight.normal),
                    ),
                  ),

                  // Text(
                  //   "Wishlist: Where Fashion Dreams Begin",
                  //   textAlign: TextAlign.center,
                  //   style: appStyle(18, Kolors.kPrimary, FontWeight.bold),
                  // ),
                  // SizedBox(
                  //   height: 20.h,
                  // ),
                  // Text(
                  //   "Wishlist: Where Fashion Dreams Begin",
                  //   textAlign: TextAlign.center,
                  //   style: appStyle(18, Kolors.kPrimary, FontWeight.bold),
                  // ),
                ],
              ),
            ),
          ),
          // Positioned(
          //   bottom: 200,
          //   left: 30,
          //   right: 30,
          //   child: Text(
          //     AppText.kOnboardWishListMessage,
          //     textAlign: TextAlign.center,
          //     style: appStyle(11, Kolors.kGray, FontWeight.normal),
          //   ),
          // )
        ],
      ),
    );
  }
}