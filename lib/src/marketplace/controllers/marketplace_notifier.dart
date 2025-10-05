import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/services/http_client.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_detail_model.dart';

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
  List<String> _selectedConditions = [];
  bool? _negotiable;
  bool? _deliveryAvailable;
  bool? _originalReceiptAvailable;
  List<String> _selectedItemTypes = [];
  List<String> _selectedItemSubtypes = [];
  List<String> _selectedSchoolIds = [];
  double _minPrice = 0;
  double _maxPrice = 10000;

  // Location for proximity search
  double? _latitude;
  double? _longitude;

  bool get isLoading => _isLoading;
  String get searchKey => _searchKey;
  List<MarketplaceListModel> get marketplaceItems => _marketplaceItems;
  List<PropertyListItem> get userProperties => _userProperties;
  String? get error => _error;

  // Autocomplete getters
  bool get isAutocompleteLoading => _isAutocompleteLoading;
  Map<String, List<String>> get autocompleteResults => _autocompleteResults;

  // Filter getters
  List<String> get selectedConditions => _selectedConditions;
  bool? get negotiable => _negotiable;
  bool? get deliveryAvailable => _deliveryAvailable;
  bool? get originalReceiptAvailable => _originalReceiptAvailable;
  List<String> get selectedItemTypes => _selectedItemTypes;
  List<String> get selectedItemSubtypes => _selectedItemSubtypes;
  List<String> get selectedSchoolIds => _selectedSchoolIds;
  double get minPrice => _minPrice;
  double get maxPrice => _maxPrice;

  // Location getters
  double? get latitude => _latitude;
  double? get longitude => _longitude;

  void setSearchKey(String value) {
    _searchKey = value;
    notifyListeners();
  }

  void clearSearch() {
    _searchKey = '';
    notifyListeners();
  }

  // Add a method to set search key and apply filters in one go
  Future<void> setSearchKeyAndApplyFilters(String searchKey) async {
    _searchKey = searchKey;
    notifyListeners();
    await refreshMarketplaceItems();
  }

  // Add a method to set search key with location and apply filters
  Future<void> setSearchKeyWithLocationAndApplyFilters(String searchKey, double lat, double lng) async {
    _searchKey = searchKey;
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
    await refreshMarketplaceItems();
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
      final url = '${Environment.baseUrl}/api/marketplace/autocomplete/?q=$query';
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
  void setSelectedConditions(List<String> conditions) {
    _selectedConditions = conditions;
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

  // Location setters
  void setLocation(double lat, double lng) {
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }

  void resetLocation() {
    _latitude = null;
    _longitude = null;
    notifyListeners();
  }

  void resetFilters() {
    _selectedConditions = [];
    _negotiable = null;
    _deliveryAvailable = null;
    _originalReceiptAvailable = null;
    _selectedItemTypes = [];
    _selectedItemSubtypes = [];
    _selectedSchoolIds = [];
    _minPrice = 0;
    _maxPrice = 10000;
    // Reset location as well when resetting all filters
    _latitude = null;
    _longitude = null;
    notifyListeners();
  }

  Future<void> fetchUserProperties() async {
    String? token = Storage().getString('accessToken');
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('${Environment.baseUrl}/api/properties/my_listings/'),
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

  // Remove context from applyFilters (deprecated, use refreshMarketplaceItems)
  Future<void> applyFilters() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '${Environment.baseUrl}/api/marketplace/';
      
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
      
      // Add conditions if selected
      if (_selectedConditions.isNotEmpty) {
        queryParams['condition'] = _selectedConditions.join(',');
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

      // Add location parameters for proximity search
      if (_latitude != null && _longitude != null) {
        queryParams['latitude'] = _latitude.toString();
        queryParams['longitude'] = _longitude.toString();
        // Default max distance of 5 miles (same as properties)
        queryParams['max_distance'] = '5';
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
      debugPrint("MarketplaceNotifier - Calling notifyListeners() with ${_marketplaceItems.length} items");
      notifyListeners();
    }
  }

  // Add a context-free version of applyFilters
  Future<void> refreshMarketplaceItems() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      String url = '${Environment.baseUrl}/api/marketplace/';
      
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
      
      // Add conditions if selected
      if (_selectedConditions.isNotEmpty) {
        queryParams['condition'] = _selectedConditions.join(',');
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

      // Add location parameters for proximity search
      if (_latitude != null && _longitude != null) {
        queryParams['latitude'] = _latitude.toString();
        queryParams['longitude'] = _longitude.toString();
        // Default max distance of 5 miles (same as properties)
        queryParams['max_distance'] = '5';
      }

      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      debugPrint("Fetching items from URL: $uri");
      
      final response = await AppHttpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: AppHttpClient.splashTimeout,
      );

      if (response.statusCode == 200) {
        debugPrint("response body: ${response.body}");
        final PaginatedMarketplaceResponse paginatedResponse = paginatedMarketplaceFromJson(response.body);
        debugPrint("Parsed paginated response - count: ${paginatedResponse.count}");
        debugPrint("Parsed paginated response - results length: ${paginatedResponse.results.length}");
        _marketplaceItems = paginatedResponse.results;
        debugPrint("Set _marketplaceItems length: ${_marketplaceItems.length}");
      } else {
        _error = 'Failed to fetch marketplace items';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      debugPrint("MarketplaceNotifier - Calling notifyListeners() with ${_marketplaceItems.length} items");
      notifyListeners();
    }
  }

  // Fetch marketplace detail
  Future<MarketplaceDetailModel?> fetchMarketplaceDetail(String itemId) async {
    try {
      final url = '${Environment.baseUrl}/api/marketplace/$itemId/';
      debugPrint('Fetching marketplace detail from: $url');
      
      final response = await http.get(Uri.parse(url));

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
      final url = '${Environment.baseUrl}/api/marketplace/my_listings/';
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
        final responseData = json.decode(response.body);
        
        // Handle both paginated and non-paginated responses
        List<dynamic> results;
        if (responseData is Map<String, dynamic> && responseData.containsKey('results')) {
          // Paginated response
          results = responseData['results'];
        } else if (responseData is List) {
          // Direct list response
          results = responseData;
        } else {
          debugPrint('Unexpected response format: $responseData');
          return [];
        }
        
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

  // Check if there are any active filters
  bool get hasActiveFilters {
    return _searchKey.isNotEmpty ||
        _selectedConditions.isNotEmpty ||
        _negotiable != null ||
        _deliveryAvailable != null ||
        _originalReceiptAvailable != null ||
        _selectedItemTypes.isNotEmpty ||
        _selectedItemSubtypes.isNotEmpty ||
        _selectedSchoolIds.isNotEmpty ||
        _minPrice > 0 ||
        _maxPrice < 10000 ||
        (_latitude != null && _longitude != null);
  }

  // Delete marketplace item
  Future<void> deleteMarketplaceItem({
    required String token,
    required String itemId,
    required Function onSuccess,
    required Function onError,
  }) async {
    String apiUrl = '${Environment.baseUrl}/api/marketplace/$itemId/';

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