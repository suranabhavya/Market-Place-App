import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:googleapis_auth/auth_io.dart';

class GoogleCloudStorageService {
  static const String _bucketName = 'homiswap-images';
  static const String _baseUrl = 'https://storage.googleapis.com';
  
  // Service account credentials - Replace with your actual credentials
  static const Map<String, dynamic> _serviceAccountCredentials = {
    "type": "service_account",
    "project_id": "homiswap-backend",
    "private_key_id": "800839bc59d5a397cec6985139903e23988a456d",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDRoWoM8gQCcwjJ\n4C1CeZSuBMVogeAj8qV2W/uuLJjPuG+XOfXcAL3HebT1lG10YjlxJJdjHI6ykxKw\numc17KcVadVqhyFxAejw8HuZUyQhfVKI0TFQc1sDbM5Ei/wqIHIaXz0HKkuhH2oC\nE47N94lxCB9Z9PAjJiNg6NXXvZSeiLkfnbvGtDmFSqLyVx3JJj7vRfZwIy9Mqm4b\n/j2DK+StaQ1s5ivtpfmYlhyKTVOoIhR7RYpMV593mk6OLMgrXR1kWbWMw3/C/AOR\n+j/4jPmmCvppm3BZ5UMB6o1VhhK3FHYjdtpnrSeV9oafEpj7HehIpOzZtQnHaQnt\nzUhEbCHZAgMBAAECggEAXae3SRxQ9UUujn6UyeemqM5h4cxwdq8ABG6Y9VpgVSFJ\n3a7b7FP6daWm1rbe5cnCbw2RgwqtqBN0HLfSx7E4fqUfX24K30GisA5IshoGgN3M\nI2sOlKpM5a1VRCOkX6/KOoUFL2/ShSQTSOUy/ksSwQiHdTmslY+C69dqPm4o+WA9\n4pUh178U9efOvKsVu2/fLJD7Yht3r+m8F+hLsD3BTjap6egJKNJ65O5kJzAypwZC\nxBykAD5RWdQoab/HnfZMa0daQYE1Fvf5ZE1f0KjSLqyTk4Pm1RoAfDgq+q9xQFZG\nbkumZif/JDrwsKLSoj6+jUEGfmK+ewsLTI4u3MZxZwKBgQDxrAwffHfmPQZHl1ep\nhlYeSObboIyurockajRfMdEVZXyTHtDM5kdrspFda9QpC88jEUAsQyT9fO//hy2p\nmtPH4HnIWv5TLUyn4Q6/8iMcrQoAaaASabAmdTQmqFHb5qLkNvjaeVjBYw9echtj\n15z4oR68NFhVvSfBtYFkcnxozwKBgQDeDw9QWLlXAK//vSJqSOAmESFj9Os2vxix\n/gbiAdSSt1yqohJ+e+8eacletK0TsUT1vSPgS37eiLsjMYo0dKwYGfStsoLzkWeS\nhtp+Sgmb/ypkN6M/rXrbMQCjjIEvvQq/CeiLStxzjoBqNpinq9OARxNx5eqVEHim\nir3htF0k1wKBgH2PyBSr1Je46QRVK2SWuTOu6NL/TViMsQZIb8Ft3pXhTqIZhp6O\nnljkRAZnualBy3MKyW61zAgv23nFwAG4wYO9q0hfjnekt4kZs1Ii+f8yIFoqhtJK\nOw0gI+JZ3X4FDGjJ7u2D0otXbmrBml17bsD25UMfZy3Uw00vgnSvztedAoGAVxUm\n10aEIJd3bd5ZMb80kBkltBJnb8fPQnYxcs5u876Oy6fVgt7Nbmrj+oz2VwOs3IX5\nHMvejByo7utNnLaoiqcbKkcYTbaXHIJgCyizzgZqNHURQzagOHdmHb1LKFKFdVfI\nZ1/LRlH7ECwq/45F2keFW6Rjs2OLPRypzGq0IG8CgYB6hCUYNFM1RTzgOrE+hY5M\ns7yCUOBgJ7iaaCLDag3j4OvVYgvZ50KoekUvKPhwj/Hv4pQD3fT2R5JyaYwvf7DS\nePWortTF9nmNQv9+5vqwlFU2SwjlpOiPKPwdfxTeolUn9I/FA5khzj0O3q2jVtn0\nFqS+ztUPFYIXDkc8G9JvBg==\n-----END PRIVATE KEY-----\n",
    "client_email": "homiswap-storage-service@homiswap-backend.iam.gserviceaccount.com",
    "client_id": "105868636728282697486",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/homiswap-storage-service%40homiswap-backend.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  };

  /// Get authenticated HTTP client
  static Future<AuthClient> _getAuthenticatedClient() async {
    try {
      debugPrint('Getting authenticated client...');
      
      final credentials = ServiceAccountCredentials.fromJson(_serviceAccountCredentials);
      const scopes = ['https://www.googleapis.com/auth/cloud-platform'];
      
      final client = await clientViaServiceAccount(credentials, scopes);
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