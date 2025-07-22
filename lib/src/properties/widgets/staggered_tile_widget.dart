import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/share_utils.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';


class StaggeredTileWidget extends StatefulWidget {
  const StaggeredTileWidget({
    super.key, 
    required this.property, 
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  // final int i;
  final PropertyListModel property;
  final void Function()? onTap;
  final void Function()? onEdit;
  final void Function()? onDelete;

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

    // Auto-slide every 5 seconds if there are multiple images
    if (widget.property.images != null && widget.property.images!.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (_currentPage < widget.property.images!.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        
        if (_pageController.hasClients) {
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
  
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Delete Property",
            style: appStyle(16.sp, Kolors.kPrimary, FontWeight.bold),
          ),
          content: Text(
            "Are you sure you want to delete this property? This action cannot be undone.",
            style: appStyle(12.sp, Kolors.kPrimary, FontWeight.w400),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: appStyle(12.sp, Kolors.kPrimary, FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (widget.onDelete != null) {
                  widget.onDelete!();
                }
              },
              child: Text(
                "Delete",
                style: appStyle(12.sp, Kolors.kRed, FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getCityStatePostcode() {
    List<String> locationParts = [];
    
    if (widget.property.city != null && widget.property.city!.isNotEmpty) {
      locationParts.add(widget.property.city!);
    }
    
    if (widget.property.state != null && widget.property.state!.isNotEmpty) {
      locationParts.add(widget.property.state!);
    }
    
    if (widget.property.pincode != null && widget.property.pincode!.isNotEmpty) {
      locationParts.add(widget.property.pincode!);
    }
    
    return locationParts.isNotEmpty ? locationParts.join(', ') : 'Location not available';
  }

  void _handleShare() async {
    try {
      await ShareUtils.sharePropertyFromList(widget.property);
    } catch (e) {
      debugPrint('Error sharing property: $e');
      if (mounted) {
        _showErrorSnackBar();
      }
    }
  }

  void _showErrorSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share property. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
      child: Card(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Property Image
            Stack(
              children: [
                SizedBox(
                  height: 200.h,
                  width: double.infinity,
                  child: (widget.property.images != null && widget.property.images!.isNotEmpty)
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: widget.property.images?.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            widget.property.images![index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Kolors.kGray,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Kolors.kPrimary,
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.image_not_supported,
                                size: 80,
                                color: Kolors.kGray,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                "No images",
                                style: appStyle(16.sp, Kolors.kGray, FontWeight.w400),
                              ),
                            ],
                          ),
                        ),
                      ),
                ),

                if (widget.property.images != null && widget.property.images!.length > 1)
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Share button
                      GestureDetector(
                        onTap: () => _handleShare(),
                        child: CircleAvatar(
                          radius: 15.r,
                          backgroundColor: Kolors.kSecondaryLight,
                          child: Icon(
                            Icons.share,
                            color: Kolors.kGray,
                            size: 15.r,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      // Wishlist button
                      Consumer<WishlistNotifier>(
                        builder: (context, wishlistNotifier, child) {
                          return GestureDetector(
                            onTap: widget.onTap ?? () {
                              final accessToken = Storage().getString('accessToken');
                              if (accessToken == null) {
                                loginBottomSheet(context);
                              } else {
                                wishlistNotifier.toggleWishlist(
                                  widget.property.id,
                                  () => setState(() {}), // Simple refresh callback
                                  type: 'property', // Specify this is a property
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 15.r,
                              backgroundColor: Kolors.kSecondaryLight,
                              child: Icon(
                                AntDesign.heart,
                                color: wishlistNotifier.wishlist.contains(widget.property.id)? Kolors.kRed : Kolors.kGray,
                                size: 15.r,
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
                
                // Edit and Delete buttons - only show if onEdit is provided
                if (widget.onEdit != null)
                  Positioned(
                    left: 10.h,
                    top: 10.h,
                    child: Row(
                      children: [
                        // Edit button
                        GestureDetector(
                          onTap: widget.onEdit,
                          child: CircleAvatar(
                            radius: 15.r,
                            backgroundColor: Kolors.kSecondaryLight,
                            child: Icon(
                              Icons.edit,
                              color: Kolors.kPrimary,
                              size: 15.r,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Delete button
                        GestureDetector(
                          onTap: _showDeleteConfirmationDialog,
                          child: CircleAvatar(
                            radius: 15.r,
                            backgroundColor: Kolors.kSecondaryLight,
                            child: Icon(
                              Icons.delete,
                              color: Colors.red,
                              size: 15.r,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            // Property Details
            Padding(
              padding: EdgeInsets.all(10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
                          widget.property.hideAddress
                              ? _getCityStatePostcode()
                              : widget.property.address,
                          style: appStyle(14.sp, Kolors.kGray, FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  // Bedrooms and Bathrooms
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${widget.property.rent}/${widget.property.rentFrequency}',
                        style: appStyle(14.sp, Kolors.kDark, FontWeight.w600),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.property.bedrooms != null) ...[
                            Icon(
                              Icons.bed,
                              size: 14.sp,
                              color: Kolors.kGray,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${widget.property.bedrooms}BR',
                              style: appStyle(12.sp, Kolors.kGray, FontWeight.w400),
                            ),
                          ],
                          if (widget.property.bedrooms != null && widget.property.bathrooms != null)
                            SizedBox(width: 8.w), // Add spacing if both exist
                          if (widget.property.bathrooms != null) ...[
                            Icon(
                              Icons.bathtub,
                              size: 14.sp,
                              color: Kolors.kGray,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${widget.property.bathrooms}BA',
                              style: appStyle(12.sp, Kolors.kGray, FontWeight.w400),
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
    );
  }
}