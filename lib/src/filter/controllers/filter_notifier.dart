import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/http_client.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'dart:convert';

// Cache data structure for storing filtered properties
class CachedPropertyData {
  final List<PropertyListModel> properties;
  final int totalCount;
  final String? nextPageUrl;
  final DateTime timestamp;
  final String cacheKey;

  CachedPropertyData({
    required this.properties,
    required this.totalCount,
    required this.nextPageUrl,
    required this.timestamp,
    required this.cacheKey,
  });

  bool get isExpired => DateTime.now().difference(timestamp) > FilterNotifier._cacheExpiry;

  Map<String, dynamic> toJson() => {
    'properties': properties.map((p) => p.toJson()).toList(),
    'totalCount': totalCount,
    'nextPageUrl': nextPageUrl,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'cacheKey': cacheKey,
  };

  factory CachedPropertyData.fromJson(Map<String, dynamic> json) {
    return CachedPropertyData(
      properties: (json['properties'] as List)
          .map((p) => PropertyListModel.fromJson(p))
          .toList(),
      totalCount: json['totalCount'],
      nextPageUrl: json['nextPageUrl'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      cacheKey: json['cacheKey'],
    );
  }
}

class FilterNotifier extends ChangeNotifier {
  RangeValues priceRange = const RangeValues(0, 50000);
  List<String> selectedBedrooms = [];
  List<String> selectedBathrooms = [];
  List<String> selectedSchools = [];
  DateTime? availableFrom;
  DateTime? availableTo;
  String _searchKey = '';
  String get searchKey => _searchKey;
  
  // Flexibility properties
  String dateFlexibility = "Exact dates";
  DateTime? actualFromDate;
  DateTime? actualToDate;

  // New state variables for property type and flatmate preferences
  List<String> selectedPropertyTypes = [];
  String smokingPreference = '';
  String partyingPreference = '';
  String dietaryPreference = '';
  String nationalityPreference = '';
  Map<String, bool> amenities = {};

  List<PropertyListModel> filteredProperties = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  String? nextPageUrl;
  int totalPropertiesCount = 0;
  String? errorMessage;
  
  // Caching mechanism
  final Map<String, CachedPropertyData> _cache = {};
  String? _lastCacheKey;
  bool _isRefreshing = false;
  
  // Cache data structure
  static const String _cacheKey = 'filtered_properties_cache';
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Location for proximity search with caching
  double? _latitude;
  double? _longitude;
  DateTime? _locationTimestamp;
  static const Duration _locationCacheExpiry = Duration(minutes: 30);
  
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  DateTime? get locationTimestamp => _locationTimestamp;
  
  // Set location for proximity search with caching
  void setLocation(double lat, double lng) {
    _latitude = lat;
    _longitude = lng;
    _locationTimestamp = DateTime.now();
    
    // Cache location data
    _cacheLocationData(lat, lng);
    notifyListeners();
  }
  
