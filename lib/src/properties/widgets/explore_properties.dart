import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/shimmers/list_shimmer.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

class ExploreProperties extends StatefulWidget {
  final List<PropertyListModel>? filteredProperties;

  const ExploreProperties({super.key, this.filteredProperties});

  @override
  State<ExploreProperties> createState() => _ExplorePropertiesState();
}

class _ExplorePropertiesState extends State<ExploreProperties> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void initState() {
    super.initState();
    
    if (widget.filteredProperties == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final propertyNotifier = context.read<PropertyNotifier>();
        // Only fetch properties if they haven't been loaded yet (e.g., from splash screen)
        if (propertyNotifier.properties.isEmpty && !propertyNotifier.isLoading) {
          debugPrint("ExploreProperties: Properties not preloaded, fetching now...");
          propertyNotifier.fetchProperties();
        } else if (propertyNotifier.properties.isNotEmpty) {
          debugPrint("ExploreProperties: Properties already loaded (${propertyNotifier.properties.length} items)");
        }
      });
    }
    
    // Initialize wishlist state when component loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final accessToken = Storage().getString('accessToken');
      final wishlistNotifier = context.read<WishlistNotifier>();
      
      if (accessToken != null) {
        // User is logged in - load their wishlist to ensure proper state
        wishlistNotifier.loadWishlistFromStorage();
        wishlistNotifier.fetchWishlist();
      } else {
        // No user logged in - clear wishlist
        wishlistNotifier.clearWishlist();
      }
    });
    
    // Add scroll listener for infinite scrolling
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  // Handle scroll events for infinite loading
  void _scrollListener() {
    // Check if we're close to bottom of the list
    if (_scrollController.hasClients && 
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 500) {
      debugPrint("Scroll triggered, loading more properties...");
      if (widget.filteredProperties != null) {
        // Using filtered properties
        final filterNotifier = context.read<FilterNotifier>();
        if (!filterNotifier.isLoadingMore && filterNotifier.nextPageUrl != null) {
          debugPrint("Loading more filtered properties");
          filterNotifier.loadMoreFilteredProperties();
        }
      } else {
        // Using all properties
        final propertyNotifier = context.read<PropertyNotifier>();
        if (!propertyNotifier.isLoadingMore && propertyNotifier.nextPageUrl != null) {
          debugPrint("Loading more properties");
          propertyNotifier.loadMoreProperties();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyNotifier = context.watch<PropertyNotifier>();
    final filterNotifier = context.watch<FilterNotifier>();
    
    final properties = widget.filteredProperties ?? propertyNotifier.properties;
    final isLoadingMore = widget.filteredProperties != null 
        ? filterNotifier.isLoadingMore 
        : propertyNotifier.isLoadingMore;
    
    final totalCount = widget.filteredProperties != null 
        ? filterNotifier.totalPropertiesCount 
        : propertyNotifier.totalPropertiesCount;
        
    String? accessToken = Storage().getString('accessToken');

    if (properties.isEmpty && (propertyNotifier.isLoading || filterNotifier.isLoading)) {
      return const ListShimmer();
    }
    
    if (properties.isEmpty) {
      return Center(
        child: Text(
          "No properties found",
          style: appStyle(16, Kolors.kDark, FontWeight.w500),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.filteredProperties != null) {
          await context.read<FilterNotifier>().applyFilters();
        } else {
          await context.read<PropertyNotifier>().fetchProperties();
        }
      },
      color: Kolors.kPrimary,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Properties count header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: Consumer<FilterNotifier>(
                builder: (context, filterNotifier, child) {
                  String headerText;
                  if (filterNotifier.searchKey.isNotEmpty) {
                    headerText = "Found $totalCount properties for \"${filterNotifier.searchKey}\"";
                  } else {
                    headerText = "Showing $totalCount properties";
                  }
                  
                  return Text(
                    headerText,
                    style: appStyle(16, Kolors.kDark, FontWeight.w600),
                  );
                },
              ),
            ),
          ),
          
          // List of properties
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == properties.length) {
                  // Show loading indicator at the bottom
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      child: const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Kolors.kPrimary),
                      ),
                    ),
                  );
                }
                
                final property = properties[index];
                return StaggeredTileWidget(
                  onTap: () {
                    if (accessToken == null) {
                      loginBottomSheet(context);
                    } else {
                      context.read<WishlistNotifier>().toggleWishlist(
                        property.id,
                        () {}
                      );
                    }
                  },
                  property: property,
                );
              },
              childCount: properties.length + (isLoadingMore ? 1 : 0),
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
