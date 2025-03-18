import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    this.onTap,
    this.btnWidth,
    required this.text,
    this.btnHeight, 
    this.textSize, 
    this.borderColor, 
    this.radius, 
    this.btnColor,
    this.icon,
    this.svgPath,
    this.iconColor,
  });
  final void Function()? onTap;
  final double? btnWidth;
  final double? btnHeight;
  final double? radius;
  final String text;
  final double? textSize;
  final Color? borderColor;
  final Color? btnColor;
  final IconData? icon;
  final String? svgPath;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: btnWidth ?? ScreenUtil().screenWidth / 2,
        height: btnHeight ?? 25.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius??6),
          color: btnColor?? Kolors.kPrimaryLight,
          border: Border.all(width: 0.5.h, color:borderColor?? Kolors.kWhite),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: (icon != null || svgPath != null)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    svgPath != null
                      ? SvgPicture.asset(
                          svgPath!,
                          width: 24,
                          height: 24,
                          colorFilter: iconColor != null 
                            ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
                            : null,
                        )
                      : Icon(
                          icon, 
                          color: iconColor ?? Kolors.kPrimary, 
                          size: 24
                        ),
                    SizedBox(width: 12.w),
                    ReusableText(
                      text: text, 
                      style: appStyle(textSize??13, Kolors.kPrimary, FontWeight.bold)
                    ),
                  ],
                )
              : ReusableText(
                  text: text, 
                  style: appStyle(textSize??13, borderColor??Kolors.kWhite, FontWeight.bold)
                ),
          ),
        ),
      ),
    );
  }
}
