import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:googleapis_auth/auth_io.dart';
import 'package:marketplace_app/common/utils/environment.dart';

class GoogleCloudStorageService {
  static const String _bucketName = 'homiswap-images';
  static const String _baseUrl = 'https://storage.googleapis.com';
  
  // Service account credentials - Load from environment or secure storage
  static Map<String, dynamic>? _serviceAccountCredentials;
  
  static Future<Map<String, dynamic>> _getServiceAccountCredentials() async {
    if (_serviceAccountCredentials != null) {
      return _serviceAccountCredentials!;
    }
    
    try {
      // Load credentials from environment variables
      final credentialsJson = Environment.googleCloudServiceAccount;
      
      if (credentialsJson.isEmpty || credentialsJson == 'GOOGLE_CLOUD_SERVICE_ACCOUNT not found') {
        throw Exception('Google Cloud Service Account credentials not found in environment variables');
      }
      
      debugPrint('Loading Google Cloud credentials from environment...');
      
      // Clean and parse the JSON credentials
      // Replace literal \n with actual newlines for proper JSON parsing
      final cleanedJson = credentialsJson.replaceAll('\\n', '\n');
      final credentials = json.decode(cleanedJson) as Map<String, dynamic>;
      
      debugPrint('Successfully parsed Google Cloud credentials');
      
      // Cache the credentials
      _serviceAccountCredentials = credentials;
      
      return credentials;
    } catch (e) {
      debugPrint('Error loading Google Cloud credentials: $e');
      // Don't log the raw credentials for security
      debugPrint('Failed to parse Google Cloud credentials from environment');
      rethrow;
    }
  }

  /// Get authenticated HTTP client
  static Future<AuthClient> _getAuthenticatedClient() async {
    try {
      debugPrint('Getting authenticated client...');
      
      final credentials = await _getServiceAccountCredentials();
      final serviceAccountCredentials = ServiceAccountCredentials.fromJson(credentials);
      const scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      
      final client = await clientViaServiceAccount(serviceAccountCredentials, scopes);
      debugPrint('Authentication successful');
      return client;
    } catch (e) {
      debugPrint('Authentication failed: $e');
      rethrow;
    }
  }
  
  /// Upload images directly to Google Cloud Storage
  /// Returns list of public URLs of uploaded images
  static Future<List<String>> uploadImages({
    required List<File> imageFiles,
    required String folder, // 'properties', 'marketplace', 'profiles'
    required String userId,
    String? itemId,
    Function(double)? onProgress,
  }) async {
    AuthClient? authClient;
    try {
      debugPrint('Starting uploadImages with ${imageFiles.length} files');
      
      // Get authenticated client
      authClient = await _getAuthenticatedClient();
      
      List<String> uploadedUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        debugPrint('Processing image ${i + 1}/${imageFiles.length}');
        File imageFile = imageFiles[i];
        
        // Generate unique filename
        String fileName = _generateFileName(
          folder: folder,
          userId: userId,
          itemId: itemId,
          originalName: path.basename(imageFile.path),
          index: i,
        );
        debugPrint('Generated filename: $fileName');
        
        // Upload single image
        debugPrint('Starting upload for image ${i + 1}');
        String? uploadedUrl = await _uploadSingleImage(
          imageFile: imageFile,
          fileName: fileName,
          authClient: authClient,
          onProgress: (progress) {
            if (onProgress != null) {
              // Calculate overall progress
              double overallProgress = (i + progress) / imageFiles.length;
              onProgress(overallProgress);
            }
          },
        );
        
        debugPrint('Upload result for image ${i + 1}: ${uploadedUrl != null ? 'SUCCESS' : 'FAILED'}');
        
        if (uploadedUrl != null) {
          uploadedUrls.add(uploadedUrl);
          debugPrint('Uploaded: $fileName -> $uploadedUrl');
        } else {
          debugPrint('Failed to upload: ${path.basename(imageFile.path)}');
          throw Exception('Failed to upload: ${path.basename(imageFile.path)}');
        }
      }
      
      debugPrint('All uploads completed successfully! Total URLs: ${uploadedUrls.length}');
      return uploadedUrls;
      
    } catch (e) {
      debugPrint('Error uploading images: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      rethrow;
    } finally {
      // Close the authenticated client
      authClient?.close();
    }
  }
  
