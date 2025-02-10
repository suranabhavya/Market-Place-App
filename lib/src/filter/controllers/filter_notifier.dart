import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';

class FilterNotifier extends ChangeNotifier {
  RangeValues priceRange = const RangeValues(0, 50000);
  List<String> selectedBedrooms = [];
  List<String> selectedBathrooms = [];
  List<String> selectedSchools = [];

  List<PropertyListModel> filteredProperties = [];
  bool isLoading = false;
  String? errorMessage;

  void setPriceRange(RangeValues values) {
    priceRange = values;
    notifyListeners();
  }

  // void setBedrooms(String value) {
  //   selectedBedrooms = value;
  //   notifyListeners();
  // }

  void setBedrooms(List<String> values) {
    selectedBedrooms = values;
    notifyListeners();
  }

  // void setBathrooms(String value) {
  //   selectedBathrooms = value;
  //   notifyListeners();
  // }

  void setBathrooms(List<String> values) {
    selectedBathrooms = values;
    notifyListeners();
  }

  void setSchools(List<String> values) {
    selectedSchools = values;
    notifyListeners();
  }

  Future<void> applyFilters(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {
        "min_rent": priceRange.start.toInt(),
        "max_rent": priceRange.end.toInt(),
        if (selectedBedrooms.isNotEmpty) "bedrooms": selectedBedrooms,
        if (selectedBathrooms.isNotEmpty) "bathrooms": selectedBathrooms,
        if (selectedSchools.isNotEmpty) "schools": selectedSchools,
        // if (selectedBedrooms != 'All') "bedrooms": int.tryParse(selectedBedrooms),
        // if (selectedBathrooms != 'All') "bathrooms": int.tryParse(selectedBathrooms),
      };

      queryParams.removeWhere((key, value) => value == null);

      // final Uri url = Uri.parse(Environment.iosAppBaseUrl).replace(
      //   path: '/api/properties/filter/',
      //   queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())),
      // );

      final Uri url = Uri.parse(Environment.iosAppBaseUrl).replace(
        path: '/api/properties/filter/',
        queryParameters: queryParams.map((key, value) {
          if (value is List<String>) {
            return MapEntry(key, value); // ✅ Keeps list as multiple query params
          } else {
            return MapEntry(key, value.toString());
          }
        }),
      );

      print("url is: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        var filteredProperties = propertyListModelFromJson(response.body);
        // List<dynamic> data = json.decode(response.body);
        // filteredProperties = data.map((item) => PropertyListModel.fromJson(item)).toList();
        
        // Navigate to home page to display results
        context.go('/home', extra: filteredProperties);
      } else {
        errorMessage = 'Failed to fetch properties: ${response.reasonPhrase}';
      }
    } catch (e) {
      errorMessage = 'An error occurred: $e';
    }

    isLoading = false;
    notifyListeners();
  }

  void resetFilters() {
    priceRange = const RangeValues(0, 50000);
    selectedBedrooms = [];
    selectedBathrooms = [];
    selectedSchools = [];
    notifyListeners();
  }
}