  // Cache location data for faster subsequent loads
  void _cacheLocationData(double lat, double lng) {
    try {
      final locationData = {
        'latitude': lat,
        'longitude': lng,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      final locationJson = jsonEncode(locationData);
      Storage().setString('cached_location', locationJson);
      debugPrint("Location data cached: $lat, $lng");
    } catch (e) {
      debugPrint("Failed to cache location: $e");
    }
  }
  
  // Load cached location data
  void _loadCachedLocation() {
    try {
      final locationJson = Storage().getString('cached_location');
      if (locationJson != null) {
        final locationData = jsonDecode(locationJson);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(locationData['timestamp']);
        
        // Only use cached location if it's not expired
        if (DateTime.now().difference(timestamp) < _locationCacheExpiry) {
          _latitude = locationData['latitude']?.toDouble();
          _longitude = locationData['longitude']?.toDouble();
          _locationTimestamp = timestamp;
          debugPrint("Loaded cached location: $_latitude, $_longitude");
        }
      }
    } catch (e) {
      debugPrint("Failed to load cached location: $e");
    }
  }
  
  // Initialize cached location on startup
  void initializeLocation() {
    _loadCachedLocation();
  }
  
  // Reset location data
  void resetLocation() {
    _latitude = null;
    _longitude = null;
    _locationTimestamp = null;
    notifyListeners();
  }

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
  
  void setDateFlexibility(String flexibility, DateTime? actualFrom, DateTime? actualTo) {
    dateFlexibility = flexibility;
    actualFromDate = actualFrom;
    actualToDate = actualTo;
    notifyListeners();
  }

  void setSearchKey(String key) {
    _searchKey = key;
    notifyListeners();
  }

  // New methods for property type and flatmate preferences
  void setPropertyTypes(List<String> types) {
    selectedPropertyTypes = types;
    notifyListeners();
  }

  void setSmokingPreference(String preference) {
    smokingPreference = preference;
    notifyListeners();
  }

  void setPartyingPreference(String preference) {
    partyingPreference = preference;
    notifyListeners();
  }

  void setDietaryPreference(String preference) {
    dietaryPreference = preference;
    notifyListeners();
  }

  void setNationalityPreference(String preference) {
    nationalityPreference = preference;
    notifyListeners();
  }

  void toggleAmenity(String amenity) {
    amenities[amenity] = !(amenities[amenity] ?? false);
    notifyListeners();
  }

  // Optimized URL building with parameter validation
  String _buildFilterUrl() {
    final baseUrl = "${Environment.baseUrl}/api/properties/?page_size=10";
    final queryParams = <String, String>{};

    // Add search parameter if available
    if (_searchKey.isNotEmpty && _searchKey != "Properties Near Me") {
      queryParams['search'] = _searchKey;
    }

    // Add location parameters if available
    if (_latitude != null && _longitude != null) {
      queryParams['latitude'] = _latitude.toString();
      queryParams['longitude'] = _longitude.toString();
    }

    // Add property types
    if (selectedPropertyTypes.isNotEmpty) {
      queryParams['property_type'] = selectedPropertyTypes.join(',');
    }

    // Add flatmate preferences
    if (smokingPreference.isNotEmpty) {
      queryParams['smoking'] = smokingPreference;
    }
    if (partyingPreference.isNotEmpty) {
      queryParams['partying'] = partyingPreference;
    }
    if (dietaryPreference.isNotEmpty) {
      queryParams['dietary'] = dietaryPreference;
    }
    if (nationalityPreference.isNotEmpty) {
      queryParams['nationality'] = nationalityPreference;
    }

    // Add amenities
    final selectedAmenities = amenities.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (selectedAmenities.isNotEmpty) {
      queryParams['amenities'] = selectedAmenities.join(',');
    }

    // Add price range
    if (priceRange.start > 0) {
      queryParams['min_rent'] = priceRange.start.toInt().toString();
    }
    if (priceRange.end < 50000) {
      queryParams['max_rent'] = priceRange.end.toInt().toString();
    }

    // Add other filters
    if (selectedBedrooms.isNotEmpty) {
      queryParams['bedrooms'] = selectedBedrooms.join(',');
    }
    if (selectedBathrooms.isNotEmpty) {
      queryParams['bathrooms'] = selectedBathrooms.join(',');
    }
    if (selectedSchools.isNotEmpty) {
      queryParams['schools'] = selectedSchools.join(',');
    }

    // Use actual dates for API filtering if flexibility is applied, otherwise use selected dates
    final filterFromDate = actualFromDate ?? availableFrom;
    final filterToDate = actualToDate ?? availableTo;
    
    if (filterFromDate != null) {
      queryParams['available_from'] = filterFromDate.toIso8601String().split('T')[0];
    }
    if (filterToDate != null) {
      queryParams['available_to'] = filterToDate.toIso8601String().split('T')[0];
    }
    
    // Build final URL efficiently
    if (queryParams.isEmpty) {
      return baseUrl;
    }
    
    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
    return uri.toString();
  }

  // Generate cache key based on current filter state
  String _generateCacheKey() {
    final buffer = StringBuffer();
    buffer.write('search:$_searchKey|');
    buffer.write('lat:$_latitude|lng:$_longitude|');
    buffer.write('price:${priceRange.start}-${priceRange.end}|');
    buffer.write('bedrooms:${selectedBedrooms.join(',')}|');
    buffer.write('bathrooms:${selectedBathrooms.join(',')}|');
    buffer.write('schools:${selectedSchools.join(',')}|');
    buffer.write('types:${selectedPropertyTypes.join(',')}|');
    buffer.write('smoking:$smokingPreference|');
    buffer.write('partying:$partyingPreference|');
    buffer.write('dietary:$dietaryPreference|');
    buffer.write('nationality:$nationalityPreference|');
    
    final selectedAmenities = amenities.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    buffer.write('amenities:${selectedAmenities.join(',')}|');
    
    final filterFromDate = actualFromDate ?? availableFrom;
    final filterToDate = actualToDate ?? availableTo;
    if (filterFromDate != null) {
      buffer.write('from:${filterFromDate.toIso8601String().split('T')[0]}|');
    }
    if (filterToDate != null) {
      buffer.write('to:${filterToDate.toIso8601String().split('T')[0]}|');
    }
    
    return buffer.toString();
  }

  // Cache management methods
  Future<void> _saveToCache(CachedPropertyData data) async {
    try {
      final cacheJson = jsonEncode(data.toJson());
      Storage().setString('${_cacheKey}_${data.cacheKey}', cacheJson);
      _cache[data.cacheKey] = data;
      debugPrint("Saved to cache: ${data.cacheKey}");
    } catch (e) {
      debugPrint("Failed to save cache: $e");
    }
  }

  Future<CachedPropertyData?> _loadFromCache(String cacheKey) async {
    try {
      // Check memory cache first
      if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
        debugPrint("Loaded from memory cache: $cacheKey");
        return _cache[cacheKey];
      }

      // Check disk cache
      final cacheJson = Storage().getString('${_cacheKey}_$cacheKey');
      if (cacheJson != null) {
        final data = CachedPropertyData.fromJson(jsonDecode(cacheJson));
        if (!data.isExpired) {
          _cache[cacheKey] = data;
          debugPrint("Loaded from disk cache: $cacheKey");
          return data;
        } else {
          // Remove expired cache
          await Storage().removeKey('${_cacheKey}_$cacheKey');
        }
      }
    } catch (e) {
      debugPrint("Failed to load cache: $e");
    }
    return null;
  }

