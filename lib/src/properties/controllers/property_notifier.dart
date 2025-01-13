import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/properties/models/property_detail_model.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/src/properties/models/property_list_model.dart';

class PropertyNotifier extends ChangeNotifier {
  PropertyListModel? property;

  void setProperty(PropertyListModel p) {
    property = p;
    notifyListeners();
  }

  bool _description = false;

  bool get description => _description;

  void setDescription() {
    _description = !_description;
    notifyListeners();
  }

  void resetDescription() {
    _description = false;
  }

  PropertyDetailModel? _selectedProperty;

  List<PropertyListModel> _properties = [];
  List<PropertyListModel> get properties => _properties;
  PropertyDetailModel? get selectedProperty => _selectedProperty;
  bool isLoading = false;


  Future<void> fetchProperties() async {
    isLoading = true;
    notifyListeners();
    try {
      var url = Uri.parse('${Environment.appBaseUrl}/api/properties/');
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        // Parse the response
        final List<dynamic> jsonData = jsonDecode(response.body);
        final List<PropertyListModel> fetchedProperties = jsonData.map((json) {
          return PropertyListModel.fromJson(json);
        }).toList();

        // Notify listeners with the fetched data
        _properties = fetchedProperties;
        print("properies are: $_properties");
        notifyListeners();
      } else {
        debugPrint("Error fetching properties: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }
    isLoading = false;
    notifyListeners();
  }

  // Fetch a specific property detail by ID
  Future<void> fetchPropertyDetail(String propertyId) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/api/properties/$propertyId/'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        _selectedProperty = PropertyDetailModel.fromJson(jsonData);
      } else {
        debugPrint("Error fetching property details: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception while fetching property details: $e");
    }

    isLoading = false;
    notifyListeners();
  }

  // Reset selected property
  void resetSelectedProperty() {
    _selectedProperty = null;
    notifyListeners();
  }

  // Create property API call
  Future<void> createProperty({
    required String token,
    required Map<String, dynamic> propertyData,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    print("hello");
    const String apiUrl = "http://127.0.0.1:8000/api/properties/";

    try {
      print("token last: $token");
      print("data last: $propertyData");
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(propertyData),
      );

      if (response.statusCode == 201) {
        print("bye");
        // Parse the response to get the created property
        print("response is ${response.body}");
        final data = jsonDecode(response.body);
        property = PropertyListModel.fromJson(data); // Assuming Properties model has a fromJson method
        print("property is: $property");
        notifyListeners();
        onSuccess(); // Callback on successful creation
      } else {
        debugPrint("Error creating property: ${response.body}");
        onError(); // Callback on error
      }
    } catch (e) {
      debugPrint("Exception: $e");
      onError(); // Callback on exception
    }
  }
}