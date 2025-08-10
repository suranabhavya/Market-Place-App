import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/share_utils.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

class MarketplaceStaggeredTile extends StatefulWidget {
  const MarketplaceStaggeredTile({
    super.key,
    required this.item,
    this.onTap,
    this.onWishlistUpdated,
  });

  final MarketplaceListModel item;
  final void Function()? onTap;
  final void Function()? onWishlistUpdated;

  @override
  State<MarketplaceStaggeredTile> createState() => _MarketplaceStaggeredTileState();
}

class _MarketplaceStaggeredTileState extends State<MarketplaceStaggeredTile> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Auto-slide every 5 seconds if there are multiple images
    if (widget.item.images.isNotEmpty && widget.item.images.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
        if (_currentPage < widget.item.images.length - 1) {
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

  String _getCityStatePostcode() {
    List<String> locationParts = [];
    
    if (widget.item.city != null && widget.item.city!.isNotEmpty) {
      locationParts.add(widget.item.city!);
    }
    
    if (widget.item.state != null && widget.item.state!.isNotEmpty) {
      locationParts.add(widget.item.state!);
    }
    
    if (widget.item.pincode != null && widget.item.pincode!.isNotEmpty) {
      locationParts.add(widget.item.pincode!);
    }
    
    return locationParts.isNotEmpty ? locationParts.join(', ') : 'Location not available';
  }

  void _handleShare() async {
    try {
      await ShareUtils.shareMarketplaceItemFromList(widget.item);
    } catch (e) {
      debugPrint('Error sharing marketplace item: $e');
      if (mounted) {
        _showErrorSnackBar();
      }
    }
  }

  void _showErrorSnackBar() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to share item. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/marketplace/${widget.item.id}'),
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
            // Item Image
            Stack(
              children: [
                SizedBox(
                  height: 200.h,
                  width: double.infinity,
                  child: widget.item.images.isNotEmpty
                    ? PageView.builder(
                        controller: _pageController,
                        itemCount: widget.item.images.length,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Image.network(
                            widget.item.images[index].image,
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

                // Image dots indicator (if multiple images)
                if (widget.item.images.length > 1)
                  Positioned(
                    bottom: 10.h,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.item.images.length,
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

                // Action buttons (Share and Wishlist)
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
                          backgroundColor: Kolors.kWhite,
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
                          final isInWishlist = wishlistNotifier.wishlist.contains(widget.item.id);
                          
                          return GestureDetector(
                            onTap: widget.onTap ?? () {
                              final accessToken = Storage().getString('accessToken');
                              if (accessToken == null) {
                                loginBottomSheet(context);
                              } else {
                                wishlistNotifier.toggleWishlist(
                                  widget.item.id,
                                  () {
                                    if (widget.onWishlistUpdated != null) {
                                      widget.onWishlistUpdated!();
                                    }
                                  },
                                  type: 'marketplace',
                                );
                              }
                            },
                            child: CircleAvatar(
                              radius: 15.r,
                              backgroundColor: Kolors.kWhite,
                              child: Icon(
                                isInWishlist ? Icons.favorite : Icons.favorite_border,
                                color: isInWishlist ? Kolors.kRed : Kolors.kGray,
                                size: 15.r,
                              ),
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Item Details
            Padding(
              padding: EdgeInsets.all(10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    widget.item.title,
                    style: appStyle(16.sp, Kolors.kDark, FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4.h),
                  
                  // Location
                  Text(
                    widget.item.hideAddress
                        ? _getCityStatePostcode()
                        : widget.item.address,
                    style: appStyle(14.sp, Kolors.kGray, FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 6.h),
                  
                  // Price and Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price
                      Row(
                        children: [
                          Text(
                            '\$${widget.item.price.toStringAsFixed(widget.item.price.truncateToDouble() == widget.item.price ? 0 : 2)}',
                            style: appStyle(16.sp, Kolors.kDark, FontWeight.bold),
                          ),
                          SizedBox(width: 4.w),
                          if (widget.item.originalPrice != null && widget.item.originalPrice! > widget.item.price)
                            Text(
                              '\$${widget.item.originalPrice!.toStringAsFixed(widget.item.originalPrice!.truncateToDouble() == widget.item.originalPrice! ? 0 : 2)}',
                              style: appStyle(12.sp, Kolors.kGray, FontWeight.w400).copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      
                      // Category
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Kolors.kPrimaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.item.itemSubtype,
                          style: appStyle(10.sp, Kolors.kPrimary, FontWeight.w500),
                        ),
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
