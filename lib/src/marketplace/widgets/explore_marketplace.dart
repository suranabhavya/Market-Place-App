import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/common/utils/share_utils.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

class ExploreMarketplace extends StatefulWidget {
  final List<MarketplaceListModel> marketplaceItems;
  final Function? onWishlistUpdated;
  final Function? onRefresh;

  const ExploreMarketplace({
    super.key,
    required this.marketplaceItems,
    this.onWishlistUpdated,
    this.onRefresh,
  });

  @override
  State<ExploreMarketplace> createState() => _ExploreMarketplaceState();
}

class _ExploreMarketplaceState extends State<ExploreMarketplace> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    // Add scroll listener for infinite scrolling (if needed in future)
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Handle scroll events for potential infinite loading in the future
  void _scrollListener() {
    // This can be implemented later if pagination is added to marketplace
    // Currently marketplace doesn't have pagination like properties
  }

  Future<void> _handleRefresh() async {
    // Call the refresh callback if provided
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    } else {
      // Fallback: refresh marketplace items directly
      final marketplaceNotifier = context.read<MarketplaceNotifier>();
      await marketplaceNotifier.applyFilters();
    }
  }

  String _getCityStatePostcode(MarketplaceListModel item) {
    List<String> locationParts = [];
    
    if (item.city != null && item.city!.isNotEmpty) {
      locationParts.add(item.city!);
    }
    
    if (item.state != null && item.state!.isNotEmpty) {
      locationParts.add(item.state!);
    }
    
    if (item.pincode != null && item.pincode!.isNotEmpty) {
      locationParts.add(item.pincode!);
    }
    
    return locationParts.isNotEmpty ? locationParts.join(', ') : 'Location not available';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.marketplaceItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        color: Kolors.kPrimary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              child: Center(
                child: ReusableText(
                  text: "No items found",
                  style: appStyle(14, Kolors.kGray, FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Kolors.kPrimary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Items count header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Consumer<MarketplaceNotifier>(
                builder: (context, marketplaceNotifier, child) {
                  final bool hasSearchTerm = marketplaceNotifier.searchKey.isNotEmpty;
                  
                  return Text(
                    hasSearchTerm 
                        ? "Found ${widget.marketplaceItems.length} items for '${marketplaceNotifier.searchKey}'"
                        : "Showing ${widget.marketplaceItems.length} items",
                    style: appStyle(16, Kolors.kDark, FontWeight.w600),
                  );
                },
              ),
            ),
          ),
          
          // Grid of marketplace items
          SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = widget.marketplaceItems[index];
                final String? imageUrl = item.images.isNotEmpty ? item.images.first.image : null;

                return GestureDetector(
                  onTap: () => context.push('/marketplace/${item.id}'),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                color: Colors.grey[200],
                                child: imageUrl != null && imageUrl.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (context, error, stackTrace) {
                                            return const Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: Kolors.kGray,
                                                size: 32,
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Kolors.kGray,
                                          size: 32,
                                        ),
                                      ),
                              ),
                            ),
                            
                            // Item details
                            Padding(
                              padding: EdgeInsets.all(8.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: appStyle(14, Kolors.kPrimary, FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Text(
                                        '\$${item.price}',
                                        style: appStyle(16, Kolors.kPrimary, FontWeight.bold),
                                      ),
                                      SizedBox(width: 4.w),
                                      if (item.originalPrice != null && item.originalPrice! > item.price)
                                        Text(
                                          '\$${item.originalPrice}',
                                          style: appStyle(12, Kolors.kGray, FontWeight.w400).copyWith(
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    item.hideAddress
                                        ? _getCityStatePostcode(item)
                                        : item.address,
                                    style: appStyle(12, Kolors.kGray, FontWeight.w400),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        // Action buttons
                        Positioned(
                          right: 8.h,
                          top: 8.h,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Share button
                              GestureDetector(
                                onTap: () async {
                                  try {
                                    await ShareUtils.shareMarketplaceItemFromList(item);
                                  } catch (e) {
                                    debugPrint('Error sharing marketplace item: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Failed to share item. Please try again.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
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
                                  final isInWishlist = wishlistNotifier.wishlist.contains(item.id);
                                  
                                  return GestureDetector(
                                    onTap: () {
                                      final accessToken = Storage().getString('accessToken');
                                      if (accessToken == null) {
                                        loginBottomSheet(context);
                                      } else {
                                        wishlistNotifier.toggleWishlist(
                                          item.id,
                                          () {
                                            // Refetch callback
                                            if (widget.onWishlistUpdated != null) {
                                              widget.onWishlistUpdated!();
                                            }
                                          },
                                          type: 'marketplace', // Specify that this is a marketplace item
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
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: widget.marketplaceItems.length,
            ),
          ),
          
          // Add extra space at the bottom to ensure we can scroll past the last item
          SliverToBoxAdapter(
            child: SizedBox(height: 100.h),
          ),
        ],
      ),
    );
  }
}