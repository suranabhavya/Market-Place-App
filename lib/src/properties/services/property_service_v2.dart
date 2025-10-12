import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:marketplace_app/common/services/google_cloud_storage_service.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PropertyServiceV2 {
  static String get backendUrl => '${Environment.baseUrl}/api/properties/';

  /// Create a property with images uploaded to Google Cloud Storage
  static Future<Map<String, dynamic>> createProperty({
    required Map<String, dynamic> propertyData,
    required List<File> images,
    required String userId,
    Function(double)? onProgress,
  }) async {
    debugPrint('Starting createProperty method...');
    final String? accessToken = Storage().getString('accessToken');
    debugPrint('Access token: '
        ' [33m$accessToken [0m'); // Highlighted in yellow for visibility
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('Access token is null or empty. Aborting property creation.');
      throw Exception('No access token found');
    }
    debugPrint('Access token found');
    debugPrint('User ID: $userId');

    // Upload images to Google Cloud Storage
    List<String> imageUrls = [];
    if (images.isNotEmpty) {
      debugPrint('Creating property with ${images.length} images...');
      debugPrint('Uploading images to Google Cloud Storage...');
      imageUrls = await GoogleCloudStorageService.uploadImages(
        imageFiles: images,
        folder: 'properties',
        userId: userId,
        onProgress: onProgress,
      );
      debugPrint('Successfully uploaded ${imageUrls.length} images');
      debugPrint('Image URLs: $imageUrls');
    } else {
      debugPrint('Creating property with 0 images...');
      debugPrint('No images to upload');
    }

    // Add image URLs to property data
    propertyData['image_urls'] = imageUrls;

    debugPrint('Sending property data to backend...');
    debugPrint('Backend URL: $backendUrl');
    debugPrint('Property data: ${jsonEncode(propertyData)}');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $accessToken',
    };
    debugPrint('Headers: $headers');
    final response = await http.post(
      Uri.parse(backendUrl),
      headers: headers,
      body: jsonEncode(propertyData),
    );

    debugPrint('Backend response status: ${response.statusCode}');
    debugPrint('Backend response body: ${response.body}');

    if (response.statusCode == 201) {
      debugPrint('Property created successfully');
      return jsonDecode(response.body);
    } else {
      debugPrint('Failed to create property');
      throw Exception('Failed to create property: ${response.body}');
    }
  }

  /// Update a property with images uploaded to Google Cloud Storage
  static Future<Map<String, dynamic>> updateProperty({
    required String propertyId,
    required Map<String, dynamic> propertyData,
    required List<File> images,
    required String userId,
    List<String>? deletedImages,
    Function(double)? onProgress,
  }) async {
    debugPrint('Starting updateProperty method...');
    final String? accessToken = Storage().getString('accessToken');
    debugPrint('Access token: $accessToken');
    if (accessToken == null || accessToken.isEmpty) {
      debugPrint('Access token is null or empty. Aborting property update.');
      throw Exception('No access token found');
    }
    debugPrint('Access token found');
    debugPrint('User ID: $userId');
    debugPrint('Property ID: $propertyId');

    // Upload images to Google Cloud Storage
    List<String> imageUrls = [];
    if (images.isNotEmpty) {
      debugPrint('Updating property with ${images.length} images...');
      debugPrint('Uploading images to Google Cloud Storage...');
      imageUrls = await GoogleCloudStorageService.uploadImages(
        imageFiles: images,
        folder: 'properties',
        userId: userId,
        itemId: propertyId,
        onProgress: onProgress,
      );
      debugPrint('Successfully uploaded ${imageUrls.length} images');
      debugPrint('Image URLs: $imageUrls');
    } else {
      debugPrint('Updating property with 0 images...');
      debugPrint('No images to upload');
    }

    // Add image URLs to property data
    propertyData['image_urls'] = imageUrls;

    // Add deleted images if any
    if (deletedImages != null && deletedImages.isNotEmpty) {
      propertyData['deleted_images'] = deletedImages;
      debugPrint('Deleted images: $deletedImages');
    }

    debugPrint('Sending property update data to backend...');
    final updateUrl = '$backendUrl$propertyId/';
    debugPrint('Backend URL: $updateUrl');
    debugPrint('Property data: ${jsonEncode(propertyData)}');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Token $accessToken',
    };
    debugPrint('Headers: $headers');
    final response = await http.put(
      Uri.parse(updateUrl),
      headers: headers,
      body: jsonEncode(propertyData),
    );

    debugPrint('Backend response status: ${response.statusCode}');
    debugPrint('Backend response body: ${response.body}');

    if (response.statusCode == 200) {
      debugPrint('Property updated successfully');
      return jsonDecode(response.body);
    } else {
      debugPrint('Failed to update property');
      throw Exception('Failed to update property: ${response.body}');
    }
  }
} 