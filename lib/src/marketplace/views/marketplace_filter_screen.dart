import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_text.dart' as custom_text;
import 'package:marketplace_app/common/widgets/multi_select_dropdown.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/common/widgets/searchable_multi_select_dropdown.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';
import 'package:provider/provider.dart';

import '../../../common/widgets/custom_dropdown.dart';
import '../../../common/widgets/custom_checkbox.dart';
import '../../../common/widgets/custom_switch.dart';
import '../../../common/widgets/custom_divider.dart';
import '../../../common/widgets/custom_text_field.dart';
import '../../../common/widgets/section_title.dart';

class MarketplaceFilterPage extends StatefulWidget {
  const MarketplaceFilterPage({super.key});

  @override
  State<MarketplaceFilterPage> createState() => _MarketplaceFilterPageState();
}

class _MarketplaceFilterPageState extends State<MarketplaceFilterPage> {
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  List<String> selectedItemTypes = [];
  List<String> selectedItemSubtypes = [];
  List<String> selectedSchoolIds = [];
  
  // Define item type options
  final List<String> itemTypeOptions = ['furniture', 'electronics', 'appliance', 'kitchen', 'decor', 'other'];
  
  // Define item subtype options for each item type
  final Map<String, List<String>> itemSubtypeOptions = {
    'furniture': ['sofa', 'cot', 'mattress', 'table', 'chair', 'wardrobe', 'dresser', 'bookshelf', 'desk', 'other'],
    'electronics': ['tv', 'computer', 'accessories', 'printer', 'monitor', 'speaker', 'gaming_console', 'camera', 'phone', 'other'],
    'appliance': ['refrigerator', 'washing_machine', 'dryer', 'microwave', 'oven', 'toaster', 'coffee_maker', 'blender', 'fan', 'heater', 'other'],
    'kitchen': ['cookware', 'utensils', 'dishes', 'cutlery', 'other'],
    'decor': ['lighting', 'rug', 'curtain', 'mattress', 'art', 'plants', 'other'],
    'other': ['other']
  };

  List<Map<String, String>> schoolOptions = [];
  final ScrollController _schoolScrollController = ScrollController();
  bool _hasMoreSchools = true;
  bool _isLoadingMoreSchools = false;
  int _currentPage = 1;
  String _lastSearchQuery = '';
  final Map<String, Map<String, String>> _selectedSchoolsMap = {};

  // Get available subtypes based on selected item types
  List<String> get availableSubtypes {
    if (selectedItemTypes.isEmpty) return [];
    
    // Get all unique subtypes from selected item types
    Set<String> subtypes = {};
    for (String type in selectedItemTypes) {
      subtypes.addAll(itemSubtypeOptions[type] ?? []);
    }
    return subtypes.toList();
  }

