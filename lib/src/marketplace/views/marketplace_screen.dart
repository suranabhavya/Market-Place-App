import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/shimmers/list_shimmer.dart';
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
  String _lastSearchKey = ''; // Track the last search key to detect changes
  bool _isFirstFrame = true; // Prevent empty-state flash before splash data arrives
  
  @override
  void initState() {
    super.initState();
    // Initialize with any filtered items passed in
    _currentItems = widget.filteredItems;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load marketplace items when user first visits this tab
      if (_currentItems == null) {
        final marketplaceNotifier = context.read<MarketplaceNotifier>();

        // refreshMarketplaceItems handles everything: cache load + background refresh
        // Marketplace should be preloaded from splash, but this ensures it's loaded
        await marketplaceNotifier.refreshMarketplaceItems();

        debugPrint('MarketplacePage: Marketplace ready (from preload or cache)');
      }

      // Clear first-frame guard after initial post-frame work completes
      if (mounted) {
        setState(() {
          _isFirstFrame = false;
        });
      }
    });
  }
  
  // Handle filtered items from the filter screen
  void _handleFilteredItems(List<MarketplaceListModel> filteredItems) {
    debugPrint('MarketplaceScreen - _handleFilteredItems called with ${filteredItems.length} items');
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

  

  // Handle refresh from pull-to-refresh
  Future<void> _handleRefresh() async {
    final marketplaceNotifier = context.read<MarketplaceNotifier>();
    
    // Clear any filtered items to show all items after refresh
    setState(() {
      _currentItems = null;
    });
    
    // Refresh marketplace items
    await marketplaceNotifier.refreshMarketplaceItems();
    
    // Also refresh wishlist if user is logged in
    final accessToken = Storage().getString('accessToken');
    if (accessToken != null && mounted) {
      await context.read<WishlistNotifier>().fetchWishlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
    final marketplaceNotifier = context.watch<MarketplaceNotifier>();
    
    // Check if search key has changed and clear local state if needed
    if (_lastSearchKey != marketplaceNotifier.searchKey) {
      if (marketplaceNotifier.searchKey.isEmpty && _lastSearchKey.isNotEmpty) {
        // Search was cleared, reset local state
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentItems = null;
            });
          }
        });
      }
      _lastSearchKey = marketplaceNotifier.searchKey;
    }
    
  // Use current items if we have them, otherwise use items from notifier
  final List<MarketplaceListModel> items = _currentItems ?? marketplaceNotifier.marketplaceItems;
  final bool isLoading = (
    _currentItems == null && (marketplaceNotifier.isLoading || _isFirstFrame)
  );
    
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: MarketplaceAppBar(
          onFilterApplied: _handleFilteredItems,
        )
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: isLoading
            ? const ListShimmer()
            : items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: Kolors.kGray),
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
                  onWishlistUpdated: () {},
                  onRefresh: () => _handleRefresh(),
                ),
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 48.w),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Kolors.kPrimary.withOpacity(0.8),
                    Kolors.kPrimaryLight.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(
                  color: Kolors.kPrimaryLight.withOpacity(0.8),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Kolors.kPrimary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Kolors.kPrimaryLight.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(25.r),
                  onTap: () {
                    if (accessToken == null) {
                      loginBottomSheet(context);
                    } else {
                      // Capture notifiers before async operation
                      final marketplaceNotifier = context.read<MarketplaceNotifier>();
                      final wishlistNotifier = context.read<WishlistNotifier>();
                      
                      // Navigate to create screen with a callback when returning
                      context.push("/marketplace/create").then((_) async {
                        if (mounted) {
                          // Refresh the marketplace items when returning from create screen
                          
                          // Clear any filtered items to show all items including the new one
                          setState(() {
                            _currentItems = null;
                          });
                          
                          // Force refresh of marketplace items
                          await marketplaceNotifier.refreshMarketplaceItems();
                          
                          // Also refresh wishlist in case the new item was added to wishlist
                          await wishlistNotifier.fetchWishlist();
                        }
                      });
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: Kolors.kWhite,
                          size: 24.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'List Items',
                          style: TextStyle(
                            color: Kolors.kWhite,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            shadows: [
                              Shadow(
                                color: Kolors.kDark.withOpacity(0.5),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 