import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:marketplace_app/common/utils/share_utils.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:provider/provider.dart';

class UserMarketplaceListingsPage extends StatefulWidget {
  final int userId;

  const UserMarketplaceListingsPage({super.key, required this.userId});

  @override
  State<UserMarketplaceListingsPage> createState() => _UserMarketplaceListingsPageState();
}

class _UserMarketplaceListingsPageState extends State<UserMarketplaceListingsPage> {
  List<MarketplaceListModel> userMarketplaceItems = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchUserMarketplaceListings();
  }

  Future<void> fetchUserMarketplaceListings() async {
    String? accessToken = Storage().getString('accessToken');

    if (accessToken == null) {
      setState(() {
        errorMessage = "Authentication required";
        isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final marketplaceNotifier = context.read<MarketplaceNotifier>();
      final items = await marketplaceNotifier.fetchUserMarketplaceListings(accessToken);
      
      if (mounted) {
        setState(() {
          userMarketplaceItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = "Error fetching marketplace items: $e";
          isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshListings() async {
    await fetchUserMarketplaceListings();
  }

  Future<void> _showDeleteConfirmation(MarketplaceListModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Delete Item',
            style: appStyle(16, Kolors.kPrimary, FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete "${item.title}"?',
            style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: appStyle(12, Kolors.kPrimary, FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Delete',
                style: appStyle(12, Kolors.kRed, FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _deleteItem(item);
    }
  }

  Future<void> _deleteItem(MarketplaceListModel item) async {
    String? accessToken = Storage().getString('accessToken');
    if (accessToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated")),
      );
      return;
    }

    final marketplaceNotifier = context.read<MarketplaceNotifier>();
    await marketplaceNotifier.deleteMarketplaceItem(
      token: accessToken,
      itemId: item.id,
      onSuccess: () {
        setState(() {
          userMarketplaceItems.removeWhere((i) => i.id == item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Item deleted successfully")),
        );
      },
      onError: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete item")),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<ProfileNotifier>(context).user;
    final bool isCurrentUser = user != null && user.id == widget.userId;
    
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: ReusableText(
          text: isCurrentUser ? "My Marketplace" : "Marketplace Items",
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: isLoading 
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Kolors.kPrimary),
              ),
            )
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 50, color: Kolors.kRed),
                      SizedBox(height: 10.h),
                      Text(
                        errorMessage!,
                        style: appStyle(14, Kolors.kDark, FontWeight.normal),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.h),
                      ElevatedButton(
                        onPressed: _refreshListings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Kolors.kPrimary,
                          foregroundColor: Kolors.kWhite,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : userMarketplaceItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.store_outlined, size: 60, color: Kolors.kGray),
                          SizedBox(height: 15.h),
                          Text(
                            "No Marketplace Items",
                            style: appStyle(16, Kolors.kDark, FontWeight.w500),
                            textAlign: TextAlign.center,
                          ),
                          if (isCurrentUser) ...[
                            SizedBox(height: 10.h),
                            Text(
                              "Create your first marketplace item to get started",
                              style: appStyle(14, Kolors.kGray, FontWeight.normal),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20.h),
                            ElevatedButton(
                              onPressed: () async {
                                await context.push('/marketplace/create');
                                // Refresh after returning from create
                                await fetchUserMarketplaceListings();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Kolors.kPrimaryLight,
                                foregroundColor: Kolors.kWhite,
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Text(
                                'Create Item',
                                style: appStyle(14, Kolors.kWhite, FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshListings,
                      color: Kolors.kPrimary,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: ListView.builder(
                          itemCount: userMarketplaceItems.length,
                          itemBuilder: (context, index) {
                            final item = userMarketplaceItems[index];
                            final String? imageUrl = item.images.isNotEmpty ? item.images.first.image : null;
                            
                            return GestureDetector(
                              onTap: () => context.push('/marketplace/${item.id}'),
                              child: Card(
                                margin: EdgeInsets.symmetric(vertical: 8.h),
                                clipBehavior: Clip.antiAlias,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Image with action buttons
                                    Stack(
                                      children: [
                                        SizedBox(
                                          height: 200.h,
                                          width: double.infinity,
                                          child: imageUrl != null && imageUrl.isNotEmpty
                                              ? Image.network(
                                                  imageUrl,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      color: Colors.grey[200],
                                                      child: const Center(
                                                        child: Icon(
                                                          Icons.image_not_supported,
                                                          color: Kolors.kGray,
                                                          size: 60,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                )
                                              : Container(
                                                  color: Colors.grey[200],
                                                  child: const Center(
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      color: Kolors.kGray,
                                                      size: 60,
                                                    ),
                                                  ),
                                                ),
                                        ),
                                        
                                        // Share and Wishlist buttons - top right
                                        Positioned(
                                          right: 10.w,
                                          top: 10.h,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Share button
                                              GestureDetector(
                                                onTap: () async {
                                                  try {
                                                    await ShareUtils.shareMarketplaceItemFromList(item);
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
                                                  backgroundColor: Kolors.kSecondaryLight,
                                                  child: Icon(
                                                    Icons.share,
                                                    color: Kolors.kGray,
                                                    size: 15.r,
                                                  ),
                                                ),
                                              ),
                                              
                                              SizedBox(width: 8.w),
                                              
                                              // Wishlist button (for all users)
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
                                                          () {},
                                                          type: 'marketplace',
                                                        );
                                                      }
                                                    },
                                                    child: CircleAvatar(
                                                      radius: 15.r,
                                                      backgroundColor: Kolors.kSecondaryLight,
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
                                        
                                        // Edit and Delete buttons for current user - top left
                                        if (isCurrentUser)
                                          Positioned(
                                            left: 10.w,
                                            top: 10.h,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Edit button
                                                GestureDetector(
                                                  onTap: () async {
                                                    await context.push('/marketplace/edit/${item.id}');
                                                    await fetchUserMarketplaceListings();
                                                  },
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
                                                  onTap: () => _showDeleteConfirmation(item),
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
                                    
                                    // Item details
                                    Padding(
                                      padding: EdgeInsets.all(12.w),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Title
                                          Text(
                                            item.title,
                                            style: appStyle(16, Kolors.kDark, FontWeight.w600),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 6.h),
                                          
                                          // Location
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on_outlined,
                                                size: 16.r,
                                                color: Kolors.kGray,
                                              ),
                                              SizedBox(width: 4.w),
                                              Expanded(
                                                child: Text(
                                                  item.hideAddress 
                                                      ? '${item.city ?? ''}, ${item.state ?? ''}'
                                                      : item.address,
                                                  style: appStyle(14, Kolors.kGray, FontWeight.w500),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.h),
                                          
                                          // Price and Item Type
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Price section
                                              Row(
                                                children: [
                                                  Text(
                                                    '\$${item.price.toStringAsFixed(0)}',
                                                    style: appStyle(16, Kolors.kPrimary, FontWeight.bold),
                                                  ),
                                                  if (item.originalPrice != null && item.originalPrice! > item.price) ...[
                                                    SizedBox(width: 6.w),
                                                    Text(
                                                      '\$${item.originalPrice!.toStringAsFixed(0)}',
                                                      style: appStyle(14, Kolors.kGray, FontWeight.w400).copyWith(
                                                        decoration: TextDecoration.lineThrough,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              
                                              // Item type
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: Kolors.kPrimaryLight.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  item.itemType,
                                                  style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
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
                          },
                        ),
                      ),
                    ),
    );
  }
} 