  @override
  void initState() {
    super.initState();
    final marketplaceNotifier = Provider.of<MarketplaceNotifier>(context, listen: false);
    
    // Initialize controllers with current values from notifier
    _minPriceController = TextEditingController(text: marketplaceNotifier.minPrice.toInt().toString());
    _maxPriceController = TextEditingController(text: marketplaceNotifier.maxPrice.toInt().toString());
    
    // Initialize selected values from notifier
    selectedItemTypes = List.from(marketplaceNotifier.selectedItemTypes);
    selectedItemSubtypes = List.from(marketplaceNotifier.selectedItemSubtypes);
    selectedSchoolIds = List.from(marketplaceNotifier.selectedSchoolIds);
    
    _fetchSchools().then((_) {
      // After fetching schools, populate selected schools map
      if (selectedSchoolIds.isNotEmpty) {
        for (var id in selectedSchoolIds) {
          var school = schoolOptions.firstWhere(
            (s) => s['id'] == id, 
            orElse: () => {'id': id, 'name': 'School $id'}
          );
          _selectedSchoolsMap[id] = school;
        }
        // Force a rebuild to update the school dropdown
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _schoolScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchools() async {
    if (!_hasMoreSchools || _isLoadingMoreSchools) return;

    setState(() {
      _isLoadingMoreSchools = true;
    });

    String url = "${Environment.iosAppBaseUrl}/api/school/lite/?page=$_currentPage";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final bool hasNext = data['next'] != null;

        setState(() {
          if (_currentPage == 1) {
            schoolOptions = results.map<Map<String, String>>((school) => {
              'id': school['id'].toString(),
              'name': school['name'].toString()
            }).toList();
          } else {
            schoolOptions.addAll(results.map<Map<String, String>>((school) => {
              'id': school['id'].toString(),
              'name': school['name'].toString()
            }));
          }
          _hasMoreSchools = hasNext;
          if (hasNext) _currentPage++;
          _isLoadingMoreSchools = false;
        });
      } else {
        setState(() {
          _isLoadingMoreSchools = false;
        });
        throw Exception("Failed to load schools");
      }
    } catch (e) {
      setState(() {
        _isLoadingMoreSchools = false;
      });
      print("Error fetching schools: $e");
    }
  }

  Future<void> _searchSchools(String query) async {
    if (_lastSearchQuery != query) {
      setState(() {
        _currentPage = 1;
        _hasMoreSchools = true;
        _lastSearchQuery = query;
      });
    }

    if (!_hasMoreSchools || _isLoadingMoreSchools) return;

    setState(() {
      _isLoadingMoreSchools = true;
    });

    if (query.isEmpty && _currentPage == 1) {
      await _fetchSchools();
      return;
    }

    String url = "${Environment.iosAppBaseUrl}/api/school/lite/?name=$query&page=$_currentPage";
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final bool hasNext = data['next'] != null;

        setState(() {
          if (_currentPage == 1) {
            List<Map<String, String>> newOptions = results.map<Map<String, String>>((school) => {
              'id': school['id'].toString(),
              'name': school['name'].toString()
            }).toList();

            for (String id in selectedSchoolIds) {
              if (!newOptions.any((school) => school['id'] == id) && _selectedSchoolsMap.containsKey(id)) {
                newOptions.add(_selectedSchoolsMap[id]!);
              }
            }
            schoolOptions = newOptions;
          } else {
            List<Map<String, String>> newSchools = results.map<Map<String, String>>((school) => {
              'id': school['id'].toString(),
              'name': school['name'].toString()
            }).where((school) => !schoolOptions.any((existing) => existing['id'] == school['id'])).toList();
            schoolOptions.addAll(newSchools);
          }
          _hasMoreSchools = hasNext;
          if (hasNext) _currentPage++;
          _isLoadingMoreSchools = false;
        });
      } else {
        setState(() {
          _isLoadingMoreSchools = false;
        });
        throw Exception("Failed to search schools");
      }
    } catch (e) {
      setState(() {
        _isLoadingMoreSchools = false;
      });
      print("Error searching schools: $e");
    }
  }

