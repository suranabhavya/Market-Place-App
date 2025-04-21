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
    return Stack(
      children: [
        // Background image
        Image.asset(
          R.ASSETS_IMAGES_GETSTARTED_WEBP,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
        ),
        
        // Bottom content container
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: 330.h,
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
                SizedBox(height: 15.h),

                // Title text
                Text(
                  AppText.kWelcomeHeader,
                  textAlign: TextAlign.center,
                  style: appStyle(24, Kolors.kPrimary, FontWeight.bold),
                ),

                SizedBox(height: 15.h),

                // Description text
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: ScreenUtil().screenWidth - 100),
                  child: Text(
                    AppText.kWelcomeMessage, 
                    textAlign: TextAlign.center,
                    style: appStyle(11, Kolors.kGray, FontWeight.normal),
                  ),
                ),

                SizedBox(height: 25.h),

                // Get Started button
                CustomButton(
                  text: AppText.kGetStarted,
                  btnHeight: 35,
                  radius: 20,
                  btnWidth: ScreenUtil().screenWidth - 100,
                  onTap: () {
                    // TODO - uncomment the boolean storage when te app is ready
                    // Storage().setBool('firstOpen', true);
                    context.go('/home');
                  },
                ),

                SizedBox(height: 4.h),

                // Sign in option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: ReusableText(
                        text: "Already have an Account?",
                        style: appStyle(12, Kolors.kDark, FontWeight.normal)
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/check-email'),
                      child: Text(
                        "Sign In",
                        style: appStyle(12, Colors.blue, FontWeight.bold),
                      )
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}