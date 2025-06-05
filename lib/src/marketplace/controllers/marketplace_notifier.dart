import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_detail_model.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';

class PropertyListItem {
  final String id;
  final String title;

  PropertyListItem({required this.id, required this.title});

  factory PropertyListItem.fromJson(Map<String, dynamic> json) {
    return PropertyListItem(
      id: json['id'],
      title: json['title'],
    );
  }
}

class MarketplaceNotifier extends ChangeNotifier {
  bool _isLoading = false;
  String _searchKey = '';
  List<MarketplaceListModel> _marketplaceItems = [];
  List<PropertyListItem> _userProperties = [];
  String? _error;

  // Autocomplete related properties
  bool _isAutocompleteLoading = false;
  Map<String, List<String>> _autocompleteResults = {
    'title': [],
    'description': [],
    'item_type': [],
    'item_subtype': [],
    'school_name': [],
  };

  // Filter properties
  String? _condition;
  bool? _negotiable;
  bool? _deliveryAvailable;
  bool? _originalReceiptAvailable;
  List<String> _selectedItemTypes = [];
  List<String> _selectedItemSubtypes = [];
  List<String> _selectedSchoolIds = [];
  double _minPrice = 0;
  double _maxPrice = 10000;

  bool get isLoading => _isLoading;
  String get searchKey => _searchKey;
  List<MarketplaceListModel> get marketplaceItems => _marketplaceItems;
  List<PropertyListItem> get userProperties => _userProperties;
  String? get error => _error;

  // Autocomplete getters
  bool get isAutocompleteLoading => _isAutocompleteLoading;
  Map<String, List<String>> get autocompleteResults => _autocompleteResults;

  // Filter getters
  String? get condition => _condition;
  bool? get negotiable => _negotiable;
  bool? get deliveryAvailable => _deliveryAvailable;
  bool? get originalReceiptAvailable => _originalReceiptAvailable;
  List<String> get selectedItemTypes => _selectedItemTypes;
  List<String> get selectedItemSubtypes => _selectedItemSubtypes;
  List<String> get selectedSchoolIds => _selectedSchoolIds;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;

  void setSearchKey(String value) {
    _searchKey = value;
    print('MarketplaceNotifier.setSearchKey: Set searchKey to "$value"');
    notifyListeners();
  }

  void clearSearch() {
    _searchKey = '';
    print('MarketplaceNotifier.clearSearch: Cleared searchKey');
    notifyListeners();
  }

  // Add a method to set search key and apply filters in one go
  Future<void> setSearchKeyAndApplyFilters(String searchKey, BuildContext context) async {
    _searchKey = searchKey;
    print('MarketplaceNotifier.setSearchKeyAndApplyFilters: Set searchKey to "$searchKey"');
    notifyListeners();
    await applyFilters(context);
  }

  // Force notify listeners - useful for ensuring UI updates
  void forceNotifyListeners() {
    notifyListeners();
  }

  // Clear autocomplete results
  void clearAutocompleteResults() {
    _autocompleteResults = {
      'title': [],
      'description': [],
      'item_type': [],
      'item_subtype': [],
      'school_name': [],
    };
    notifyListeners();
  }