  void _applyFilters(MarketplaceNotifier marketplaceNotifier) {
    final double? minPrice = double.tryParse(_minPriceController.text);
    final double? maxPrice = double.tryParse(_maxPriceController.text);
    if (minPrice == null || maxPrice == null || minPrice > maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid price values"), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Set all filter parameters
    marketplaceNotifier.setPriceRange(minPrice, maxPrice);
    marketplaceNotifier.setSelectedItemTypes(selectedItemTypes);
    marketplaceNotifier.setSelectedItemSubtypes(selectedItemSubtypes);
    marketplaceNotifier.setSelectedSchoolIds(selectedSchoolIds);
    
    // Apply filters and navigate back with filtered items
    setState(() {
      // Show loading indicator
      _isFiltering = true;
    });
    
    marketplaceNotifier.applyFilters(context).then((_) {
      setState(() {
        _isFiltering = false;
      });
      
      // Pop back to the previous screen with filtered items
      Navigator.pop(context, marketplaceNotifier.marketplaceItems);
    });
  }

  // Add a state variable to track loading state
  bool _isFiltering = false;

  void _resetFilters(MarketplaceNotifier marketplaceNotifier) {
    setState(() {
      selectedItemTypes = [];
      selectedItemSubtypes = [];
      selectedSchoolIds = [];
      _selectedSchoolsMap.clear();
      _minPriceController.text = '0';
      _maxPriceController.text = '10000';
    });
    marketplaceNotifier.resetFilters();
  }

  @override
  Widget build(BuildContext context) {
    final marketplaceNotifier = Provider.of<MarketplaceNotifier>(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onTap: () => context.pop()),
        title: ReusableText(
          text: "Filter Marketplace",
          style: appStyle(15, Kolors.kPrimary, FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price Range Section
                  const SectionTitle(
                    title: "Price Range",
                  ),
                  RangeSlider(
                    values: RangeValues(
                      double.tryParse(_minPriceController.text) ?? 0,
                      double.tryParse(_maxPriceController.text) ?? 10000,
                    ),
                    min: 0,
                    max: 10000,
                    activeColor: Kolors.kPrimary,
                    onChanged: (values) {
                      setState(() {
                        _minPriceController.text = values.start.toInt().toString();
                        _maxPriceController.text = values.end.toInt().toString();
                      });
                    },
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _minPriceController,
                          labelText: "Min Price",
                          maxLines: 1,
                          hintText: "Min Price",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(CupertinoIcons.money_dollar, size: 20, color: Kolors.kGray),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _maxPriceController,
                          labelText: "Max Price",
                          maxLines: 1,
                          hintText: "Max Price",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(CupertinoIcons.money_dollar, size: 20, color: Kolors.kGray),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Item Type Section
                  const SectionTitle(
                    title: "Item Type",
                  ),
                  SizedBox(height: 8.h),
                  MultiSelectDropdown(
                    title: "Item Types",
                    options: itemTypeOptions,
                    selectedValues: selectedItemTypes,
                    hintText: "Select Item Types",
                    onSelectionChanged: (List<String> newSelection) {
                      setState(() {
                        selectedItemTypes = newSelection;
                        // Clear selected subtypes that are not available for the new selection
                        selectedItemSubtypes = selectedItemSubtypes
                            .where((subtype) => availableSubtypes.contains(subtype))
                            .toList();
                      });
                    },
                  ),

                  if (selectedItemTypes.isNotEmpty) ...[
                    SizedBox(height: 16.h),

                    // Item Subtype Section
                    const SectionTitle(
                      title: "Item Subtype",
                    ),
                    SizedBox(height: 8.h),
                    MultiSelectDropdown(
                      title: "Item Subtypes",
                      options: availableSubtypes,
                      selectedValues: selectedItemSubtypes,
                      hintText: "Select Item Subtypes",
                      onSelectionChanged: (List<String> newSelection) {
                        setState(() {
                          selectedItemSubtypes = newSelection;
                        });
                      },
                    ),
                  ],

                  SizedBox(height: 16.h),

                  // Condition Section
                  CustomDropdown<String>(
                    value: marketplaceNotifier.condition ?? '',
                    items: const [
                      DropdownMenuItem(value: '', child: Text("Select Condition")),
                      DropdownMenuItem(value: 'new', child: Text("New")),
                      DropdownMenuItem(value: 'like_new', child: Text("Like New")),
                      DropdownMenuItem(value: 'good', child: Text("Good")),
                      DropdownMenuItem(value: 'fair', child: Text("Fair")),
                      DropdownMenuItem(value: 'poor', child: Text("Poor")),
                    ],
                    onChanged: (value) {
                      marketplaceNotifier.setCondition(value);
                    },
                    labelText: "Condition",
                  ),

                  SizedBox(height: 16.h),

                  // Nearby Schools Section
                  const SectionTitle(
                    title: "Nearby Schools",
                  ),
                  SizedBox(height: 8.h),
                  SearchableMultiSelectDropdown(
                    title: "Schools",
                    options: schoolOptions.map((school) => school['name']!).toList(),
                    selectedValues: selectedSchoolIds.map((id) =>
                      schoolOptions.firstWhere((school) => school['id'] == id, orElse: () => _selectedSchoolsMap[id] ?? {'name': '', 'id': id})['name']!
                    ).toList(),
                    hintText: "Select Nearby Schools",
                    onSelectionChanged: (List<String> selectedNames) {
                      setState(() {
                        selectedSchoolIds = selectedNames.map((name) {
                          var school = schoolOptions.firstWhere((s) => s['name'] == name);
                          _selectedSchoolsMap[school['id']!] = school;
                          return school['id']!;
                        }).toList();
                      });
                    },
                    onSearch: _searchSchools,
                    scrollController: _schoolScrollController,
                    isLoading: _isLoadingMoreSchools,
                  ),
                  SizedBox(height: 8.h),
                  CustomSwitch(
                    label: "Negotiable",
                    value: marketplaceNotifier.negotiable ?? false,
                    onChanged: (value) {
                      marketplaceNotifier.setNegotiable(value);
                    },
                  ),
                  SizedBox(height: 8.h),
                  CustomSwitch(
                    label: "Delivery Available",
                    value: marketplaceNotifier.deliveryAvailable ?? false,
                    onChanged: (value) {
                      marketplaceNotifier.setDeliveryAvailable(value);
                    },
                  ),
                  SizedBox(height: 8.h),
                  CustomSwitch(
                    label: "Original Receipt Available",
                    value: marketplaceNotifier.originalReceiptAvailable ?? false,
                    onChanged: (value) {
                      marketplaceNotifier.setOriginalReceiptAvailable(value);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Fixed Buttons at the Bottom
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => _resetFilters(marketplaceNotifier),
                      style: TextButton.styleFrom(backgroundColor: Colors.grey[200]),
                      child: const Text("Reset Filters", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isFiltering ? null : () => _applyFilters(marketplaceNotifier),
                      child: _isFiltering
                          ? const CircularProgressIndicator()
                          : const Text("Apply Filter"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 