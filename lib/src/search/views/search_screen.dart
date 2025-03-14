import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
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
  
  // Perform the search when user selects an autocomplete suggestion or presses search
  void _performSearch(String query) async {
    // Update the search key in FilterNotifier instead of SearchNotifier
    final filterNotifier = context.read<FilterNotifier>();
    filterNotifier.setSearchKey(query);
    
    // Use FilterNotifier to apply filters (which now includes search)
    filterNotifier.applyFilters(context);
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
    
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(
          onTap: () {
            // Clear search results when going back
            context.read<SearchNotifier>().clearResults();
            context.pop();
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
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              children: [
                // Autocomplete results section
                if (searchNotifier.autocompleteResults.isNotEmpty)
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      children: searchNotifier.autocompleteResults.entries.expand((entry) {
                        String displayName = _getDisplayName(entry.key);
                        return [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            child: ReusableText(
                              text: displayName,
                              style: appStyle(12, Kolors.kGray, FontWeight.w600),
                            ),
                          ),
                          const Divider(height: 1),
                          ...entry.value.map((value) => InkWell(
                            onTap: () {
                              _searchController.text = value;
                              _performSearch(value);
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                              child: Row(
                                children: [
                                  Icon(
                                    _getCategoryIcon(entry.key),
                                    size: 18, 
                                    color: Kolors.kGray
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: ReusableText(
                                      text: value,
                                      style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )).toList(),
                          if (entry.key != searchNotifier.autocompleteResults.keys.last)
                            SizedBox(height: 10.h),
                        ];
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        }
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