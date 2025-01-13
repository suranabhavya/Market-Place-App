import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_slideshow/flutter_image_slideshow.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/const/constants.dart';

class HomeSlider extends StatelessWidget {
  const HomeSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: kRadiusAll,
      child: Stack(
        children: [
          SizedBox(
            height: ScreenUtil().screenHeight * 0.16,
            width: ScreenUtil().screenWidth,
            child: ImageSlideshow(
              indicatorColor: Kolors.kPrimaryLight,
              onPageChanged: (p) {
                
              },
              autoPlayInterval: 5000,
              isLoop: true,
              children: List.generate(
                images.length,
                (i) {
                  return CachedNetworkImage(
                    placeholder: placeholder,
                    errorWidget: errorWidget,
                    imageUrl: images[i],
                    fit: BoxFit.cover,
                  );
                }
              )
            ),
          ),
          Positioned(child: SizedBox(
            height: ScreenUtil().screenHeight * 0.16,
            width: ScreenUtil().screenWidth,
            child: Padding(padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ReusableText(
                  text: AppText.kCollection,
                  style: appStyle(20, Kolors.kDark, FontWeight.w600),
                ),
                SizedBox(
                  height: 5.h,
                ),
                Text(
                  'Discount 50% off \nthe first transaction!',
                  style: appStyle(14, Kolors.kDark.withOpacity(0.6),
                  FontWeight.normal)
                ),
                const SizedBox(
                  height: 10,
                ),
                CustomButton(
                  text: "Shop Now",
                  btnWidth: 150.w,
                )
              ],
            ),),
          ))
        ],
      ),
    );
  }
}


List<String> images = [
  "https://www.freewebheaders.com/wp-content/gallery/houses/cache/nice-house-and-garden-header.jpg-nggid03629-ngg0dyn-1280x375x100-00f0w010c010r110f110r010t010.jpg",
  "https://www.freewebheaders.com/wp-content/gallery/beautiful-landscape/amazing-house-on-lake-reflection-landscape-web-header.jpg",
  "https://img.freepik.com/free-photo/3d-render-house-countryside_1048-13116.jpg"
];