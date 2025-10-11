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

// Cache data structure for storing marketplace items
class CachedMarketplaceData {
  final List<MarketplaceListModel> items;
  final int totalCount;
  final String? nextPageUrl;
  final DateTime timestamp;
  final String cacheKey;

  CachedMarketplaceData({
    required this.items,
    required this.totalCount,
    required this.nextPageUrl,
    required this.timestamp,
    required this.cacheKey,
  });

  // Cache never expires - we always keep it and refresh in background

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'totalCount': totalCount,
    'nextPageUrl': nextPageUrl,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'cacheKey': cacheKey,
  };

  factory CachedMarketplaceData.fromJson(Map<String, dynamic> json) {
    return CachedMarketplaceData(
      items: (json['items'] as List)
          .map((item) => MarketplaceListModel.fromJson(item))
          .toList(),
      totalCount: json['totalCount'],
      nextPageUrl: json['nextPageUrl'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      cacheKey: json['cacheKey'],
    );
  }
}

class MarketplaceNotifier extends ChangeNotifier {
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _searchKey = '';
  List<MarketplaceListModel> _marketplaceItems = [];
  List<PropertyListItem> _userProperties = [];
  String? _error;
  String? _nextPageUrl;

  // Autocomplete related properties
  bool _isAutocompleteLoading = false;
  Map<String, List<String>> _autocompleteResults = {
    'title': [],
    'description': [],
    'item_type': [],
    'item_subtype': [],
    'school_name': [],
  };

