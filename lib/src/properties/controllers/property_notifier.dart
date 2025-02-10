import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
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
  List<PropertyListModel> userProperties = [];

  Future<List<PropertyListModel>> fetchUserProperties() async {
    try {
      String? accessToken = Storage().getString('accessToken');
      if (accessToken == null) throw Exception("User not authenticated");

      final response = await http.get(
        Uri.parse("${Environment.iosAppBaseUrl}/api/properties/user/"),
        headers: {
          "Authorization": "Token $accessToken",
          "Content-Type": "application/json"
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        userProperties = data.map((json) => PropertyListModel.fromJson(json)).toList();
        notifyListeners();
        return userProperties;
      } else {
        throw Exception("Failed to fetch user properties");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }


  Future<void> fetchProperties({double? lat, double? lng}) async {
    isLoading = true;
    notifyListeners();
    try {
      String url = '${Environment.iosAppBaseUrl}/api/properties/';
      if (lat != null && lng != null) {
        url += "?lat=$lat&lng=$lng";
      }
      final response = await http.get(
        Uri.parse(url),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      var url = Uri.parse('${Environment.iosAppBaseUrl}/api/properties/$propertyId/');
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        _selectedProperty = PropertyDetailModel.fromJson(jsonData);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        debugPrint("Error fetching property details: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception while fetching property details: $e");
    }

    isLoading = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
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
    String apiUrl = '${Environment.iosAppBaseUrl}/api/properties/';

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

  Future<String?> fetchLocation(Uri uri, {Map<String, String>? headers}) async {
    try {
      final response = await http.get(uri, headers: headers);
      if(response.statusCode == 200) {
        return response.body;
      }
    } catch(e) {
      debugPrint(e.toString());
    }
    return null;
  }
}