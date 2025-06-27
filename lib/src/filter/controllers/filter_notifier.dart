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
  String _searchKey = '';
  String get searchKey => _searchKey;

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

  // Location for proximity search
  double? _latitude;
  double? _longitude;
  
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  
  // Set location for proximity search
  void setLocation(double lat, double lng) {
    _latitude = lat;
    _longitude = lng;
    notifyListeners();
  }
  
  // Reset location data
  void resetLocation() {
    _latitude = null;
    _longitude = null;
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

  // Update _buildFilterUrl to include new filters
  String _buildFilterUrl() {
    String url = "${Environment.iosAppBaseUrl}/api/properties/?";

    // Add search parameter if available
    if (_searchKey.isNotEmpty && _searchKey != "Properties Near Me") {
      url += "search=$_searchKey&";
    }

    // Add location parameters if available
    if (_latitude != null && _longitude != null) {
      url += "latitude=$_latitude&longitude=$_longitude&";
    }

    // Add property types
    if (selectedPropertyTypes.isNotEmpty) {
      url += "property_type=${selectedPropertyTypes.join(',')}&";
    }

    // Add flatmate preferences
    if (smokingPreference.isNotEmpty) {
      url += "smoking=$smokingPreference&";
    }
    if (partyingPreference.isNotEmpty) {
      url += "partying=$partyingPreference&";
    }
    if (dietaryPreference.isNotEmpty) {
      url += "dietary=$dietaryPreference&";
    }
    if (nationalityPreference.isNotEmpty) {
      url += "nationality=$nationalityPreference&";
    }

    // Add amenities
    List<String> selectedAmenities = amenities.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
    if (selectedAmenities.isNotEmpty) {
      url += "amenities=${selectedAmenities.join(',')}&";
    }

    // Add price range
    if (priceRange.start > 0) {
      url += "min_rent=${priceRange.start.toInt()}&";
    }
    if (priceRange.end < 50000) {
      url += "max_rent=${priceRange.end.toInt()}&";
    }

    // Add other filters
    if (selectedBedrooms.isNotEmpty) {
      url += "bedrooms=${selectedBedrooms.join(',')}&";
    }
    if (selectedBathrooms.isNotEmpty) {
      url += "bathrooms=${selectedBathrooms.join(',')}&";
    }
    if (selectedSchools.isNotEmpty) {
      url += "schools=${selectedSchools.join(',')}&";
    }
    if (availableFrom != null) {
      url += "available_from=${availableFrom!.toIso8601String().split('T')[0]}&";
    }
    if (availableTo != null) {
      url += "available_to=${availableTo!.toIso8601String().split('T')[0]}&";
    }
    
    return url;
  }

  Future<void> applyFilters(BuildContext context) async {
    if (isLoading) return;
    
    isLoading = true;
    errorMessage = null;
    filteredProperties = [];
    nextPageUrl = null;
    
    notifyListeners();

    try {
      String url = _buildFilterUrl();      
      debugPrint("Applying filters with URL: $url");

      final response = await http.get(Uri.parse(url));

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
        
        notifyListeners();
        context.go('/home');
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

  Future<void> loadMoreFilteredProperties() async {
    if (isLoadingMore || nextPageUrl == null) {
      debugPrint("Skipping load more: isLoadingMore=$isLoadingMore, nextPageUrl=$nextPageUrl");
      return;
    }
    
    debugPrint("Loading more filtered properties from URL: $nextPageUrl");
    isLoadingMore = true;
    notifyListeners();
    
    try {
      final response = await http.get(Uri.parse(nextPageUrl!));

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
}