  /// Upload a single image file to Google Cloud Storage
  static Future<String?> _uploadSingleImage({
    required File imageFile,
    required String fileName,
    required AuthClient authClient,
    Function(double)? onProgress,
  }) async {
    try {
      debugPrint('Starting upload for: $fileName');
      
      // Validate file
      if (!await _validateFile(imageFile)) {
        debugPrint('File validation failed: ${path.basename(imageFile.path)}');
        throw Exception('Invalid file: ${path.basename(imageFile.path)}');
      }
      debugPrint('File validation passed');
      
      // Create upload URL
      String uploadUrl = '$_baseUrl/upload/storage/v1/b/$_bucketName/o?uploadType=media&name=$fileName';
      debugPrint('Upload URL: $uploadUrl');
      
      // Read file bytes
      final fileBytes = await imageFile.readAsBytes();
      final totalBytes = fileBytes.length;
      debugPrint('File size: ${totalBytes} bytes');
      
      // Create authenticated request
      var request = http.Request('POST', Uri.parse(uploadUrl));
      
      // Set headers
      request.headers['Content-Type'] = _getContentType(imageFile.path);
      request.headers['Content-Length'] = totalBytes.toString();
      
      // Add authorization header from authenticated client
      request.headers['Authorization'] = 'Bearer ${authClient.credentials.accessToken.data}';
      
      debugPrint('Headers set: ${request.headers}');
      
      // Set body
      request.bodyBytes = fileBytes;
      
      // Report 100% progress since we're using bodyBytes (not streaming)
      if (onProgress != null) {
        onProgress(1.0);
      }
      
      debugPrint('Sending request to Google Cloud Storage...');
      
      // Send request using authenticated client
      final response = await authClient.send(request);
      
      debugPrint('Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        // Return public URL
        String publicUrl = 'https://storage.googleapis.com/$_bucketName/$fileName';
        debugPrint('Upload successful: $publicUrl');
        return publicUrl;
      } else {
        final responseBody = await response.stream.bytesToString();
        debugPrint('Upload failed: ${response.statusCode} - $responseBody');
        return null;
      }
      
    } catch (e) {
      debugPrint('Error uploading single image: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return null;
    }
  }
  
  /// Generate unique filename for the image
  static String _generateFileName({
    required String folder,
    required String userId,
    String? itemId,
    required String originalName,
    required int index,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = path.extension(originalName).toLowerCase();
    
    String baseName;
    if (itemId != null) {
      baseName = '${userId}_${itemId}_${index}_$timestamp';
    } else {
      baseName = '${userId}_${index}_$timestamp';
    }
    
    return '$folder/$baseName$extension';
  }
  
  /// Validate file before upload
  static Future<bool> _validateFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        debugPrint('File does not exist: ${file.path}');
        return false;
      }
      
      // Check file size (max 5MB)
      const int maxFileSizeBytes = 5 * 1024 * 1024;
      final fileSize = await file.length();
      if (fileSize > maxFileSizeBytes) {
        debugPrint('File too large: ${fileSize / (1024 * 1024)}MB');
        return false;
      }
      
      // Check file extension
      const List<String> allowedExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
      final extension = path.extension(file.path).toLowerCase();
      if (!allowedExtensions.contains(extension)) {
        debugPrint('Invalid file extension: $extension');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('Error validating file: $e');
      return false;
    }
  }
  
  /// Get content type based on file extension
  static String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
  
  /// Delete images from Google Cloud Storage (for future use)
  static Future<bool> deleteImages(List<String> imageUrls) async {
    try {
      // This would require authentication - implement when needed
      // For now, just return true as images will be overwritten
      debugPrint('Delete images: $imageUrls');
      return true;
    } catch (e) {
      debugPrint('Error deleting images: $e');
      return false;
    }
  }
} 