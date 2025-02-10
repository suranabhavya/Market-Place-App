import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_text.dart';
import 'package:marketplace_app/common/widgets/multi_select_dropdown.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/common/widgets/searchable_multi_select_dropdown.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:provider/provider.dart';

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
  List<String> selectedSchools = [];
  final List<String> bedroomOptions = ['1', '2', '3', '4', '5+'];
  final List<String> bathroomOptions = ['1', '2', '3', '4+'];
  List<String> schoolOptions = [];

  @override
  void initState() {
    super.initState();
    final filterNotifier = Provider.of<FilterNotifier>(context, listen: false);
    _minRentController = TextEditingController(text: filterNotifier.priceRange.start.toInt().toString());
    _maxRentController = TextEditingController(text: filterNotifier.priceRange.end.toInt().toString());
    _fetchSchools();
  }

  @override
  void dispose() {
    _minRentController.dispose();
    _maxRentController.dispose();
    super.dispose();
  }

  Future<void> _fetchSchools() async {
    try {
      final response = await http.get(Uri.parse("${Environment.iosAppBaseUrl}/api/school/lite/"));
      if (response.statusCode == 200) {
        setState(() {
          schoolOptions = (json.decode(response.body) as List).map((school) => school.toString()).toList();
        });
      } else {
        throw Exception("Failed to load schools");
      }
    } catch (e) {
      print("Error fetching schools: $e");
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
    filterNotifier.applyFilters(context);
  }

  void _resetFilters(FilterNotifier filterNotifier) {
    setState(() {
      selectedBedrooms = [];
      selectedBathrooms = [];
      selectedSchools = [];
      filterNotifier.resetFilters();
      _minRentController.text = filterNotifier.priceRange.start.toInt().toString();
      _maxRentController.text = filterNotifier.priceRange.end.toInt().toString();
    });
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
          // Scrollable Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rent Range
                  Text("Rent Range", style: appStyle(14, Kolors.kPrimary, FontWeight.bold)),
                  RangeSlider(
                    values: filterNotifier.priceRange,
                    min: 0,
                    max: 50000,
                    activeColor: Kolors.kPrimary,
                    onChanged: (values) {
                      filterNotifier.setPriceRange(values);
                      _minRentController.text = values.start.toInt().toString();
                      _maxRentController.text = values.end.toInt().toString();
                    },
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: CustomTextField(
                          controller: _minRentController,
                          maxLines: 1,
                          hintText: "Min Rent",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(CupertinoIcons.money_dollar, size: 20, color: Kolors.kGray),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: CustomTextField(
                          controller: _maxRentController,
                          maxLines: 1,
                          hintText: "Max Rent",
                          keyboardType: TextInputType.number,
                          prefixIcon: const Icon(CupertinoIcons.money_dollar, size: 20, color: Kolors.kGray),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 30),

                  // Nearby Schools
                  Text("Nearby Schools", style: appStyle(14, Kolors.kPrimary, FontWeight.bold)),
                  const SizedBox(height: 8),
                  SearchableMultiSelectDropdown(
                    title: "Schools",
                    options: schoolOptions,
                    selectedValues: selectedSchools,
                    hintText: "Select Nearby Schools",
                    onSelectionChanged: (List<String> newSelection) {
                      setState(() {
                        selectedSchools = newSelection;
                        filterNotifier.setSchools(selectedSchools);
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 30),

                  // Bedrooms and Bathrooms
                  Row(
                    children: [
                      Flexible(
                        child: MultiSelectDropdown(
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
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: MultiSelectDropdown(
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
                      ),
                    ],
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
                      child: const Text("Reset All", style: TextStyle(color: Colors.black)),
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