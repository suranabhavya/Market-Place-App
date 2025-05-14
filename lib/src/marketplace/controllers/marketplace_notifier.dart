import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';

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

  bool get isLoading => _isLoading;
  String get searchKey => _searchKey;
  List<MarketplaceListModel> get marketplaceItems => _marketplaceItems;
  List<PropertyListItem> get userProperties => _userProperties;
  String? get error => _error;

  void setSearchKey(String value) {
    _searchKey = value;
    notifyListeners();
  }

  void clearSearch() {
    _searchKey = '';
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
      debugPrint("Fetching items from URL: $url");
      final response = await http.get(
        Uri.parse(url),
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
      var request = http.MultipartRequest("POST", Uri.parse(apiUrl));
      request.headers['Authorization'] = 'Token $token';

      // Handle images
      List<String>? imagePaths = marketplaceData['images'] as List<String>?;
      if (imagePaths != null && imagePaths.isNotEmpty) {
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
      request.fields['original_price'] = marketplaceData['original_price'].toString();
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

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        onSuccess();
      } else {
        debugPrint('Failed to create marketplace item: $responseBody');
        onError();
      }
    } catch (e) {
      debugPrint('Error creating marketplace item: $e');
      onError();
    }
  }
} 