import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:marketplace_app/common/services/google_cloud_storage_service.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MarketplaceServiceV2 {
  static String get backendUrl => '${Environment.baseUrl}/api/marketplace/';

  /// Create a marketplace item with images uploaded to Google Cloud Storage
  static Future<Map<String, dynamic>> createMarketplaceItem({
    required Map<String, dynamic> marketplaceData,
    required List<File> images,
    required String userId,
    Function(double)? onProgress,
  }) async {
    debugPrint('Starting createMarketplaceItem method...');
    final String? accessToken = Storage().getString('accessToken');
    debugPrint('Access token: $accessToken');
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('Access token is null or empty. Aborting marketplace item creation.');
      throw Exception('No access token found');
    }
    debugPrint('Access token found');
    debugPrint('User ID: $userId');

    // Upload images to Google Cloud Storage
    List<String> imageUrls = [];
    if (images.isNotEmpty) {
      debugPrint('Creating marketplace item with ${images.length} images...');
      debugPrint('Uploading images to Google Cloud Storage...');
      imageUrls = await GoogleCloudStorageService.uploadImages(
        imageFiles: images,
        folder: 'marketplace',
        userId: userId,
        onProgress: onProgress,
      );
      debugPrint('Successfully uploaded ${imageUrls.length} images');
      debugPrint('Image URLs: $imageUrls');
    } else {
      debugPrint('Creating marketplace item with 0 images...');
      debugPrint('No images to upload');
    }

    // Add image URLs to marketplace data
    marketplaceData['image_urls'] = imageUrls;

    debugPrint('Sending marketplace data to backend...');
    debugPrint('Backend URL: $backendUrl');
    debugPrint('Marketplace data: ${jsonEncode(marketplaceData)}');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $accessToken',
    };
    debugPrint('Headers: $headers');
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: headers,
      body: jsonEncode(marketplaceData),
    );

    debugPrint('Backend response status: ${response.statusCode}');
    debugPrint('Backend response body: ${response.body}');

    if (response.statusCode == 201) {
      debugPrint('Marketplace item created successfully');
      return jsonDecode(response.body);
    } else {
      debugPrint('Failed to create marketplace item');
      throw Exception('Failed to create marketplace item: ${response.body}');
    }
  }

  /// Update a marketplace item with images uploaded to Google Cloud Storage
  static Future<Map<String, dynamic>> updateMarketplaceItem({
    required String itemId,
    required Map<String, dynamic> marketplaceData,
    required List<File> images,
    required String userId,
    Function(double)? onProgress,
  }) async {
    debugPrint('Starting updateMarketplaceItem method...');
    final String? accessToken = Storage().getString('accessToken');
    debugPrint('Access token: $accessToken');
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('Access token is null or empty. Aborting marketplace item update.');
      throw Exception('No access token found');
    }
    debugPrint('Access token found');
    debugPrint('User ID: $userId');
    debugPrint('Item ID: $itemId');

    // Upload images to Google Cloud Storage
    List<String> imageUrls = [];
    if (images.isNotEmpty) {
      debugPrint('Updating marketplace item with ${images.length} images...');
      debugPrint('Uploading images to Google Cloud Storage...');
      imageUrls = await GoogleCloudStorageService.uploadImages(
        imageFiles: images,
        folder: 'marketplace',
        userId: userId,
        itemId: itemId,
        onProgress: onProgress,
      );
      debugPrint('Successfully uploaded ${imageUrls.length} images');
      debugPrint('Image URLs: $imageUrls');
    } else {
      debugPrint('Updating marketplace item with 0 images...');
      debugPrint('No images to upload');
    }

    // Add image URLs to marketplace data
    marketplaceData['image_urls'] = imageUrls;

    debugPrint('Sending marketplace update data to backend...');
    final updateUrl = '$backendUrl$itemId/';
    debugPrint('Backend URL: $updateUrl');
    debugPrint('Marketplace data: ${jsonEncode(marketplaceData)}');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $accessToken',
    };
    debugPrint('Headers: $headers');
    final response = await http.put(
      Uri.parse(updateUrl),
      headers: headers,
      body: jsonEncode(marketplaceData),
    );

    debugPrint('Backend response status: ${response.statusCode}');
    debugPrint('Backend response body: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('Marketplace item updated successfully');
      return jsonDecode(response.body);
    } else {
      debugPrint('Failed to update marketplace item');
      throw Exception('Failed to update marketplace item: ${response.body}');
    }
  }
} 