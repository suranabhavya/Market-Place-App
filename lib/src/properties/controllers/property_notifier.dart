import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
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
  bool isLoadingMore = false;
  String? nextPageUrl;
  int totalPropertiesCount = 0;
  List<PropertyListModel> userProperties = [];
  List<PropertyListModel> nearbyProperties = [];

  // Reset properties and pagination data
  void resetProperties() {
    _properties = [];
    nextPageUrl = null;
    totalPropertiesCount = 0;
    notifyListeners();
  }

  Future<List<PropertyListModel>> fetchUserProperties() async {
    try {
      String? accessToken = Storage().getString('accessToken');
      if (accessToken == null) throw Exception("User not authenticated");

      final response = await http.get(
        Uri.parse("${Environment.baseUrl}/api/properties/user/"),
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
    if (isLoading) return;
    
    isLoading = true;
    nextPageUrl = null; // Reset pagination when fetching from the beginning
    notifyListeners();
    
    try {
      String url = '${Environment.baseUrl}/api/properties/';
      if (lat != null && lng != null) {
        url += "?lat=$lat&lng=$lng";
      }
      
      debugPrint("Fetching properties from URL: $url");
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        // Parse the paginated response
        final PaginatedPropertiesResponse paginatedResponse = paginatedPropertiesFromJson(response.body);
        
        // Update properties list with results
        _properties = paginatedResponse.results;
        
        // Store pagination info
        nextPageUrl = paginatedResponse.next;
        totalPropertiesCount = paginatedResponse.count;

        debugPrint("Fetched ${paginatedResponse.results.length} properties");
        debugPrint("Total count: $totalPropertiesCount");
        debugPrint("Next page URL: $nextPageUrl");

        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        debugPrint("Error fetching properties: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception: $e");
    }
    
    isLoading = false;
    notifyListeners();
  }

  // Load more properties for infinite scrolling
  Future<void> loadMoreProperties() async {
    if (isLoadingMore || nextPageUrl == null) {
      debugPrint("Skipping load more: isLoadingMore=$isLoadingMore, nextPageUrl=$nextPageUrl");
      return;
    }
    
    debugPrint("Loading more properties from URL: $nextPageUrl");
    isLoadingMore = true;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse(nextPageUrl!),
        headers: {
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        // Parse the paginated response
        final PaginatedPropertiesResponse paginatedResponse = paginatedPropertiesFromJson(response.body);
        
        // Add more properties to the existing list
        _properties.addAll(paginatedResponse.results);
        debugPrint("Added ${paginatedResponse.results.length} more properties, total now: ${_properties.length}");
        
        // Update pagination info
        nextPageUrl = paginatedResponse.next;
        debugPrint("Next page URL updated to: $nextPageUrl");
      } else {
        debugPrint("Error loading more properties: ${response.body}");
      }
    } catch (e) {
      debugPrint("Exception loading more properties: $e");
    }
    
    isLoadingMore = false;
    notifyListeners();
  }

  // Fetch a specific property detail by ID
  Future<void> fetchPropertyDetail(String propertyId) async {
    isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      var url = Uri.parse('${Environment.baseUrl}/api/properties/$propertyId/');
      final response = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        String responseBody = utf8.decode(response.bodyBytes);
        final jsonData = jsonDecode(responseBody);
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
    String apiUrl = '${Environment.baseUrl}/api/properties/';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(propertyData),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        PropertyListModel newProperty = PropertyListModel.fromJson(data);
        _properties.insert(0, newProperty);
        totalPropertiesCount += 1;
        notifyListeners();
        onSuccess();
      } else {
        debugPrint("Error creating property: ${response.body}");
        onError(); // Callback on error
      }
    } catch (e) {
      debugPrint("Exception: $e");
      onError(); // Callback on exception
    }
  }

  // Update property API call
  Future<void> updateProperty({
    required String token,
    required String propertyId,
    required Map<String, dynamic> propertyData,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    String apiUrl = '${Environment.baseUrl}/api/properties/$propertyId/';

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(propertyData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        PropertyListModel updatedProperty = PropertyListModel.fromJson(data);
        int index = _properties.indexWhere((p) => p.id == propertyId);
        if (index != -1) {
          _properties[index] = updatedProperty;
        }
        notifyListeners();
        onSuccess();
      } else {
        debugPrint("Error updating property: ${response.body}");
        onError();
      }
    } catch (e) {
      debugPrint("Exception: $e");
      onError();
    }
  }

  Future<void> deleteProperty({
    required String token,
    required String propertyId,
    required VoidCallback onSuccess,
    required VoidCallback onError,
  }) async {
    String apiUrl = '${Environment.baseUrl}/api/properties/$propertyId/';

    try {
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        // Remove the property from the list
        _properties.removeWhere((property) => property.id == propertyId);
        notifyListeners();
        onSuccess();
      } else {
        debugPrint("Error deleting property: ${response.body}");
        onError();
      }
    } catch (e) {
      debugPrint("Exception deleting property: $e");
      onError();
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

  Future<void> fetchNearbyProperties(double latitude, double longitude) async {
    if (isLoading) return; // Prevent multiple simultaneous fetches
    
    isLoading = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    try {
      final response = await http.get(
        Uri.parse('${Environment.baseUrl}/api/properties/?latitude=$latitude&longitude=$longitude&max_distance=2'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        nearbyProperties = (data['results'] as List)
            .map((property) => PropertyListModel.fromJson(property))
            .toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifyListeners();
        });
      } else {
        debugPrint('Failed to fetch nearby properties: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching nearby properties: $e');
    } finally {
      isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }
}