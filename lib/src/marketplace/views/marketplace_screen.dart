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
      if (accessToken != null) {
        context.read<WishlistNotifier>().fetchWishlist();
      }
      
      // Only fetch items if we don't have filtered items
      if (_currentItems == null) {
        context.read<MarketplaceNotifier>().applyFilters(context);
      }
    });
  }
  
  // Handle filtered items from the filter screen
  void _handleFilteredItems(List<MarketplaceListModel> filteredItems) {
    setState(() {
      _currentItems = filteredItems;
    });
  }
  
  // Refresh the current items display
  void _refreshItems() {
    setState(() {});
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
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
                      if (widget.filteredItems != null || _currentItems != null) ...[
                        SizedBox(height: 8.h),
                        ElevatedButton(
                          onPressed: () {
                            // Reset filters and clear current items
                            marketplaceNotifier.resetFilters();
                            setState(() {
                              _currentItems = null;
                            });
                            // Reload items
                            marketplaceNotifier.applyFilters(context);
                          },
                          child: const Text("Clear Filters"),
                        ),
                      ],
                    ],
                  ),
                )
              : ExploreMarketplace(
                  marketplaceItems: items,
                  onWishlistUpdated: _refreshItems,
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
              // Navigate to create screen with a simple callback when returning
              context.push("/marketplace/create").then((_) {
                // Refresh the marketplace items when returning from create screen
                setState(() {
                  _currentItems = null; // Clear any filtered items
                });
                marketplaceNotifier.applyFilters(context);
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