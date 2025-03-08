import 'dart:async';

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


class StaggeredTileWidget extends StatefulWidget {
  const StaggeredTileWidget(
    {super.key, required this.property, this.onTap}
  );

  // final int i;
  final PropertyListModel property;
  final void Function()? onTap;

  @override
  State<StaggeredTileWidget> createState() => _StaggeredTileWidgetState();
}

class _StaggeredTileWidgetState extends State<StaggeredTileWidget> {

  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Auto-slide every 2 seconds
    if (widget.property.images != null && widget.property.images!.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (widget.property.images!.isNotEmpty) {
          if (_currentPage < widget.property.images!.length - 1) {
            _currentPage++;
          } else {
            _currentPage = 0;
          }
          _pageController.animateToPage(
            _currentPage,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<PropertyNotifier>().setProperty(widget.property);
        });
        context.push('/property/${widget.property.id}');
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
                    SizedBox(
                      height: 220.h,
                      width: double.infinity,
                      child: widget.property.images!.isNotEmpty
                        ? PageView.builder(
                            controller: _pageController,
                            itemCount: widget.property.images?.length,
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: widget.property.images![index],
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image, size: 100, color: Kolors.kGray),
                              );
                            },
                          )
                        : Center(
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
                    ),

                    if (widget.property.images!.length > 1)
                      Positioned(
                        bottom: 10.h,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.property.images!.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              height: 6,
                              width: _currentPage == index ? 14 : 6,
                              decoration: BoxDecoration(
                                color: _currentPage == index ? Kolors.kPrimary : Kolors.kGray,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),

                    Positioned(
                      right: 10.h,
                      top: 10.h,
                      child: Consumer<WishlistNotifier>(
                        builder: (context, wishlistNotifier, child) {
                          return GestureDetector(
                            onTap: widget.onTap,
                            child: CircleAvatar(
                              backgroundColor: Kolors.kSecondaryLight,
                              child: Icon(
                                AntDesign.heart,
                                color: wishlistNotifier.wishlist.contains(widget.property.id)? Kolors.kRed : Kolors.kGray,
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
                      widget.property.title,
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
                            widget.property.address,
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
                          '\$${widget.property.rent}/${widget.property.rentFrequency}',
                          style: appStyle(15.sp, Kolors.kDark, FontWeight.w500),
                        ),
                        Row(
                          children: [
                            if (widget.property.bedrooms != null) ...[
                              Icon(
                                Icons.bed,
                                size: 16.sp,
                                color: Kolors.kGray,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${widget.property.bedrooms}BR',
                                style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
                              ),
                            ],
                            if (widget.property.bedrooms != null && widget.property.bathrooms != null)
                              SizedBox(width: 8.w), // Add spacing if both exist
                            if (widget.property.bathrooms != null) ...[
                              Icon(
                                Icons.bathtub,
                                size: 16.sp,
                                color: Kolors.kGray,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '${widget.property.bathrooms}BA',
                                style: appStyle(13.sp, Kolors.kGray, FontWeight.w400),
                              ),
                            ],
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
  }
}