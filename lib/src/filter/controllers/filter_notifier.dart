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
  DateTime? availableFrom;
  DateTime? availableTo;

  List<PropertyListModel> filteredProperties = [];
  bool isLoading = false;
  String? errorMessage;

  void setPriceRange(RangeValues values) {
    priceRange = values;
    notifyListeners();
  }

  void setBedrooms(List<String> values) {
    selectedBedrooms = values;
    notifyListeners();
  }

  void setBathrooms(List<String> values) {
    selectedBathrooms = values;
    notifyListeners();
  }

  void setSchools(List<String> values) {
    selectedSchools = values;
    notifyListeners();
  }

  void setMoveInDate(DateTime? date) {
    availableFrom = date;
    notifyListeners();
  }

  void setMoveOutDate(DateTime? date) {
    availableTo = date;
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
        if (availableFrom != null) "available_from": availableFrom!.toIso8601String().split('T')[0],
        if (availableTo != null) "available_to": availableTo!.toIso8601String().split('T')[0],
      };

      queryParams.removeWhere((key, value) => value == null || value.toString().isEmpty);

      final Uri url = Uri.parse(Environment.iosAppBaseUrl).replace(
        path: '/api/properties/',
        queryParameters: queryParams.map((key, value) {
          if (value is List<String>) {
            return MapEntry(key, value);
          } else {
            return MapEntry(key, value.toString());
          }
        }),
      );

      print("Fetching filtered properties from: $url");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        filteredProperties = propertyListModelFromJson(response.body);
        notifyListeners();
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
    availableFrom = null;
    availableTo = null;
    notifyListeners();
  }
}