import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/app_routes.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/property_detail_model.dart';
import 'package:flutter/material.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';


class StaggeredTileWidget extends StatelessWidget {
  const StaggeredTileWidget(
    {super.key, required this.i, required this.property, this.onTap}
  );

  final int i;
  final PropertyListModel property;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    // String? accessToken = Storage().getString('accessToken');


    return GestureDetector(
      onTap: () {
        context.read<PropertyNotifier>().setProperty(property);
        context.push('/property/${property.id}');
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Card(
          margin: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    property.images.isNotEmpty 
                    ? CachedNetworkImage(
                      height: 220.h,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      imageUrl: property.images.isNotEmpty 
                        ? property.images[0] 
                        : 'https://static.thenounproject.com/png/944120-200.png',
                    ) : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 16.h),
                          const Icon(
                            Icons.image_not_supported,
                            size: 120,
                            color: Kolors.kGray,
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            "No images available",
                            style: appStyle(14.sp, Kolors.kGray, FontWeight.w400),
                          ),
                          SizedBox(height: 16.h),
                        ],
                      ),
                    ),

                    Positioned(
                      right: 10.h,
                      top: 10.h,
                      child: Consumer<WishlistNotifier>(
                        builder: (context, wishlistNotifier, child) {
                          return GestureDetector(
                            onTap: onTap,
                            child: CircleAvatar(
                              backgroundColor: Kolors.kSecondaryLight,
                              child: Icon(
                                AntDesign.heart,
                                color: wishlistNotifier.wishlist.contains(property.id)? Kolors.kRed : Kolors.kGray,
                              ),
                            ),
                          );
                        }
                      )
                    ),
                  ],
                ),
              ),
              // Property Details
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      property.title,
                      style: appStyle(16.sp, Kolors.kDark, FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 4.h),
                    // Location and Rent
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            property.address,
                            style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        // SizedBox(width: 8.w),
                        // Text(
                        //   '\$${property.rent.toStringAsFixed(0)}/${property.rentFrequency}',
                        //   style: appStyle(15.sp, Kolors.kDark, FontWeight.w500),
                        // ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    // Bedrooms and Bathrooms
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${property.rent}/${property.rentFrequency}',
                          style: appStyle(15.sp, Kolors.kDark, FontWeight.w500),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.bed,
                              size: 16.sp,
                              color: Kolors.kGray,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${property.bedrooms}BR',
                              style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              Icons.bathtub,
                              size: 16.sp,
                              color: Kolors.kGray,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${property.bathrooms}BA',
                              style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    
    // return GestureDetector(
    //   onTap: () {},
    //   child: Card(
    //     margin: EdgeInsets.symmetric(vertical: 2.h),
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(12),
    //     ),
    //     child: Column(
    //       crossAxisAlignment: CrossAxisAlignment.start,
    //       children: [
    //         // Property Image
    //         ClipRRect(
    //           borderRadius: BorderRadius.circular(12),
    //           child: Stack(
    //             children: [
    //               CachedNetworkImage(
    //                 height: 200.h,
    //                 width: double.infinity,
    //                 fit: BoxFit.cover,
    //                 imageUrl: property.images[0],
    //               ),
    //               // Wishlist Icon
    //               Positioned(
    //                 right: 10.h,
    //                 top: 10.h,
    //                 child: CircleAvatar(
    //                   radius: 14.h,
    //                   backgroundColor: Kolors.kSecondaryLight.withOpacity(0.8),
    //                   child: const Icon(
    //                     AntDesign.heart,
    //                     color: Kolors.kRed,
    //                     size: 18,
    //                   ),
    //                 ),
    //               ),
    //             ],
    //           ),
    //         ),
    //         Property Details
    //         Padding(
    //           padding: EdgeInsets.symmetric(horizontal: 2.h),
    //           child: Column(
    //             crossAxisAlignment: CrossAxisAlignment.start,
    //             children: [
    //               // Title
    //               Text(
    //                 property.title,
    //                 style: appStyle(16.sp, Kolors.kDark, FontWeight.w600),
    //                 overflow: TextOverflow.ellipsis,
    //                 maxLines: 1,
    //               ),
    //               SizedBox(height: 4.h),
    //               // Location and Rent
    //               Row(
    //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //                 children: [
    //                   Expanded(
    //                     child: Text(
    //                       property.description,
    //                       style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
    //                       overflow: TextOverflow.ellipsis,
    //                       maxLines: 1,
    //                     ),
    //                   ),
    //                   SizedBox(width: 8.w),
    //                   Text(
    //                     '\$${property.rent.toStringAsFixed(0)}/${property.rentFrequency}',
    //                     style: appStyle(15.sp, Kolors.kDark, FontWeight.w500),
    //                   ),
    //                 ],
    //               ),
    //               SizedBox(height: 8.h),
    //               // Bedrooms and Bathrooms
    //               Row(
    //                 children: [
    //                   Icon(
    //                     Icons.bed,
    //                     size: 16.sp,
    //                     color: Kolors.kGray,
    //                   ),
    //                   SizedBox(width: 4.w),
    //                   Text(
    //                     '${property.bedrooms}BR',
    //                     style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
    //                   ),
    //                   SizedBox(width: 16.w),
    //                   Icon(
    //                     Icons.bathtub,
    //                     size: 16.sp,
    //                     color: Kolors.kGray,
    //                   ),
    //                   SizedBox(width: 4.w),
    //                   Text(
    //                     '${property.bathrooms}BA',
    //                     style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
    //                   ),
    //                 ],
    //               ),
    //             ],
    //           ),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
   
   
    // return GestureDetector(
    //   onTap: () {

    //   },
    //   child: ClipRRect(
    //     borderRadius: BorderRadius.circular(12),
    //     child: Container(
    //       color: Kolors.kOffWhite,
    //       child: Column(
    //         crossAxisAlignment: CrossAxisAlignment.start,
    //         children: [
    //           Container(
    //             // height: i % 2 == 0 ? 163.h : 180.h,
    //             height: 180.h,
    //             color: Kolors.kPrimary,
    //             child: Stack(
    //               children: [
    //                 CachedNetworkImage(
    //                   // height: i % 2 == 0 ? 163.h : 180.h,
    //                   height: 400.h,
    //                   fit: BoxFit.cover,
    //                   imageUrl: property.images[0],
    //                 ),

    //                 Positioned(
    //                   right: 10.h,
    //                   top: 10.h,
    //                   child: CircleAvatar(
    //                     radius: 14.h,
    //                     backgroundColor: Kolors.kSecondaryLight.withOpacity(0.8),
    //                     child: const Icon(
    //                       AntDesign.heart,
    //                       color: Kolors.kRed,
    //                       size: 18
    //                     ),
    //                   ),
    //                 )
    //               ],
    //             ),
    //           ),

    //           Padding(
    //             padding: EdgeInsets.symmetric(horizontal: 2.h),
    //             child: Row(
    //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //               children: [
    //                 SizedBox(
    //                   width: MediaQuery.of(context).size.width * 0.3,
    //                   child: Text(
    //                     property.title,
    //                     overflow: TextOverflow.ellipsis,
    //                     style: appStyle(13, Kolors.kDark, FontWeight.w600)
    //                   ),
    //                 ),
    //               ],
    //             ),
    //           ),

    //           Padding(
    //             padding: EdgeInsets.symmetric(horizontal: 2.w),
    //             child: ReusableText(
    //               text: '\$${property.rent.toStringAsFixed(2)}/${property.rentFrequency}',
    //               style: appStyle(17, Kolors.kDark, FontWeight.w500)
    //             ),
    //           )
    //         ],
    //       ),
    //     ),
    //   ),
    // );
  }
}