  // Caching mechanism
  final Map<String, CachedMarketplaceData> _cache = {};
  String? _lastCacheKey;
  bool _isRefreshing = false;
  bool _isRefreshingMarketplace = false; // Prevent concurrent refreshMarketplaceItems calls
  static const String _cacheKey = 'marketplace_items_cache';
  // Cache never expires - we keep it indefinitely and always refresh in background

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
  bool get isLoadingMore => _isLoadingMore;
  String get searchKey => _searchKey;
  List<MarketplaceListModel> get marketplaceItems => _marketplaceItems;
  List<PropertyListItem> get userProperties => _userProperties;
  String? get error => _error;
  String? get nextPageUrl => _nextPageUrl;

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
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        Map<String, List<String>> results = {};
        data.forEach((key, value) {
          if (value is List) {
            // Filter out null values and convert everything to strings
            results[key] = value
                .where((item) => item != null)
                .map<String>((item) => item?.toString() ?? '')
                .where((item) => item.isNotEmpty)
                .toList();
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

  // Generate cache key based on current filter state
  String _generateCacheKey() {
    final buffer = StringBuffer();
    buffer.write('search:$_searchKey|');
    buffer.write('lat:$_latitude|lng:$_longitude|');
    buffer.write('conditions:${_selectedConditions.join(',')}|');
    buffer.write('negotiable:$_negotiable|');
    buffer.write('delivery:$_deliveryAvailable|');
    buffer.write('receipt:$_originalReceiptAvailable|');
    buffer.write('types:${_selectedItemTypes.join(',')}|');
    buffer.write('subtypes:${_selectedItemSubtypes.join(',')}|');
    buffer.write('schools:${_selectedSchoolIds.join(',')}|');
    buffer.write('price:$_minPrice-$_maxPrice|');
    return buffer.toString();
  }

  // Save cache to storage
  Future<void> _saveToCache(CachedMarketplaceData data) async {
    try {
      final cacheJson = jsonEncode(data.toJson());
      Storage().setString('${_cacheKey}_${data.cacheKey}', cacheJson);
      _cache[data.cacheKey] = data;
      debugPrint("Saved marketplace cache: ${data.cacheKey}");
    } catch (e) {
      debugPrint("Failed to save marketplace cache: $e");
    }
  }

  // Load cache from storage
  Future<CachedMarketplaceData?> _loadFromCache(String cacheKey) async {
    try {
      // Check memory cache first (no expiry check - cache is indefinite)
      if (_cache.containsKey(cacheKey)) {
        debugPrint("Loaded marketplace from memory cache: $cacheKey");
        return _cache[cacheKey];
      }

      // Check disk cache (no expiry check - cache is indefinite)
      final cacheJson = Storage().getString('${_cacheKey}_$cacheKey');
      if (cacheJson != null) {
        final data = CachedMarketplaceData.fromJson(jsonDecode(cacheJson));
        _cache[cacheKey] = data;
        debugPrint("Loaded marketplace from disk cache: $cacheKey");
        return data;
      }
    } catch (e) {
      debugPrint("Failed to load marketplace cache: $e");
    }
    return null;
  }

  // Background refresh without blocking UI
  Future<void> _refreshInBackground(String cacheKey) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    debugPrint("Starting background refresh for marketplace...");

    try {
      final url = _buildMarketplaceUrl();
      final response = await AppHttpClient.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: AppHttpClient.splashTimeout,
      );

      if (response.statusCode == 200) {
        final PaginatedMarketplaceResponse paginatedResponse = paginatedMarketplaceFromJson(response.body);

        // Update cache with fresh data
        final cacheData = CachedMarketplaceData(
          items: List.from(paginatedResponse.results),
          totalCount: paginatedResponse.count,
          nextPageUrl: paginatedResponse.next,
          timestamp: DateTime.now(),
          cacheKey: cacheKey,
        );
        await _saveToCache(cacheData);

        // Update current data if this is still the active filter
        if (_lastCacheKey == cacheKey) {
          _marketplaceItems = List.from(paginatedResponse.results);
          _nextPageUrl = paginatedResponse.next;
          notifyListeners();
          debugPrint("Background refresh completed, UI updated with fresh marketplace data");
        }
      }
    } catch (e) {
      debugPrint("Background marketplace refresh failed: $e");
    } finally {
      _isRefreshing = false;
    }
  }

  // Helper to build marketplace URL with filters
  String _buildMarketplaceUrl() {
    String url = '${Environment.baseUrl}/api/marketplace/';

    // Build query parameters
    final queryParams = <String, String>{
      'page_size': '10',
    };

    // Add search query if present
    if (_searchKey.isNotEmpty) {
      queryParams['search'] = _searchKey;

      // Check if the search key matches a school name from autocomplete
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
      queryParams['max_distance'] = '5';
    }

    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    return uri.toString();
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
      final queryParams = <String, String>{
        'page_size': '10',
      };
      
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
      
      final response = await AppHttpClient.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: AppHttpClient.splashTimeout,
      );

      if (response.statusCode == 200) {
        final PaginatedMarketplaceResponse paginatedResponse = paginatedMarketplaceFromJson(response.body);
        _marketplaceItems = paginatedResponse.results;
        _nextPageUrl = paginatedResponse.next;
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

  // Refresh marketplace items with cache-first strategy
  Future<void> refreshMarketplaceItems() async {
    // Prevent concurrent calls to avoid GetStorage file conflicts
    if (_isRefreshingMarketplace) {
      debugPrint("refreshMarketplaceItems already in progress, skipping duplicate call");
      return;
    }
    if (_isLoading) return;

    _isRefreshingMarketplace = true;

    try {
      final cacheKey = _generateCacheKey();

      // Try to load from cache first
        final cachedData = await _loadFromCache(cacheKey);
        if (cachedData != null) {
          // Show cached data IMMEDIATELY without setting loading state
          _marketplaceItems = List.from(cachedData.items);
          _nextPageUrl = cachedData.nextPageUrl;
          _error = null;
          _lastCacheKey = cacheKey;

          // Notify listeners first so UI updates instantly with cached data
          notifyListeners();

          debugPrint("Showing cached marketplace items, starting background refresh...");

          // ALWAYS refresh in background (no age check - indefinite cache strategy)
          _refreshInBackground(cacheKey);

          return;
        }

      // No cache available - fetch from API
      _isLoading = true;
      _error = null;
      _marketplaceItems = [];
      _nextPageUrl = null;
      notifyListeners();

      try {
        final url = _buildMarketplaceUrl();
        debugPrint("Fetching marketplace items from URL: $url");

        final response = await AppHttpClient.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
          },
          timeout: AppHttpClient.splashTimeout,
        );

        if (response.statusCode == 200) {
          debugPrint("Marketplace response body: ${response.body}");
          final PaginatedMarketplaceResponse paginatedResponse = paginatedMarketplaceFromJson(response.body);
          debugPrint("Parsed paginated response - count: ${paginatedResponse.count}");
          debugPrint("Parsed paginated response - results length: ${paginatedResponse.results.length}");
          _marketplaceItems = paginatedResponse.results;
          _nextPageUrl = paginatedResponse.next;
          debugPrint("Set _marketplaceItems length: ${_marketplaceItems.length}");

          // Save to cache
          final cacheData = CachedMarketplaceData(
            items: List.from(paginatedResponse.results),
            totalCount: paginatedResponse.count,
            nextPageUrl: paginatedResponse.next,
            timestamp: DateTime.now(),
            cacheKey: cacheKey,
          );
          await _saveToCache(cacheData);
          _lastCacheKey = cacheKey;

          notifyListeners();
        } else {
          _error = 'Failed to fetch marketplace items';
          debugPrint("Failed to fetch marketplace items: ${response.statusCode}");
        }
      } catch (e) {
        _error = e.toString();
        debugPrint("Error fetching marketplace items: $e");
      } finally {
        _isLoading = false;
        debugPrint("MarketplaceNotifier - Calling notifyListeners() with ${_marketplaceItems.length} items");
        notifyListeners();
      }
    } finally {
      _isRefreshingMarketplace = false;
    }
  }

  Future<void> loadMoreMarketplaceItems() async {
    if (_isLoadingMore || _nextPageUrl == null) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await AppHttpClient.get(
        Uri.parse(_nextPageUrl!),
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: AppHttpClient.splashTimeout,
      );

      if (response.statusCode == 200) {
        final PaginatedMarketplaceResponse paginatedResponse = paginatedMarketplaceFromJson(response.body);
        _marketplaceItems.addAll(paginatedResponse.results);
        _nextPageUrl = paginatedResponse.next;
      } else {
        debugPrint('Failed to load more marketplace items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading more marketplace items: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Fetch marketplace detail
  Future<MarketplaceDetailModel?> fetchMarketplaceDetail(String itemId) async {
    try {
      final url = '${Environment.baseUrl}/api/marketplace/$itemId/';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return MarketplaceDetailModel.fromJson(json.decode(response.body));
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Fetch user's marketplace listings
  Future<List<MarketplaceListModel>> fetchUserMarketplaceListings(String token) async {
    try {
      final url = '${Environment.baseUrl}/api/marketplace/my_listings/';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
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
          return [];
        }
        
        return results.map((item) => MarketplaceListModel.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
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
      
      final response = await http.delete(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 204) {
        onSuccess();
      } else {
        onError();
      }
    } catch (e) {
      onError();
    }
  }
} 