  Future<void> _clearExpiredCache() async {
    try {
      final keys = _cache.keys.toList();
      for (final key in keys) {
        if (_cache[key]!.isExpired) {
          _cache.remove(key);
          await Storage().removeKey('${_cacheKey}_$key');
        }
      }
    } catch (e) {
      debugPrint("Failed to clear expired cache: $e");
    }
  }

  // Optimized applyFilters with caching and background refresh
  Future<void> applyFilters({bool forceRefresh = false}) async {
    if (isLoading && !forceRefresh) return;
    
    final cacheKey = _generateCacheKey();
    
    // Try to load from cache first (unless force refresh)
    if (!forceRefresh) {
      final cachedData = await _loadFromCache(cacheKey);
      if (cachedData != null) {
        filteredProperties = List.from(cachedData.properties);
        totalPropertiesCount = cachedData.totalCount;
        nextPageUrl = cachedData.nextPageUrl;
        isLoading = false;
        errorMessage = null;
        _lastCacheKey = cacheKey;
        notifyListeners();
        
        debugPrint("Loaded ${cachedData.properties.length} properties from cache");
        
        // Refresh in background if cache is getting stale
        if (DateTime.now().difference(cachedData.timestamp).inMinutes > 2) {
          _refreshInBackground(cacheKey);
        }
        return;
      }
    }
    
    // No cache available or force refresh - fetch from API
    isLoading = true;
    errorMessage = null;
    
    // Only clear properties if we don't have cached data to show
    if (filteredProperties.isEmpty || forceRefresh) {
      filteredProperties = [];
      nextPageUrl = null;
    }
    
    notifyListeners();

    try {
      final url = _buildFilterUrl();      
      debugPrint("Applying filters with URL: $url");

      final response = await AppHttpClient.getFast(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Parse the paginated response
        final PaginatedPropertiesResponse paginatedResponse = paginatedPropertiesFromJson(response.body);
        
        // Update properties and pagination info
        filteredProperties = paginatedResponse.results;
        totalPropertiesCount = paginatedResponse.count;
        nextPageUrl = paginatedResponse.next;
        
        debugPrint("Fetched ${paginatedResponse.results.length} filtered properties");
        debugPrint("Total filtered count: $totalPropertiesCount");
        debugPrint("Next page URL for filtered results: $nextPageUrl");
        
        // Save to cache
        final cacheData = CachedPropertyData(
          properties: List.from(paginatedResponse.results),
          totalCount: paginatedResponse.count,
          nextPageUrl: paginatedResponse.next,
          timestamp: DateTime.now(),
          cacheKey: cacheKey,
        );
        await _saveToCache(cacheData);
        _lastCacheKey = cacheKey;
        
        notifyListeners();
      } else {
        errorMessage = 'Failed to fetch properties: ${response.reasonPhrase}';
        debugPrint(errorMessage);
      }
    } catch (e) {
      errorMessage = 'An error occurred: $e';
      debugPrint(errorMessage);
    }

    isLoading = false;
    notifyListeners();
  }

