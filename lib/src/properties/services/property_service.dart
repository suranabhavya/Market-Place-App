import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/properties/models/property_detail_model.dart';
import 'package:marketplace_app/src/properties/models/property_edit_model.dart';
import 'package:path/path.dart' as path;

class PropertyService {
  static Future<Map<String, dynamic>> fetchProperty(String propertyId) async {
    final accessToken = Storage().getString('accessToken');
    if (accessToken == null) {
      throw Exception("Authentication required");
    }

    final response = await http.get(
      Uri.parse('${Environment.iosAppBaseUrl}/api/properties/$propertyId/'),
      headers: {'Authorization': 'Token $accessToken'},
    );

    if (response.statusCode == 200) {
      String responseBody = utf8.decode(response.bodyBytes);
      return json.decode(responseBody);
    } else {
      throw Exception("Failed to load property details: ${response.statusCode}");
    }
  }

  static Future<void> updateProperty(String propertyId, Map<String, dynamic> updatedData) async {
    String? accessToken = Storage().getString('accessToken');
    if (accessToken == null) {
      throw Exception("Authentication required");
    }

    var request = http.MultipartRequest(
      "PUT",
      Uri.parse('${Environment.iosAppBaseUrl}/api/properties/$propertyId/'),
    );
    request.headers['Authorization'] = 'Token $accessToken';

    // Handle new images
    List<String>? imagePaths = updatedData['images'] as List<String>?;
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

    // Handle deleted images
    // if (updatedData['deletedImages'] != null && updatedData['deletedImages']!.isNotEmpty) {
    //   print("property.deletedImages: ${updatedData['deletedImages']}");
    //   List<String> nonPlaceholderIds = property.deletedImages!
    //       .where((id) => !id.startsWith('placeholder_'))
    //       .toList();
    //   if (nonPlaceholderIds.isNotEmpty) {
    //     request.fields['deleted_images'] = json.encode(nonPlaceholderIds);
    //   }
    // }

    // Add all other fields
    // final propertyData = property.toJson();
    updatedData.forEach((key, value) {
      if (value != null) {
        if (value is Map || value is List) {
          request.fields[key] = json.encode(value);
          print("request.fields: $key: "+json.encode(value));
        } else {
          request.fields[key] = value.toString();
          print("request.fields: $key: ${value.toString()}");
        }
      }
    });

    var response = await request.send();
    var responseData = await http.Response.fromStream(response);

    print("responseData: ${responseData.body}");

    if (response.statusCode != 200) {
      String errorBody = utf8.decode(responseData.bodyBytes);
      throw Exception("Failed to update property: ${response.statusCode}\nError: $errorBody");
    }
  }

  static Future<void> createProperty(PropertyDetailModel property) async {
    String? accessToken = Storage().getString('accessToken');
    if (accessToken == null) {
      throw Exception("Authentication required");
    }

    var request = http.MultipartRequest(
      "POST",
      Uri.parse('${Environment.iosAppBaseUrl}/api/properties/'),
    );
    request.headers['Authorization'] = 'Token $accessToken';

    // Handle images
    if (property.images != null && property.images!.isNotEmpty) {
      for (var imagePath in property.images!) {
        File imageFile = File(imagePath.url);
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            imageFile.path,
            filename: path.basename(imageFile.path),
          ),
        );
      }
    }

    // Add all other fields
    final propertyData = property.toJson();
    propertyData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    var response = await request.send();
    var responseData = await http.Response.fromStream(response);

    if (response.statusCode != 201) {
      String errorBody = utf8.decode(responseData.bodyBytes);
      throw Exception("Failed to create property: ${response.statusCode}\nError: $errorBody");
    }
  }
} 