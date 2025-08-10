import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/src/marketplace/widgets/marketplace_staggered_tile.dart';
import 'package:provider/provider.dart';

class ExploreMarketplace extends StatefulWidget {
  final List<MarketplaceListModel> marketplaceItems;
  final void Function()? onWishlistUpdated;
  final Future<void> Function()? onRefresh;

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
          
          // List of marketplace items (using staggered layout like properties)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = widget.marketplaceItems[index];
                return MarketplaceStaggeredTile(
                  item: item,
                  onWishlistUpdated: widget.onWishlistUpdated,
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