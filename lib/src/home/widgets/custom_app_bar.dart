import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/app_routes.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/home/widgets/notification_widget.dart';

class CustomAppBar extends StatelessWidget {
  const CustomAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      automaticallyImplyLeading: false,
      title: PreferredSize(
        preferredSize: Size.fromHeight(55.h), 
        child: GestureDetector(
          onTap: () {
            context.push('/search');
          },
          child: Padding(padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 6.w),
                child: Container(
                  height: 40.h,
                  width: ScreenUtil().screenWidth - 120,
                  decoration: BoxDecoration(
                    border: Border.all(
                      width: 0.5,
                      color: Kolors.kGrayLight,
                    ),
                    borderRadius: BorderRadius.circular(24)
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                    child: Row(
                      children: [
                        const Icon(
                          Ionicons.search, 
                          size: 20, 
                          color: Kolors.kPrimaryLight
                        ),
                        
                        SizedBox(
                          width: 20.w,
                        ),
                        
                        ReusableText(
                          text: "Search Pin Code, City, Address", 
                          style: appStyle(14, Kolors.kGray, FontWeight.w400)
                        )
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                height: 40.h,
                width: 40.w,
                decoration: BoxDecoration(
                  color: Kolors.kPrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  FontAwesome.sliders,
                  color: Kolors.kWhite,
                  size: 20,
                ),
              )
            ],
          ),),
        )
      ),
    );
  }
}