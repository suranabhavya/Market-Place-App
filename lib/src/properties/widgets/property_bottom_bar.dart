import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';

class PropertyBottomBar extends StatelessWidget {
  const PropertyBottomBar({super.key, required this.price, this.onPressed});

  final String price;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');

    return Container(
      height: 68.h,
      color: Colors.white.withOpacity(.6),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 12.w, 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                if(accessToken == null) {
                  loginBottomSheet(context);
                } else {
                  // TODO: Implement whatsapp integration
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Kolors.kPrimary)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    MaterialCommunityIcons.whatsapp,
                    size: 16,
                    color: Kolors.kWhite,
                  ),
                  SizedBox(
                    width: 8.w,
                  ),
                  ReusableText(
                    text: 'Whatsapp',
                    style: appStyle(14, Kolors.kWhite, FontWeight.bold)
                  ),
                ],
              )
            ),

            ElevatedButton(
              onPressed: () {
                if(accessToken == null) {
                  loginBottomSheet(context);
                } else {
                  // TODO: Implement messaging inside the app
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Kolors.kPrimary)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    MaterialCommunityIcons.message,
                    size: 16,
                    color: Kolors.kWhite,
                  ),
                  SizedBox(
                    width: 8.w,
                  ),
                  ReusableText(
                    text: 'Message',
                    style: appStyle(14, Kolors.kWhite, FontWeight.bold)
                  ),
                ],
              )
            ),
          ],
        ),
      ),
    );
  }
}