import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/empty_screen_widget.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/shimmers/list_shimmer.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:marketplace_app/src/wishlist/hooks/fetch_wishlist.dart';
import 'package:marketplace_app/common/utils/share_utils.dart';
import 'package:provider/provider.dart';

class WishlistWidget extends HookWidget {
  const WishlistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final results = useFetchWishlist();
    final wishlistItems = results.wishlistItems;
    final isLoading = results.isLoading;
    final refetch = results.refetch;

    if (isLoading) {
      return const ListShimmer();
    }

    return wishlistItems.isEmpty
        ? const EmptyScreenWidget()
        : Consumer<WishlistNotifier>(
            builder: (context, wishlistNotifier, child) {
              // Ensure that only items in the local wishlist are displayed
              final filteredItems = wishlistItems
                  .where((item) => wishlistNotifier.wishlist.contains(item.id))
                  .toList();

              if (filteredItems.isEmpty) {
                return const EmptyScreenWidget();
              }

              // Group items by type for better organization
              final propertyItems = filteredItems
                  .where((item) => item.itemType == 'property')
                  .toList();
                  
              final marketplaceItems = filteredItems
                  .where((item) => item.itemType == 'marketplace')
                  .toList();
                  
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Properties section
                  if (propertyItems.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                      child: Text(
                        "Properties",
                        style: appStyle(18, Kolors.kDark, FontWeight.bold),
                      ),
                    ),
                    ...propertyItems.map((item) {
                      final property = item.item as PropertyListModel;
                      return StaggeredTileWidget(
                        property: property,
                        onTap: () {
                          final accessToken = Storage().getString('accessToken');
                          if (accessToken == null) {
                            loginBottomSheet(context);
                          } else {
                            final wishlistNotifier = context.read<WishlistNotifier>();
                            wishlistNotifier.toggleWishlist(
                              property.id,
                              () {
                                refetch();
                                
                                // Show error message if there was an error
                                if (wishlistNotifier.error != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(wishlistNotifier.error!),
                                      backgroundColor: Kolors.kRed,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                                                         wishlistNotifier.clearError(); // Clear error after showing
                                }
                              },
                              type: 'property',
                            );
                          }
                        },
                      );
                    }),
                  ],
                  
                  // Marketplace items section
                  if (marketplaceItems.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
                      child: Text(
                        "Marketplace Items",
                        style: appStyle(18, Kolors.kDark, FontWeight.bold),
                      ),
                    ),
                    ...marketplaceItems.map((item) => 
                      _buildMarketplaceItem(context, item, refetch)
                    ),
                  ],
                ],
              );
            },
          );
  }
  
  Widget _buildMarketplaceItem(BuildContext context, WishlistItem item, VoidCallback refetch) {
    // Extract data from marketplace item
    final rawItem = item.item as Map<String, dynamic>;
    final String id = rawItem['id'] ?? '';
    final String title = rawItem['title'] ?? '';
    final double price = double.tryParse(rawItem['price']?.toString() ?? '0') ?? 0;
    final double? originalPrice = rawItem['original_price'] != null 
        ? double.tryParse(rawItem['original_price'].toString()) 
        : null;
    final String itemType = rawItem['item_type'] ?? '';
    final String itemSubtype = rawItem['item_subtype'] ?? '';
    final String address = rawItem['address'] ?? '';
    final String imageUrl = item.images.isNotEmpty ? item.images.first : '';
    
    return GestureDetector(
      onTap: () {
        // Navigate to marketplace item detail
        context.push('/marketplace/$id');
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
            // Item Image
            Stack(
              children: [
                SizedBox(
                  height: 200.h,
                  width: double.infinity,
                  child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                          const Icon(Icons.broken_image, size: 60, color: Kolors.kGray),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: Kolors.kGray,
                          ),
                        ),
                      ),
                ),
                
                // Share and Wishlist buttons
                Positioned(
                  right: 10.h,
                  top: 10.h,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Share button
                      GestureDetector(
                        onTap: () async {
                          try {
                            // Create a marketplace list model from the raw data for sharing
                            final marketplaceItem = MarketplaceListModel(
                              id: id,
                              title: title,
                              price: price,
                              originalPrice: originalPrice,
                              itemType: itemType,
                              itemSubtype: itemSubtype,
                              address: address,
                              hideAddress: false, // Default value
                              city: rawItem['city'] ?? '',
                              state: rawItem['state'] ?? '',
                              createdAt: DateTime.now(), // Default value
                              updatedAt: DateTime.now(), // Default value
                              isActive: true, // Default value
                              images: item.images.map((img) => MarketplaceImage(
                                id: '', // Default empty ID
                                image: img,
                                uploadedAt: DateTime.now(), // Default timestamp
                              )).toList(),
                            );
                            await ShareUtils.shareMarketplaceItemFromList(marketplaceItem);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error sharing item: $e'),
                                  backgroundColor: Kolors.kRed,
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
                          return GestureDetector(
                            onTap: () {
                              final accessToken = Storage().getString('accessToken');
                              if (accessToken == null) {
                                loginBottomSheet(context);
                              } else {
                                wishlistNotifier.toggleWishlist(
                                  id,
                                  () {
                                    refetch();
                                    
                                    // Show error message if there was an error
                                    if (wishlistNotifier.error != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(wishlistNotifier.error!),
                                          backgroundColor: Kolors.kRed,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                      wishlistNotifier.clearError(); // Clear error after showing
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
                                Icons.favorite,
                                color: Kolors.kRed,
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
            
            // Item Details
            Padding(
              padding: EdgeInsets.all(10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    style: appStyle(16.sp, Kolors.kDark, FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  SizedBox(height: 4.h),
                  
                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          address,
                          style: appStyle(14.sp, Kolors.kGray, FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  
                  // Price and Item Type
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '\$${price.toStringAsFixed(0)}',
                            style: appStyle(14.sp, Kolors.kDark, FontWeight.w600),
                          ),
                          if (originalPrice != null && originalPrice > price) ...[
                            SizedBox(width: 4.w),
                            Text(
                              '\$${originalPrice.toStringAsFixed(0)}',
                              style: appStyle(12.sp, Kolors.kGray, FontWeight.w400).copyWith(
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (itemType.isNotEmpty || itemSubtype.isNotEmpty)
                        Text(
                          itemSubtype.isNotEmpty ? itemSubtype : itemType,
                          style: appStyle(12.sp, Kolors.kGray, FontWeight.w500),
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
