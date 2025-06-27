import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/src/marketplace/widgets/marketplace_app_bar.dart';
import 'package:marketplace_app/src/marketplace/widgets/explore_marketplace.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

class MarketplacePage extends StatefulWidget {
  final List<MarketplaceListModel>? filteredItems;
  
  const MarketplacePage({
    super.key,
    this.filteredItems,
  });

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  List<MarketplaceListModel>? _currentItems;
  
  @override
  void initState() {
    super.initState();
    // Initialize with any filtered items passed in
    _currentItems = widget.filteredItems;
    
    // Load wishlist data and marketplace items on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accessToken = Storage().getString('accessToken');
      final wishlistNotifier = context.read<WishlistNotifier>();
      
      if (accessToken != null) {
        // User is logged in - load their wishlist
        wishlistNotifier.loadWishlistFromStorage();
        wishlistNotifier.fetchWishlist();
      } else {
        // No user logged in - clear wishlist
        wishlistNotifier.clearWishlist();
      }
      
      // Only fetch items if we don't have filtered items
      if (_currentItems == null) {
        final marketplaceNotifier = context.read<MarketplaceNotifier>();
        print('MarketplacePage initState - About to call applyFilters, current searchKey: ${marketplaceNotifier.searchKey}');
        marketplaceNotifier.applyFilters(context);
      } else {
        print('MarketplacePage initState - Using filtered items, not calling applyFilters');
      }
    });
  }
  
  // Handle filtered items from the filter screen
  void _handleFilteredItems(List<MarketplaceListModel> filteredItems) {
    setState(() {
      _currentItems = filteredItems;
    });
    // Force a rebuild to ensure the app bar reflects any search changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  // Refresh the current items display
  void _refreshItems() {
    setState(() {});
  }

  // Handle refresh from pull-to-refresh
  Future<void> _handleRefresh() async {
    final marketplaceNotifier = context.read<MarketplaceNotifier>();
    
    // Clear any filtered items to show all items after refresh
    setState(() {
      _currentItems = null;
    });
    
    // Refresh marketplace items
    await marketplaceNotifier.applyFilters(context);
    
    // Also refresh wishlist if user is logged in
    final accessToken = Storage().getString('accessToken');
    if (accessToken != null) {
      await context.read<WishlistNotifier>().fetchWishlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
    final marketplaceNotifier = context.watch<MarketplaceNotifier>();
    
    // Use current items if we have them, otherwise use items from notifier
    final List<MarketplaceListModel> items = _currentItems ?? marketplaceNotifier.marketplaceItems;
    final bool isLoading = (_currentItems == null && marketplaceNotifier.isLoading) || 
                         context.watch<WishlistNotifier>().isLoading;
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: MarketplaceAppBar(
          onFilterApplied: _handleFilteredItems,
        )
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Kolors.kPrimary),
                ),
              )
            : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Kolors.kGray),
                      SizedBox(height: 16.h),
                      Text(
                        "No marketplace items found",
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          color: Kolors.kGray,
                        ),
                      ),
                    ],
                  ),
                )
              : ExploreMarketplace(
                  marketplaceItems: items,
                  onWishlistUpdated: _refreshItems,
                  onRefresh: _handleRefresh,
                ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 48.w),
        child: FloatingActionButton(
          onPressed: () {
            if (accessToken == null) {
              loginBottomSheet(context);
            } else {
              // Navigate to create screen with a callback when returning
              context.push("/marketplace/create").then((_) async {
                // Refresh the marketplace items when returning from create screen
                print('Returned from create screen, refreshing items...');
                
                // Clear any filtered items to show all items including the new one
                setState(() {
                  _currentItems = null;
                });
                
                // Force refresh of marketplace items
                await marketplaceNotifier.applyFilters(context);
                
                // Also refresh wishlist in case the new item was added to wishlist
                if (accessToken != null) {
                  await context.read<WishlistNotifier>().fetchWishlist();
                }
                
                print('Refresh completed after create');
              });
            }
          },
          backgroundColor: Kolors.kPrimary,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, size: 32, color: Kolors.kWhite),
        ),
      ),
    );
  }
} 