  // Background refresh without blocking UI
  Future<void> _refreshInBackground(String cacheKey) async {
    if (_isRefreshing) return;
    
    _isRefreshing = true;
    debugPrint("Starting background refresh for cache key: $cacheKey");
    
    try {
      final url = _buildFilterUrl();
      final response = await AppHttpClient.getFast(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final PaginatedPropertiesResponse paginatedResponse = paginatedPropertiesFromJson(response.body);
        
        // Update cache with fresh data
        final cacheData = CachedPropertyData(
          properties: List.from(paginatedResponse.results),
          totalCount: paginatedResponse.count,
          nextPageUrl: paginatedResponse.next,
          timestamp: DateTime.now(),
          cacheKey: cacheKey,
        );
        await _saveToCache(cacheData);
        
        // Update current data if this is still the active filter
        if (_lastCacheKey == cacheKey) {
          filteredProperties = List.from(paginatedResponse.results);
          totalPropertiesCount = paginatedResponse.count;
          nextPageUrl = paginatedResponse.next;
          notifyListeners();
        }
        
        debugPrint("Background refresh completed for cache key: $cacheKey");
      }
    } catch (e) {
      debugPrint("Background refresh failed: $e");
    } finally {
      _isRefreshing = false;
    }
  }

  // Quick load method for initial app startup
  Future<void> quickLoad() async {
    debugPrint("Quick load initiated");
    await applyFilters();
  }

  Future<void> loadMoreFilteredProperties() async {
    if (isLoadingMore || nextPageUrl == null) {
      debugPrint("Skipping load more: isLoadingMore=$isLoadingMore, nextPageUrl=$nextPageUrl");
      return;
    }
    
    debugPrint("Loading more filtered properties from URL: $nextPageUrl");
    isLoadingMore = true;
    notifyListeners();
    
    try {
      final response = await AppHttpClient.get(
        Uri.parse(nextPageUrl!),
        headers: {
          'Content-Type': 'application/json',
        },
        timeout: AppHttpClient.splashTimeout,
      );

      if (response.statusCode == 200) {
        // Parse the paginated response
        final PaginatedPropertiesResponse paginatedResponse = paginatedPropertiesFromJson(response.body);
        
        // Add more properties to the existing list
        filteredProperties.addAll(paginatedResponse.results);
        debugPrint("Added ${paginatedResponse.results.length} more properties, total now: ${filteredProperties.length}");
        
        // Update pagination info
        nextPageUrl = paginatedResponse.next;
        debugPrint("Next page URL updated to: $nextPageUrl");
      } else {
        errorMessage = 'Failed to load more properties: ${response.reasonPhrase}';
        debugPrint(errorMessage);
      }
    } catch (e) {
      errorMessage = 'An error occurred: $e';
      debugPrint(errorMessage);
    }
    
    isLoadingMore = false;
    notifyListeners();
  }

  // Update resetFilters to include new filters
  void resetFilters() {
    priceRange = const RangeValues(0, 50000);
    selectedBedrooms = [];
    selectedBathrooms = [];
    selectedSchools = [];
    availableFrom = null;
    availableTo = null;
    dateFlexibility = "Exact dates";
    actualFromDate = null;
    actualToDate = null;
    selectedPropertyTypes = [];
    smokingPreference = '';
    partyingPreference = '';
    dietaryPreference = '';
    nationalityPreference = '';
    // Reset all amenities to false instead of clearing the map
    for (var key in amenities.keys.toList()) {
      amenities[key] = false;
    }
    notifyListeners();
  }

  void clearSearch() {
    _searchKey = '';
    notifyListeners();
  }

  void resetAll() {
    resetFilters();
    clearSearch();
    filteredProperties = [];
    nextPageUrl = null;
    totalPropertiesCount = 0;
  }

  // Method to initialize filtered properties from property notifier (used when no filters are applied)
  void initializeFromProperties(List<PropertyListModel> properties, int totalCount, String? nextPage) {
    filteredProperties = List.from(properties);
    totalPropertiesCount = totalCount;
    nextPageUrl = nextPage;
    isLoading = false;
    notifyListeners();
    debugPrint("FilterNotifier: Initialized with ${properties.length} properties from PropertyNotifier");
  }

  // Clear all cache data
  Future<void> clearCache() async {
    try {
      _cache.clear();
      // Clear all cache keys from storage
      final storageInfo = Storage().getStorageInfo();
      final keys = storageInfo['keys'] as List<String>? ?? [];
      for (final key in keys) {
        if (key.startsWith(_cacheKey)) {
          await Storage().removeKey(key);
        }
      }
      debugPrint("Cache cleared successfully");
    } catch (e) {
      debugPrint("Failed to clear cache: $e");
    }
  }

  // Initialize cache on startup
  Future<void> initializeCache() async {
    await _clearExpiredCache();
    debugPrint("Cache initialized and expired entries cleared");
  }
}