  // Fetch autocomplete suggestions for marketplace items
  Future<void> fetchAutocomplete(String query) async {
    if (query.isEmpty) {
      clearAutocompleteResults();
      return;
    }

    _isAutocompleteLoading = true;
    notifyListeners();

    try {
      final url = '${Environment.iosAppBaseUrl}/api/marketplace/autocomplete/?q=$query';
      debugPrint('Fetching marketplace autocomplete from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('Marketplace autocomplete response: ${response.body}');
        
        Map<String, List<String>> results = {};
        data.forEach((key, value) {
          if (value is List) {
            // Filter out null values and convert everything to strings
            results[key] = value
                .where((item) => item != null)
                .map<String>((item) => item?.toString() ?? '')
                .where((item) => item.isNotEmpty)
                .toList();
            
            debugPrint('Category $key has ${results[key]?.length ?? 0} items');
          }
        });
        
        _autocompleteResults = results;
        
      } else {
        debugPrint('Failed to fetch marketplace autocomplete: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching marketplace autocomplete: $e');
    } finally {
      _isAutocompleteLoading = false;
      notifyListeners();
    }
  }

  // Filter setters
  void setCondition(String? value) {
    _condition = value;
    notifyListeners();
  }

  void setNegotiable(bool value) {
    _negotiable = value;
    notifyListeners();
  }

  void setDeliveryAvailable(bool value) {
    _deliveryAvailable = value;
    notifyListeners();
  }

  void setOriginalReceiptAvailable(bool value) {
    _originalReceiptAvailable = value;
    notifyListeners();
  }

  void setSelectedItemTypes(List<String> types) {
    _selectedItemTypes = types;
    notifyListeners();
  }

  void setSelectedItemSubtypes(List<String> subtypes) {
    _selectedItemSubtypes = subtypes;
    notifyListeners();
  }

  void setSelectedSchoolIds(List<String> ids) {
    _selectedSchoolIds = ids;
    notifyListeners();
  }

  void setPriceRange(double min, double max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void resetFilters() {
    _condition = null;
    _negotiable = null;
    _deliveryAvailable = null;
    _originalReceiptAvailable = null;
    _selectedItemTypes = [];
    _selectedItemSubtypes = [];
    _selectedSchoolIds = [];
    _minPrice = 0;
    _maxPrice = 10000;
    notifyListeners();
  }

  Future<void> fetchUserProperties() async {
    String? token = Storage().getString('accessToken');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${Environment.iosAppBaseUrl}/api/properties/my_listings/'),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _userProperties = data.map((item) => PropertyListItem.fromJson(item)).toList();
        notifyListeners();
      } else {
        debugPrint('Failed to fetch user properties: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching user properties: $e');
    }
  }

  Future<void> applyFilters(BuildContext context) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '${Environment.iosAppBaseUrl}/api/marketplace/';
      
      // Build query parameters
      final queryParams = <String, String>{};
      
      // Add search query if present
      if (_searchKey.isNotEmpty) {
        queryParams['search'] = _searchKey;
        
        // Check if the search key matches a school name from autocomplete
        // If so, also add the school search parameter
        if (_autocompleteResults['school_name']?.contains(_searchKey) ?? false) {
          queryParams['school_name'] = _searchKey;
        }
      }
      
      // Add condition if selected
      if (_condition != null && _condition!.isNotEmpty) {
        queryParams['condition'] = _condition!;
      }
      
      // Add boolean filters
      if (_negotiable != null) {
        queryParams['negotiable'] = _negotiable.toString();
      }
      
      if (_deliveryAvailable != null) {
        queryParams['delivery_available'] = _deliveryAvailable.toString();
      }
      
      if (_originalReceiptAvailable != null) {
        queryParams['original_receipt_available'] = _originalReceiptAvailable.toString();
      }
      
      // Add price range
      if (_minPrice > 0) {
        queryParams['min_price'] = _minPrice.toString();
      }
      
      if (_maxPrice < 10000) {
        queryParams['max_price'] = _maxPrice.toString();
      }
      
      // Add item types and subtypes
      if (_selectedItemTypes.isNotEmpty) {
        queryParams['item_type'] = _selectedItemTypes.join(',');
      }
      
      if (_selectedItemSubtypes.isNotEmpty) {
        queryParams['item_subtype'] = _selectedItemSubtypes.join(',');
      }
      
      // Add school IDs
      if (_selectedSchoolIds.isNotEmpty) {
        queryParams['schools_nearby'] = _selectedSchoolIds.join(',');
      }

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      debugPrint("Fetching items from URL: $uri");
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint("response body: ${response.body}");
        final PaginatedMarketplaceResponse paginatedResponse = paginatedMarketplaceFromJson(response.body);
        _marketplaceItems = paginatedResponse.results;
      } else {
        _error = 'Failed to fetch marketplace items';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMarketplaceItem({
    required String token,
    required Map<String, dynamic> marketplaceData,
    required Function onSuccess,
    required Function onError,
  }) async {
    String apiUrl = '${Environment.iosAppBaseUrl}/api/marketplace/';

    try {
      // Debug print the incoming data
      print('Creating marketplace item with data:');
      print('Raw marketplaceData: $marketplaceData');
      
      var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
      request.headers['Authorization'] = 'Token $token';

      // Handle images
      List<String>? imagePaths = marketplaceData['images'] as List<String>?;
      if (imagePaths != null && imagePaths.isNotEmpty) {
        print('📸 Adding ${imagePaths.length} images');
        for (var imagePath in imagePaths) {
          File imageFile = File(imagePath);
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              imageFile.path,
              filename: path.basename(imageFile.path),
            ),
          );
        }
      }

      // Add basic fields
      request.fields['title'] = marketplaceData['title'] ?? '';
      if (marketplaceData['description'] != null) {
        request.fields['description'] = marketplaceData['description'];
      }
      request.fields['price'] = marketplaceData['price'].toString();
      
      // Handle original_price properly - only add if not null
      if (marketplaceData['original_price'] != null) {
        request.fields['original_price'] = marketplaceData['original_price'].toString();
        print('original_price: ${marketplaceData['original_price']}');
      } else {
        print('original_price: null (not included in request)');
      }
      
      request.fields['item_type'] = marketplaceData['item_type'] ?? '';
      request.fields['item_subtype'] = marketplaceData['item_subtype'] ?? '';
      request.fields['condition'] = marketplaceData['condition'] ?? '';
      request.fields['negotiable'] = marketplaceData['negotiable'].toString();
      request.fields['delivery_available'] = marketplaceData['delivery_available'].toString();
      request.fields['address'] = marketplaceData['address'] ?? '';
      
      if (marketplaceData['property_id'] != null && marketplaceData['property_id'].toString().isNotEmpty) {
        request.fields['property_id'] = marketplaceData['property_id'].toString();
      }
      
      if (marketplaceData['unit'] != null && marketplaceData['unit'].toString().isNotEmpty) {
        request.fields['unit'] = marketplaceData['unit'].toString();
      }
      
      if (marketplaceData['latitude'] != null) {
        request.fields['latitude'] = marketplaceData['latitude'].toString();
      }
      
      if (marketplaceData['longitude'] != null) {
        request.fields['longitude'] = marketplaceData['longitude'].toString();
      }
      
      request.fields['hide_address'] = marketplaceData['hide_address'].toString();
      
      if (marketplaceData['availability_date'] != null) {
        request.fields['availability_date'] = marketplaceData['availability_date'];
      }
      
      request.fields['original_receipt_available'] = marketplaceData['original_receipt_available'].toString();

      // Add school_ids if present
      if (marketplaceData['school_ids'] != null && marketplaceData['school_ids'].isNotEmpty) {
        // Join the list into a comma-separated string
        String schoolIdsString = marketplaceData['school_ids'].join(',');
        request.fields['school_ids'] = schoolIdsString;
      }

      // Debug print the final request fields
      print('📋 Final request fields:');
      request.fields.forEach((key, value) {
        print('  $key: $value');
      });
      print('📁 Files count: ${request.files.length}');

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print('📡 API Response Status: ${response.statusCode}');
      print('📡 API Response Body: $responseBody');

      if (response.statusCode == 201) {
        debugPrint('✅ Successfully created marketplace item');
        
        // Don't reset filters or clear items here - let the parent screen handle refresh
        // This ensures that any active filters or search terms are preserved
        
        onSuccess();
      } else {
        debugPrint('❌ Failed to create marketplace item: $responseBody');
        onError();
      }
    } catch (e) {
      debugPrint('💥 Error creating marketplace item: $e');
      onError();
    }
  }

  // Fetch marketplace item details
  Future<MarketplaceDetailModel?> fetchMarketplaceDetail(String itemId) async {
    try {
      final url = '${Environment.iosAppBaseUrl}/api/marketplace/$itemId/';
      debugPrint('Fetching marketplace detail from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Marketplace detail response: ${response.body}');
        return MarketplaceDetailModel.fromJson(json.decode(response.body));
      } else {
        debugPrint('Failed to fetch marketplace detail: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching marketplace detail: $e');
      return null;
    }
  }

  // Fetch user's marketplace listings
  Future<List<MarketplaceListModel>> fetchUserMarketplaceListings(String token) async {
    try {
      final url = '${Environment.iosAppBaseUrl}/api/marketplace/my_listings/';
      debugPrint('Fetching user marketplace listings from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('User marketplace listings response: ${response.body}');
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        
        return results.map((item) => MarketplaceListModel.fromJson(item)).toList();
      } else {
        debugPrint('Failed to fetch user marketplace listings: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching user marketplace listings: $e');
      return [];
    }
  }

  // Update marketplace item
  Future<void> updateMarketplaceItem({
    required String token,
    required String itemId,
    required Map<String, dynamic> marketplaceData,
    required Function onSuccess,
    required Function onError,
  }) async {
    String apiUrl = '${Environment.iosAppBaseUrl}/api/marketplace/$itemId/';

    try {
      debugPrint('Updating marketplace item with ID: $itemId');
      debugPrint('Update data: $marketplaceData');
      
      var request = http.MultipartRequest("PUT", Uri.parse(apiUrl));
      request.headers['Authorization'] = 'Token $token';

      // Handle images (only add new images if provided)
      List<String>? imagePaths = marketplaceData['images'] as List<String>?;
      if (imagePaths != null && imagePaths.isNotEmpty) {
        debugPrint('Adding ${imagePaths.length} images for update');
        for (var imagePath in imagePaths) {
          File imageFile = File(imagePath);
          request.files.add(
            await http.MultipartFile.fromPath(
              'images',
              imageFile.path,
              filename: path.basename(imageFile.path),
            ),
          );
        }
      }

      // Add basic fields
      request.fields['title'] = marketplaceData['title'] ?? '';
      if (marketplaceData['description'] != null) {
        request.fields['description'] = marketplaceData['description'];
      }
      request.fields['price'] = marketplaceData['price'].toString();
      
      // Handle original_price properly - only add if not null
      if (marketplaceData['original_price'] != null) {
        request.fields['original_price'] = marketplaceData['original_price'].toString();
      }
      
      request.fields['item_type'] = marketplaceData['item_type'] ?? '';
      request.fields['item_subtype'] = marketplaceData['item_subtype'] ?? '';
      request.fields['condition'] = marketplaceData['condition'] ?? '';
      request.fields['negotiable'] = marketplaceData['negotiable'].toString();
      request.fields['delivery_available'] = marketplaceData['delivery_available'].toString();
      request.fields['address'] = marketplaceData['address'] ?? '';
      
      if (marketplaceData['property_id'] != null && marketplaceData['property_id'].toString().isNotEmpty) {
        request.fields['property_id'] = marketplaceData['property_id'].toString();
      }
      
      if (marketplaceData['unit'] != null && marketplaceData['unit'].toString().isNotEmpty) {
        request.fields['unit'] = marketplaceData['unit'].toString();
      }
      
      if (marketplaceData['latitude'] != null) {
        request.fields['latitude'] = marketplaceData['latitude'].toString();
      }
      
      if (marketplaceData['longitude'] != null) {
        request.fields['longitude'] = marketplaceData['longitude'].toString();
      }
      
      request.fields['hide_address'] = marketplaceData['hide_address'].toString();
      
      if (marketplaceData['availability_date'] != null) {
        request.fields['availability_date'] = marketplaceData['availability_date'];
      }
      
      request.fields['original_receipt_available'] = marketplaceData['original_receipt_available'].toString();

      // Add school_ids if present
      if (marketplaceData['school_ids'] != null && marketplaceData['school_ids'].isNotEmpty) {
        String schoolIdsString = marketplaceData['school_ids'].join(',');
        request.fields['school_ids'] = schoolIdsString;
      }

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      debugPrint('Update API Response Status: ${response.statusCode}');
      debugPrint('Update API Response Body: $responseBody');

      if (response.statusCode == 200) {
        debugPrint('✅ Successfully updated marketplace item');
        onSuccess();
      } else {
        debugPrint('❌ Failed to update marketplace item: $responseBody');
        onError();
      }
    } catch (e) {
      debugPrint('💥 Error updating marketplace item: $e');
      onError();
    }
  }

  // Delete marketplace item
  Future<void> deleteMarketplaceItem({
    required String token,
    required String itemId,
    required Function onSuccess,
    required Function onError,
  }) async {
    String apiUrl = '${Environment.iosAppBaseUrl}/api/marketplace/$itemId/';

    try {
      debugPrint('Deleting marketplace item with ID: $itemId');
      
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      debugPrint('Delete API Response Status: ${response.statusCode}');

      if (response.statusCode == 204) {
        debugPrint('✅ Successfully deleted marketplace item');
        onSuccess();
      } else {
        debugPrint('❌ Failed to delete marketplace item: ${response.body}');
        onError();
      }
    } catch (e) {
      debugPrint('💥 Error deleting marketplace item: $e');
      onError();
    }
  }
} 