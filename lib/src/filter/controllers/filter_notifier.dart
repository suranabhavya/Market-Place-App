import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';

class FilterNotifier extends ChangeNotifier {
  RangeValues priceRange = const RangeValues(0, 50000);
  String selectedBedrooms = 'All';
  String selectedBathrooms = 'All';

  List<PropertyListModel> filteredProperties = [];
  bool isLoading = false;
  String? errorMessage;

  void setPriceRange(RangeValues values) {
    priceRange = values;
    notifyListeners();
  }

  void setBedrooms(String value) {
    selectedBedrooms = value;
    notifyListeners();
  }

  void setBathrooms(String value) {
    selectedBathrooms = value;
    notifyListeners();
  }

  Future<void> applyFilters(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {
        "min_rent": priceRange.start.toInt(),
        "max_rent": priceRange.end.toInt(),
        if (selectedBedrooms != 'All') "bedrooms": int.tryParse(selectedBedrooms),
        if (selectedBathrooms != 'All') "bathrooms": int.tryParse(selectedBathrooms),
      };

      queryParams.removeWhere((key, value) => value == null);

      final Uri url = Uri.parse(Environment.iosAppBaseUrl).replace(
        path: '/api/properties/filter/',
        queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())),
      );

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
    selectedBedrooms = 'All';
    selectedBathrooms = 'All';
    notifyListeners();
  }
}