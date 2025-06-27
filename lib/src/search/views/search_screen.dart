import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/empty_screen_widget.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/entrypoint/views/entrypoint.dart';
import 'package:marketplace_app/src/properties/widgets/staggered_tile_widget.dart';
import 'package:marketplace_app/src/search/controllers/search_notifier.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/properties/widgets/explore_properties.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  bool _isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize the search controller with any existing search query
    final filterNotifier = context.read<FilterNotifier>();
    if (filterNotifier.searchKey.isNotEmpty) {
      _searchController.text = filterNotifier.searchKey;
    }
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
    
    // Set focus to the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  
  // This function is called whenever the text field's value changes
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Debounce to avoid too many API calls
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_searchController.text.isNotEmpty) {
        context.read<SearchNotifier>().fetchAutocomplete(_searchController.text);
      } else {
        context.read<SearchNotifier>().clearAutocompleteResults();
      }
    });
  }
  
  // Get nearby properties using device location
  Future<void> _getNearbyProperties() async {
    setState(() {
      _isLocationLoading = true;
    });
    
    try {
      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || 
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Location permission is required to find nearby properties"),
            backgroundColor: Kolors.kRed,
          ),
        );
        setState(() {
          _isLocationLoading = false;
        });
        return;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Update filter notifier with location
      final filterNotifier = context.read<FilterNotifier>();
      
      // Clear search text and set "Near Me" as the search key
      _searchController.text = "Properties Near Me";
      filterNotifier.setSearchKey("Properties Near Me");
      
      // Set location in filter notifier
      filterNotifier.setLocation(position.latitude, position.longitude);
      
      // Apply filters with the new location
      await filterNotifier.applyFilters(context);
      
      // Navigate back to home
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to get location: $e"),
          backgroundColor: Kolors.kRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
    }
  }
  
  // Perform the search when user selects an autocomplete suggestion or presses search
  void _performSearch(String query) async {
    if (query.isEmpty) return;
    
    // Update the search key in FilterNotifier
    final filterNotifier = context.read<FilterNotifier>();
    filterNotifier.setSearchKey(query);
    
    // Reset location if we're not doing a location-based search
    if (query != "Properties Near Me") {
      filterNotifier.resetLocation();
    }
    
    // Use FilterNotifier to apply filters
    await filterNotifier.applyFilters(context);
    
    // Go back to home screen
    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          onTap: () {
            // Clear search results and reset filters when going back
            context.read<SearchNotifier>().clearResults();
            
            // Clear the search controller text
            _searchController.clear();
            
            // Reset the search key and filters in FilterNotifier
            final filterNotifier = context.read<FilterNotifier>();
            filterNotifier.setSearchKey(''); // Clear search keyword
            filterNotifier.resetLocation(); // Clear location if set
            
            // Apply filters (which will show all properties since search key is empty)
            filterNotifier.applyFilters(context).then((_) {
              if (mounted) {
                context.pop();
              }
            });
          },
        ),
        title: ReusableText(
          text: AppText.kSearch,
          style: appStyle(15, Kolors.kPrimary, FontWeight.bold)
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Consumer<SearchNotifier>(
              builder: (context, searchNotifier, _) {
                return Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    EmailTextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      radius: 30,
                      hintText: AppText.kSearchHint,
                      textInputAction: TextInputAction.search,
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
                                context.read<SearchNotifier>().clearAutocompleteResults();
                                
                                // Clear the search key in FilterNotifier but don't apply filters yet
                                // The user stays on the search screen
                                final filterNotifier = context.read<FilterNotifier>();
                                filterNotifier.setSearchKey(''); // Clear search keyword
                                filterNotifier.resetLocation(); // Clear location if set
                              },
                              child: const Icon(
                                Icons.close,
                                color: Kolors.kGray,
                                size: 18,
                              ),
                            )
                          : null,
                    ),
                    if (searchNotifier.isAutocompleteLoading)
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

      body: Consumer<SearchNotifier>(
        builder: (context, searchNotifier, child) {
          final bool hasAutocompleteResults = searchNotifier.autocompleteResults.entries
              .any((entry) => entry.value.isNotEmpty);
              
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              children: [
                // "Near Me" option
                InkWell(
                  onTap: _isLocationLoading ? null : _getNearbyProperties,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Kolors.kOffWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Kolors.kGray.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        _isLocationLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Kolors.kPrimary,
                                ),
                              )
                            : const Icon(
                                Icons.location_on,
                                color: Kolors.kPrimary,
                                size: 24,
                              ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            "Find properties near me",
                            style: appStyle(14, Kolors.kPrimary, FontWeight.w500),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Kolors.kPrimary,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Search suggestions or "No results" message
                if (_searchController.text.isNotEmpty)
                  Expanded(
                    child: hasAutocompleteResults 
                      ? _buildAutocompleteResults(searchNotifier)
                      : searchNotifier.isAutocompleteLoading 
                          ? Container() // Don't show anything while loading
                          : _buildNoResultsMessage(),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
  
  // Build the autocomplete results list
  Widget _buildAutocompleteResults(SearchNotifier searchNotifier) {
    return Container(
      decoration: BoxDecoration(
        color: Kolors.kWhite,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: EdgeInsets.only(bottom: 16.h),
      child: ListView(
        padding: EdgeInsets.only(top: 8.h),
        physics: const BouncingScrollPhysics(),
        children: searchNotifier.autocompleteResults.entries
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
                      _searchController.text = value;
                      _performSearch(value);
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w, 
                        vertical: entry.key == 'school_name' ? 14.h : 12.h, // More padding for school names
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
                          // Add arrow icon to indicate this is selectable
                          Icon(
                            Icons.north_west,
                            size: 14,
                            color: Kolors.kGray.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
              // Add spacing after each category except the last one
              if (entry.key != searchNotifier.autocompleteResults.entries
                  .where((e) => e.value.isNotEmpty)
                  .last.key)
                SizedBox(height: 10.h),
            ];
        }).toList(),
      ),
    );
  }
  
  // Build the no results message
  Widget _buildNoResultsMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 60.sp,
            color: Kolors.kGray.withOpacity(0.5),
          ),
          SizedBox(height: 16.h),
          Text(
            "No results found",
            style: appStyle(16, Kolors.kDark, FontWeight.w500),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              "Try a different search term or use the location search option",
              style: appStyle(14, Kolors.kGray, FontWeight.normal),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  // Get display name for each category
  String _getDisplayName(String key) {
    Map<String, String> keyDisplayNames = {
      'title': 'Property Title',
      'address': 'Address',
      'pincode': 'Zip Code',
      'school_name': 'Nearby Schools'
    };
    return keyDisplayNames[key] ?? key.toUpperCase();
  }
  
  // Get appropriate icon for each category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'title':
        return Icons.home;
      case 'address':
        return Icons.location_on;
      case 'pincode':
        return Icons.pin;
      case 'school_name':
        return Icons.school;
      default:
        return Icons.location_on;
    }
  }
}