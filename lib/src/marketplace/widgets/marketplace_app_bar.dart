import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/marketplace/views/marketplace_filter_screen.dart';
import 'package:marketplace_app/src/marketplace/views/marketplace_search_screen.dart';
import 'package:provider/provider.dart';

class MarketplaceAppBar extends StatelessWidget {
  final Function(List<MarketplaceListModel>)? onFilterApplied;
  
  const MarketplaceAppBar({
    super.key,
    this.onFilterApplied,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MarketplaceNotifier>(
      builder: (context, marketplaceNotifier, child) {
        // Remove storage loading since we no longer persist search keys
        
        final String searchText = marketplaceNotifier.searchKey.isNotEmpty 
            ? marketplaceNotifier.searchKey 
            : "Search items, furniture, electronics...";
        
        return AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          title: PreferredSize(
            preferredSize: Size.fromHeight(55.h),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      // Open search screen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MarketplaceSearchPage()),
                      );
                      
                      // Handle the result from search screen
                      if (result != null) {
                        if (result is Map<String, dynamic>) {
                          // New format with search term and filtered items
                          final String? searchTerm = result['searchTerm'];
                          final List<MarketplaceListModel>? filteredItems = result['filteredItems'];
                          
                          if (searchTerm != null) {
                            // Ensure the search key is set in the notifier
                            marketplaceNotifier.setSearchKey(searchTerm);
                          }
                          
                          if (filteredItems != null && onFilterApplied != null) {
                            onFilterApplied!(filteredItems);
                          }
                        } else if (result is List<MarketplaceListModel>) {
                          // Legacy format - just filtered items
                          if (onFilterApplied != null) {
                            onFilterApplied!(result);
                          }
                        }
                      }
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 2.w,),
                      child: Container(
                        height: 40.h,
                        width: ScreenUtil().screenWidth - 80,
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 0.5,
                            color: Kolors.kGrayLight,
                          ),
                          borderRadius: BorderRadius.circular(24)
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                          child: Row(
                            children: [
                              const Icon(
                                Ionicons.search, 
                                size: 20, 
                                color: Kolors.kPrimaryLight
                              ),
                              
                              SizedBox(width: 10.w),
                              
                              Expanded(
                                child: Text(
                                  searchText,
                                  style: appStyle(14, 
                                    marketplaceNotifier.searchKey.isNotEmpty 
                                      ? Kolors.kPrimary 
                                      : Kolors.kGray, 
                                    FontWeight.w400),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              
                              if (marketplaceNotifier.searchKey.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    // Clear search and apply filters
                                    marketplaceNotifier.clearSearch();
                                    marketplaceNotifier.applyFilters(context);
                                    
                                    // If we have a callback, call it with the refreshed items
                                    if (onFilterApplied != null) {
                                      // Use a post frame callback to ensure the API call completes
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        onFilterApplied!(marketplaceNotifier.marketplaceItems);
                                      });
                                    }
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Kolors.kGray,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      // Open filter screen
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MarketplaceFilterPage()),
                      );
                      
                      // If we got filtered items back and we have a callback, use it
                      if (result != null && result is List<MarketplaceListModel> && onFilterApplied != null) {
                        onFilterApplied!(result);
                      }
                    },
                    child: Container(
                      height: 40.h,
                      width: 40.w,
                      decoration: BoxDecoration(
                        color: Kolors.kPrimary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        FontAwesome.sliders,
                        color: Kolors.kWhite,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ),
        );
      }
    );
  }
} 