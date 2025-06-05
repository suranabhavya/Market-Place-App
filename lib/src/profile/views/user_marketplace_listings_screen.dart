import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
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
      debugPrint('Error fetching marketplace items: $e');
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
                              onPressed: () => context.push('/marketplace/create'),
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
                        child: GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8.w,
                            mainAxisSpacing: 8.h,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: userMarketplaceItems.length,
                          itemBuilder: (context, index) {
                            final item = userMarketplaceItems[index];
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
                                          flex: 4,
                                          child: Container(
                                            width: double.infinity,
                                            color: Colors.grey[200],
                                            child: imageUrl != null && imageUrl.isNotEmpty
                                                ? Image.network(
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
                                        Expanded(
                                          flex: 2,
                                          child: Padding(
                                            padding: EdgeInsets.all(8.w),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  item.title,
                                                  style: appStyle(14, Kolors.kDark, FontWeight.w600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4.h),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '\$${item.price}',
                                                        style: appStyle(15, Kolors.kPrimary, FontWeight.bold),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    if (item.originalPrice != null && item.originalPrice! > item.price)
                                                      Text(
                                                        '\$${item.originalPrice}',
                                                        style: appStyle(12, Kolors.kGray, FontWeight.w400).copyWith(
                                                          decoration: TextDecoration.lineThrough,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                  ],
                                                ),
                                                SizedBox(height: 4.h),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        item.itemType,
                                                        style: appStyle(11, Kolors.kGray, FontWeight.w400),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                                                      decoration: BoxDecoration(
                                                        color: item.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                                        borderRadius: BorderRadius.circular(3),
                                                      ),
                                                      child: Text(
                                                        item.isActive ? 'Active' : 'Inactive',
                                                        style: appStyle(9, item.isActive ? Colors.green : Colors.red, FontWeight.w500),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Action buttons for current user
                                    if (isCurrentUser)
                                      Positioned(
                                        top: 8.h,
                                        right: 8.w,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Edit button
                                            GestureDetector(
                                              onTap: () async {
                                                await context.push('/marketplace/edit/${item.id}');
                                                // Refresh after returning from edit
                                                await fetchUserMarketplaceListings();
                                              },
                                              child: Container(
                                                padding: EdgeInsets.all(4.w),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withOpacity(0.8),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.edit,
                                                  color: Colors.white,
                                                  size: 16.sp,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 4.w),
                                            // Delete button
                                            GestureDetector(
                                              onTap: () => _showDeleteConfirmation(item),
                                              child: Container(
                                                padding: EdgeInsets.all(4.w),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.8),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                  size: 16.sp,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    
                                    // Wishlist button for other users
                                    if (!isCurrentUser)
                                      Positioned(
                                        right: 8.h,
                                        top: 8.h,
                                        child: Consumer<WishlistNotifier>(
                                          builder: (context, wishlistNotifier, child) {
                                            final isInWishlist = wishlistNotifier.wishlist.contains(item.id);
                                            
                                            return GestureDetector(
                                              onTap: () {
                                                final accessToken = Storage().getString('accessToken');
                                                if (accessToken == null) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text("Please log in to access wishlist")),
                                                  );
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
                                                backgroundColor: Colors.white.withOpacity(0.9),
                                                child: Icon(
                                                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                                                  color: isInWishlist ? Kolors.kRed : Kolors.kGray,
                                                  size: 15.r,
                                                ),
                                              ),
                                            );
                                          },
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