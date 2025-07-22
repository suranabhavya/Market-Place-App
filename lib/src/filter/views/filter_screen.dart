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
import 'package:marketplace_app/common/widgets/multi_select_dropdown.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/common/widgets/searchable_multi_select_dropdown.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:provider/provider.dart';
import 'package:get_storage/get_storage.dart';

import '../../../common/widgets/custom_dropdown.dart';
import '../../../common/widgets/custom_divider.dart';
import '../../../common/widgets/custom_text_field.dart';
import '../../../common/widgets/amenity_chip.dart';
import '../../../common/widgets/section_title.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({super.key});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late TextEditingController _minRentController;
  late TextEditingController _maxRentController;
  List<String> selectedBedrooms = [];
  List<String> selectedBathrooms = [];
  List<String> selectedSchoolIds = [];
  List<String> selectedPropertyTypes = [];
  final List<String> bedroomOptions = ['1', '2', '3', '4', '5+'];
  final List<String> bathroomOptions = ['1', '2', '3', '4+'];
  List<Map<String, String>> schoolOptions = [];
  final ScrollController _schoolScrollController = ScrollController();
  bool _hasMoreSchools = true;
  bool _isLoadingMoreSchools = false;
  int _currentPage = 1;
  String _lastSearchQuery = '';
  final Map<String, Map<String, String>> _selectedSchoolsMap = {};

  @override
  void initState() {
    super.initState();
    final filterNotifier = Provider.of<FilterNotifier>(context, listen: false);
    _minRentController = TextEditingController(text: filterNotifier.priceRange.start.toInt().toString());
    _maxRentController = TextEditingController(text: filterNotifier.priceRange.end.toInt().toString());
    
    // Initialize selected values from notifier state
    selectedBedrooms = List.from(filterNotifier.selectedBedrooms);
    selectedBathrooms = List.from(filterNotifier.selectedBathrooms);
    selectedSchoolIds = List.from(filterNotifier.selectedSchools);
    selectedPropertyTypes = List.from(filterNotifier.selectedPropertyTypes);
    
    // Load previously selected schools from local storage
    _loadSelectedSchoolsFromStorage();
    
    _fetchSchools().then((_) {
      // Force a rebuild to update the school dropdown with all data
      if (mounted) setState(() {});
    });
    
    _fetchAmenities();
  }

  void _loadSelectedSchoolsFromStorage() {
    final box = GetStorage();
    final storedSchools = box.read('selected_schools');
    
    if (storedSchools != null) {
      Map<String, dynamic> schoolsMap = Map<String, dynamic>.from(storedSchools);
      
      for (String schoolId in selectedSchoolIds) {
        if (schoolsMap.containsKey(schoolId)) {
          _selectedSchoolsMap[schoolId] = Map<String, String>.from(schoolsMap[schoolId]);
        }
      }
    }
  }

  void _saveSelectedSchoolsToStorage() {
    final box = GetStorage();
    Map<String, Map<String, String>> currentStored = {};
    
    // Load existing stored schools
    final storedSchools = box.read('selected_schools');
    if (storedSchools != null) {
      Map<String, dynamic> schoolsMap = Map<String, dynamic>.from(storedSchools);
      for (var entry in schoolsMap.entries) {
        currentStored[entry.key] = Map<String, String>.from(entry.value);
      }
    }
    
    // Add new selected schools
    currentStored.addAll(_selectedSchoolsMap);
    
    // Save back to storage
    box.write('selected_schools', currentStored);
  }

  @override
  void dispose() {
    _minRentController.dispose();
    _maxRentController.dispose();
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
            
            // Add selected schools from local storage that aren't in the first page results
            for (String id in selectedSchoolIds) {
              if (!schoolOptions.any((school) => school['id'] == id) && _selectedSchoolsMap.containsKey(id)) {
                schoolOptions.add(_selectedSchoolsMap[id]!);
              } else if (schoolOptions.any((school) => school['id'] == id)) {
                // Update the selected schools map with the fetched data
                var school = schoolOptions.firstWhere((s) => s['id'] == id);
                _selectedSchoolsMap[id] = school;
              }
            }
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
      debugPrint("Error fetching schools: $e");
    }
  }

  Future<void> _searchSchools(String query) async {
    // Reset pagination when a new search is initiated
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
            // Create a new list with both API results and selected schools
            List<Map<String, String>> newOptions = results.map<Map<String, String>>((school) => {
              'id': school['id'].toString(),
              'name': school['name'].toString()
            }).toList();

            // Add selected schools that aren't in the search results
            for (String id in selectedSchoolIds) {
              if (!newOptions.any((school) => school['id'] == id) && _selectedSchoolsMap.containsKey(id)) {
                newOptions.add(_selectedSchoolsMap[id]!);
              }
            }
            schoolOptions = newOptions;
          } else {
            // For pagination, only add new schools from API that aren't already in the list
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
      debugPrint("Error searching schools: $e");
    }
  }

  Future<void> _fetchAmenities() async {
    String url = '${Environment.iosAppBaseUrl}/api/amenities/';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(responseBody);

        if (mounted) {
          final filterNotifier = Provider.of<FilterNotifier>(context, listen: false);
          
          // Preserve existing selections when updating amenities
          Map<String, bool> currentAmenities = Map.from(filterNotifier.amenities);
          
          // Initialize amenities with preserved selections
          filterNotifier.amenities = {
            for (var item in data) 
              item["name"]: currentAmenities[item["name"]] ?? false
          };
        }
      } else {
        throw Exception("Failed to load amenities");
      }
    } catch (e) {
      debugPrint("Error fetching amenities: $e");
    }
  }

  void _applyFilters(FilterNotifier filterNotifier) {
    final double? minRent = double.tryParse(_minRentController.text);
    final double? maxRent = double.tryParse(_maxRentController.text);
    if (minRent == null || maxRent == null || minRent > maxRent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter valid rent values"), backgroundColor: Colors.red),
      );
      return;
    }
    filterNotifier.setPriceRange(RangeValues(minRent, maxRent));
    filterNotifier.applyFilters();
  }

  void _resetFilters(FilterNotifier filterNotifier) {
    setState(() {
      selectedBedrooms = [];
      selectedBathrooms = [];
      selectedSchoolIds = [];
      selectedPropertyTypes = [];
      _selectedSchoolsMap.clear();
      filterNotifier.resetFilters();
      _minRentController.text = filterNotifier.priceRange.start.toInt().toString();
      _maxRentController.text = filterNotifier.priceRange.end.toInt().toString();
    });
  }

  void _updateRangeSlider(String value, bool isMin) {
    final filterNotifier = Provider.of<FilterNotifier>(context, listen: false);
    final double? numericValue = double.tryParse(value);
    
    if (numericValue == null) return;

    // Clamp the value to the valid range (0-50000)
    final clampedValue = numericValue.clamp(0.0, 50000.0);

    if (isMin) {
      if (clampedValue <= filterNotifier.priceRange.end) {
        filterNotifier.setPriceRange(RangeValues(clampedValue, filterNotifier.priceRange.end));
      }
    } else {
      if (clampedValue >= filterNotifier.priceRange.start) {
        filterNotifier.setPriceRange(RangeValues(filterNotifier.priceRange.start, clampedValue));
      }
    }
  }

  void _handleTextChange(String value, bool isMin) {
    final double? numericValue = double.tryParse(value);
    if (numericValue == null) return;

    final filterNotifier = Provider.of<FilterNotifier>(context, listen: false);
    
    if (isMin) {
      if (numericValue <= filterNotifier.priceRange.end) {
        _updateRangeSlider(value, true);
      }
    } else {
      if (numericValue >= filterNotifier.priceRange.start) {
        _updateRangeSlider(value, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filterNotifier = Provider.of<FilterNotifier>(context);
    
    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onTap: () => context.pop()),
        title: ReusableText(
          text: AppText.kFilter,
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
                  // Rent Range Section
                  const SectionTitle(
                    title: "Rent Range",
                  ),
                  RangeSlider(
                    values: RangeValues(
                      filterNotifier.priceRange.start.clamp(0.0, 50000.0),
                      filterNotifier.priceRange.end.clamp(0.0, 50000.0),
                    ),
                    min: 0,
                    max: 50000,
                    activeColor: Kolors.kPrimary,
                    onChanged: (values) {
                      filterNotifier.setPriceRange(values);
                      _minRentController.text = values.start.toInt().toString();
                      _maxRentController.text = values.end.toInt().toString();
                    },
                  ),
                  SizedBox(height: 16.h),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _minRentController,
                          labelText: "Min Rent",
                          maxLines: 1,
                          hintText: "Min Rent",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(CupertinoIcons.money_dollar, size: 20, color: Kolors.kGray),
                          onChanged: (value) => _handleTextChange(value, true),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: CustomTextField(
                          controller: _maxRentController,
                          labelText: "Max Rent",
                          maxLines: 1,
                          hintText: "Max Rent",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(CupertinoIcons.money_dollar, size: 20, color: Kolors.kGray),
                          onChanged: (value) => _handleTextChange(value, false),
                        ),
                      ),
                    ],
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
                        filterNotifier.setSchools(selectedSchoolIds);
                        
                        // Save selected schools to local storage
                        _saveSelectedSchoolsToStorage();
                      });
                    },
                    onSearch: _searchSchools,
                    scrollController: _schoolScrollController,
                    isLoading: _isLoadingMoreSchools,
                  ),

                  SizedBox(height: 16.h),

                  // Bedrooms and Bathrooms Section
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle(
                              title: "Bedrooms",
                            ),
                            SizedBox(height: 8.h),
                            MultiSelectDropdown(
                              title: "Bedrooms",
                              options: bedroomOptions,
                              selectedValues: selectedBedrooms,
                              hintText: "Select Bedrooms",
                              onSelectionChanged: (List<String> newSelection) {
                                setState(() {
                                  selectedBedrooms = newSelection;
                                  filterNotifier.setBedrooms(selectedBedrooms);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle(
                              title: "Bathrooms",
                            ),
                            SizedBox(height: 8.h),
                            MultiSelectDropdown(
                              title: "Bathrooms",
                              options: bathroomOptions,
                              selectedValues: selectedBathrooms,
                              hintText: "Select Bathrooms",
                              onSelectionChanged: (List<String> newSelection) {
                                setState(() {
                                  selectedBathrooms = newSelection;
                                  filterNotifier.setBathrooms(selectedBathrooms);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16.h),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: "Property Type",
                      ),
                      SizedBox(height: 8.h),
                      MultiSelectDropdown(
                        title: "Property Type",
                        options: const ['Private Room', 'Shared Room', 'Apartment'],
                        selectedValues: selectedPropertyTypes.map((type) {
                          switch (type) {
                            case 'private_room': return 'Private Room';
                            case 'shared_room': return 'Shared Room';
                            case 'apartment': return 'Apartment';
                            default: return type;
                          }
                        }).toList(),
                        hintText: "Select Property Types",
                        onSelectionChanged: (List<String> newSelection) {
                          setState(() {
                            selectedPropertyTypes = newSelection.map((displayName) {
                              switch (displayName) {
                                case 'Private Room': return 'private_room';
                                case 'Shared Room': return 'shared_room';
                                case 'Apartment': return 'apartment';
                                default: return displayName;
                              }
                            }).toList();
                            filterNotifier.setPropertyTypes(selectedPropertyTypes);
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Flatmate Preferences (only show for Private Room or Shared Room)
                  if (selectedPropertyTypes.contains('private_room') || selectedPropertyTypes.contains('shared_room')) ...[
                    CustomDivider(
                      height: 1,
                      thickness: 0.5.h,
                      color: Kolors.kGrayLight,
                    ),

                    SizedBox(height: 16.h),
                    
                    const SectionTitle(
                      title: "Flatmate Preferences",
                    ),

                    const SizedBox(height: 16),
                    CustomDropdown<String>(
                      value: filterNotifier.smokingPreference,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Doesn't Matter",
                                style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                              ),
                              SizedBox(width: 8.w),
                              const Icon(Icons.smoking_rooms, color: Colors.black, size: 16)
                            ],
                          )
                        ),
                        const DropdownMenuItem(value: 'never', child: Text("Never")),
                        const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                        const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                        const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                      ],
                      onChanged: (value) {
                        filterNotifier.setSmokingPreference(value ?? '');
                      },
                      labelText: "Smoking",
                    ),
                    const SizedBox(height: 16),
                    CustomDropdown<String>(
                      value: filterNotifier.partyingPreference,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Doesn't Matter",
                                style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                              ),
                              SizedBox(width: 8.w),
                              const Icon(Icons.wine_bar, color: Colors.black, size: 16)
                            ],
                          )
                        ),
                        const DropdownMenuItem(value: 'never', child: Text("Never")),
                        const DropdownMenuItem(value: 'rarely', child: Text("Rarely")),
                        const DropdownMenuItem(value: 'occasionally', child: Text("Occasionally")),
                        const DropdownMenuItem(value: 'regularly', child: Text("Regularly")),
                      ],
                      onChanged: (value) {
                        filterNotifier.setPartyingPreference(value ?? '');
                      },
                      labelText: "Partying",
                    ),
                    const SizedBox(height: 16),
                    CustomDropdown<String>(
                      value: filterNotifier.dietaryPreference,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Doesn't Matter",
                                style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                              ),
                              SizedBox(width: 8.w),
                              const Icon(Icons.lunch_dining, color: Colors.black, size: 16)
                            ],
                          )
                        ),
                        const DropdownMenuItem(value: 'veg', child: Text("Vegetarian")),
                        const DropdownMenuItem(value: 'non_veg', child: Text("Non Vegetarian")),
                        const DropdownMenuItem(value: 'vegan', child: Text("Vegan")),
                      ],
                      onChanged: (value) {
                        filterNotifier.setDietaryPreference(value ?? '');
                      },
                      labelText: "Dietary",
                    ),
                    const SizedBox(height: 16),
                    CustomDropdown<String>(
                      value: filterNotifier.nationalityPreference,
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                "Doesn't Matter",
                                style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                              ),
                              SizedBox(width: 8.w),
                              const Icon(Icons.groups_3_sharp, color: Colors.black, size: 16)
                            ],
                          )
                        ),
                        const DropdownMenuItem(value: 'indian', child: Text("Indian")),
                        const DropdownMenuItem(value: 'korean', child: Text("Korean")),
                        const DropdownMenuItem(value: 'chinese', child: Text("Chinese")),
                        const DropdownMenuItem(value: 'american', child: Text("American")),
                        const DropdownMenuItem(value: 'others', child: Text("Others")),
                        const DropdownMenuItem(value: 'mixed', child: Text("Mixed")),
                      ],
                      onChanged: (value) {
                        filterNotifier.setNationalityPreference(value ?? '');
                      },
                      labelText: "Nationality",
                    ),
                    const SizedBox(height: 16),
                  ],

                  CustomDivider(
                    height: 1,
                    thickness: 0.5.h,
                    color: Kolors.kGrayLight,
                  ),

                  SizedBox(height: 16.h),

                  // Must Haves (Amenities)
                  const SectionTitle(
                    title: "Must Haves",
                  ),
                  const SizedBox(height: 16),
                  filterNotifier.amenities.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: filterNotifier.amenities.keys.map((String key) {
                          bool isSelected = filterNotifier.amenities[key]!;
                          return AmenityChip(
                            label: key,
                            isSelected: isSelected,
                            onTap: () {
                              filterNotifier.toggleAmenity(key);
                            },
                          );
                        }).toList(),
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
                      onPressed: () => _resetFilters(filterNotifier),
                      style: TextButton.styleFrom(backgroundColor: Colors.grey[200]),
                      child: const Text("Reset Filters", style: TextStyle(color: Colors.black)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _applyFilters(filterNotifier),
                      child: filterNotifier.isLoading
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