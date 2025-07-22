import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class MarketplaceSearchPage extends StatefulWidget {
  const MarketplaceSearchPage({super.key});

  @override
  State<MarketplaceSearchPage> createState() => _MarketplaceSearchPageState();
}

class _MarketplaceSearchPageState extends State<MarketplaceSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  List<String> _recentSearches = [];
  final List<String> _suggestions = [
    'Furniture',
    'Electronics',
    'Books',
    'Clothing',
    'Kitchen',
    'Appliance',
    'Decor',
  ];
  
  // Store reference to notifier to avoid accessing Provider in dispose
  MarketplaceNotifier? _marketplaceNotifier;

  @override
  void initState() {
    super.initState();
    
    // Store reference to notifier
    _marketplaceNotifier = context.read<MarketplaceNotifier>();
    
    // Initialize the search controller with any existing search query
    if (_marketplaceNotifier!.searchKey.isNotEmpty) {
      _searchController.text = _marketplaceNotifier!.searchKey;
      // Trigger autocomplete for existing search term
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _marketplaceNotifier!.fetchAutocomplete(_searchController.text);
      });
    }
    
    // Add listener to search controller for autocomplete
    _searchController.addListener(_onSearchChanged);
    
    // Load recent searches from storage
    _loadRecentSearches();
    
    // Set focus to the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    // Don't try to update the notifier in dispose as it causes errors
    // The search key is already set in _performSearch when needed
    
    _focusNode.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  // This function is called whenever the text field's value changes
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Debounce to avoid too many API calls - reduced to 250ms for better responsiveness
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (_searchController.text.isNotEmpty) {
        // Only call fetchAutocomplete, don't update the search key here
        // since we're already updating it in the onChanged handler
        _marketplaceNotifier!.fetchAutocomplete(_searchController.text);
      } else {
        _marketplaceNotifier!.clearAutocompleteResults();
        // Clear the search key if the search field is empty
        _marketplaceNotifier!.clearSearch();
      }
    });
  }
  
  // Load recent searches from storage
  void _loadRecentSearches() {
    // This would typically load from shared preferences or other storage
    // For now, we'll use a placeholder
    setState(() {
      _recentSearches = ['Sofa', 'Laptop', 'Desk', 'Chair'];
    });
  }
  
  // Save a search term to recent searches
  void _saveSearch(String term) {
    if (term.isEmpty) return;
    
    setState(() {
      // Remove if already exists and add to the beginning
      _recentSearches.remove(term);
      _recentSearches.insert(0, term);
      
      // Keep only the most recent 5 searches
      if (_recentSearches.length > 5) {
        _recentSearches = _recentSearches.sublist(0, 5);
      }
    });
    
    // This would typically save to shared preferences or other storage
  }
  
  // Perform the search when user selects a suggestion or presses search
  void _performSearch(String query) async {
    if (query.isEmpty) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      // Save to recent searches
      _saveSearch(query);
      
      // Clear autocomplete results first
      _marketplaceNotifier!.clearAutocompleteResults();
      
      // Use the new method to set search key and apply filters in one go
      await _marketplaceNotifier!.setSearchKeyAndApplyFilters(query);
      
      // Get the filtered items from the notifier after API call
      final filteredItems = _marketplaceNotifier!.marketplaceItems;
      
      // Navigate back to marketplace screen with both filtered results and search term
      if (mounted) {
        // Pop back with a map containing both the search term and filtered items
        navigator.pop({
          'searchTerm': query,
          'filteredItems': filteredItems,
        });
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("Search failed: $e"),
          backgroundColor: Kolors.kRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          onTap: () {
            // Clear autocomplete results when going back
            _marketplaceNotifier!.clearAutocompleteResults();
            
            // Clear the search controller text
            _searchController.clear();
            
            // Clear the search key and reset marketplace items to show all
            _marketplaceNotifier!.clearSearch();
            final navigator = Navigator.of(context);
            _marketplaceNotifier!.refreshMarketplaceItems().then((_) {
              if (mounted) {
                // Navigate back with cleared search
                navigator.pop({
                  'searchTerm': '',
                  'filteredItems': _marketplaceNotifier!.marketplaceItems,
                });
              }
            });
          },
        ),
        title: ReusableText(
          text: "Search Marketplace",
          style: appStyle(15, Kolors.kPrimary, FontWeight.bold)
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Consumer<MarketplaceNotifier>(
              builder: (context, marketplaceNotifier, _) {
                return Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    EmailTextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      radius: 30,
                      hintText: "Search furniture, electronics, books...",
                      textInputAction: TextInputAction.search,
                      onChanged: (value) {
                        // Update the search key in the notifier in real-time
                        _marketplaceNotifier!.setSearchKey(value);
                        // The autocomplete API call is handled by the debounce timer
                      },
                      onSubmitted: (value) {
                        if(value.isNotEmpty) {
                          _performSearch(value);
                        }
                      },
                      prefixIcon: GestureDetector(
                        onTap: () {
                          if(_searchController.text.isNotEmpty) {
                            _performSearch(_searchController.text);
                          }
                        },
                        child: const Icon(
                          AntDesign.search1,
                          color: Kolors.kPrimary,
                        ),
                      ),
                      // Add clear button to search field
                      suffixIcon: _searchController.text.isNotEmpty 
                          ? GestureDetector(
                              onTap: () {
                                // Clear the search controller text
                                _searchController.clear();
                                
                                // Clear autocomplete results
                                _marketplaceNotifier!.clearAutocompleteResults();
                                
                                // Clear the search key and reset marketplace items
                                _marketplaceNotifier!.clearSearch();
                                final navigator = Navigator.of(context);
                                _marketplaceNotifier!.refreshMarketplaceItems().then((_) {
                                  if (mounted) {
                                    navigator.pop({
                                      'searchTerm': '',
                                      'filteredItems': _marketplaceNotifier!.marketplaceItems,
                                    });
                                  }
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Kolors.kGray,
                                size: 18,
                              ),
                            )
                          : null,
                    ),
                    if (marketplaceNotifier.isAutocompleteLoading)
                      Positioned(
                        right: 12,
                        child: Container(
                          width: 20,
                          height: 20,
                          padding: const EdgeInsets.all(2),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Kolors.kPrimary,
                          ),
                        ),
                      ),
                  ],
                );
              }
            ),
          )
        ),
      ),

      body: Consumer<MarketplaceNotifier>(
        builder: (context, marketplaceNotifier, child) {
          final bool hasAutocompleteResults = marketplaceNotifier.autocompleteResults.entries
              .any((entry) => entry.value.isNotEmpty);
              
          // Show autocomplete results or loading state when text field has content
          if (_searchController.text.isNotEmpty) {
            if (marketplaceNotifier.isAutocompleteLoading) {
              return _buildLoadingState();
            } else if (hasAutocompleteResults) {
              return _buildAutocompleteResults(marketplaceNotifier);
            } else {
              return _buildNoResultsState();
            }
          }
          
          // Otherwise show recent searches and suggestions
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recent searches section
                if (_recentSearches.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Recent Searches",
                          style: appStyle(14, Kolors.kDark, FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _recentSearches = [];
                            });
                            // This would typically clear from storage as well
                          },
                          child: Text(
                            "Clear",
                            style: appStyle(12, Kolors.kPrimary, FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: _recentSearches.map((search) => GestureDetector(
                      onTap: () => _performSearch(search),
                      child: Chip(
                        backgroundColor: Kolors.kOffWhite,
                        side: const BorderSide(color: Kolors.kGrayLight),
                        label: Text(search),
                        labelStyle: appStyle(12, Kolors.kDark, FontWeight.normal),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _recentSearches.remove(search);
                          });
                          // This would typically update storage as well
                        },
                      ),
                    )).toList(),
                  ),
                  SizedBox(height: 16.h),
                ],
                
                // Popular categories section
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
                  child: Text(
                    "Popular Categories",
                    style: appStyle(14, Kolors.kDark, FontWeight.w600),
                  ),
                ),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: _suggestions.map((suggestion) => GestureDetector(
                    onTap: () => _performSearch(suggestion),
                    child: Chip(
                      backgroundColor: Kolors.kOffWhite,
                      side: const BorderSide(color: Kolors.kGrayLight),
                      label: Text(suggestion),
                      labelStyle: appStyle(12, Kolors.kDark, FontWeight.normal),
                    ),
                  )).toList(),
                ),
              ],
            ),
          );
        }
      ),
    );
  }
  
  // Build loading state while waiting for autocomplete results
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Kolors.kPrimary,
          ),
          SizedBox(height: 16.h),
          Text(
            "Searching...",
            style: appStyle(14, Kolors.kGray, FontWeight.w500),
          ),
        ],
      ),
    );
  }
  
  // Build no results state
  Widget _buildNoResultsState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60.sp,
            color: Kolors.kGray.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            "No results found",
            style: appStyle(16, Kolors.kDark, FontWeight.w500),
          ),
          SizedBox(height: 8.h),
          Text(
            "Try a different search term",
            style: appStyle(14, Kolors.kGray, FontWeight.normal),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          
          // Show popular categories as fallback
          Text(
            "Popular Categories",
            style: appStyle(14, Kolors.kDark, FontWeight.w600),
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            alignment: WrapAlignment.center,
            children: _suggestions.map((suggestion) => GestureDetector(
              onTap: () => _performSearch(suggestion),
              child: Chip(
                backgroundColor: Kolors.kOffWhite,
                side: const BorderSide(color: Kolors.kGrayLight),
                label: Text(suggestion),
                labelStyle: appStyle(12, Kolors.kDark, FontWeight.normal),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }
  
  // Build the autocomplete results list
  Widget _buildAutocompleteResults(MarketplaceNotifier marketplaceNotifier) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: Kolors.kWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.only(top: 8.h),
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        children: marketplaceNotifier.autocompleteResults.entries
          // Filter out empty categories first
          .where((entry) => entry.value.isNotEmpty)
          .expand((entry) {
            String displayName = _getDisplayName(entry.key);
            return [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Text(
                  displayName,
                  style: appStyle(12, Kolors.kGray, FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              ...entry.value.map((value) {
                // Skip empty values
                if (value.isEmpty) return Container();
                
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Set the search controller text first
                      _searchController.text = value;
                      // Then perform the search
                      _performSearch(value);
                    },
                    borderRadius: BorderRadius.circular(4),
                    hoverColor: Kolors.kOffWhite,
                    splashColor: Kolors.kOffWhite,
                    highlightColor: Kolors.kOffWhite.withValues(alpha: 0.5),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w, 
                        vertical: entry.key == 'school_name' ? 16.h : 12.h, // More padding for school names
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(entry.key),
                            size: 18, 
                            color: Kolors.kGray
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              value,
                              style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                              overflow: TextOverflow.ellipsis,
                              maxLines: entry.key == 'school_name' ? 2 : 1, // Allow school names to wrap to 2 lines
                            ),
                          ),
                          // Add search icon to indicate this is searchable
                          Icon(
                            Icons.north_west,
                            size: 14,
                            color: Kolors.kGray.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              // Add spacing after each category except the last one
              if (entry.key != marketplaceNotifier.autocompleteResults.entries
                  .where((e) => e.value.isNotEmpty)
                  .last.key)
                SizedBox(height: 10.h),
            ];
        }).toList(),
      ),
    );
  }
  
  // Get display name for each category
  String _getDisplayName(String key) {
    Map<String, String> keyDisplayNames = {
      'title': 'Item Title',
      'description': 'Description',
      'item_type': 'Item Type',
      'item_subtype': 'Item Subtype',
      'school_name': 'Schools'
    };
    return keyDisplayNames[key] ?? key.toUpperCase();
  }
  
  // Get appropriate icon for each category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'title':
        return Icons.title;
      case 'description':
        return Icons.description;
      case 'item_type':
        return Icons.category;
      case 'item_subtype':
        return Icons.category_outlined;
      case 'school_name':
        return Icons.school;
      default:
        return Icons.search;
    }
  }
} 