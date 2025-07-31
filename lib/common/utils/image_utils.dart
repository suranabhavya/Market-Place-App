import 'dart:io';
import 'package:flutter/material.dart';

/// Utility class for handling image providers that can work with both local files and network URLs
class ImageUtils {
  /// Creates an image provider that handles both local files and network URLs
  static ImageProvider? getImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    
    try {
      // Check if it's a local file path
      if (imageUrl.startsWith('file://') || imageUrl.startsWith('/')) {
        return FileImage(File(imageUrl.replaceFirst('file://', '')));
      }
      // Check if it's a network URL
      else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return NetworkImage(imageUrl);
      }
      // If it's neither, return null to show default icon
      return null;
    } catch (e) {
      debugPrint('Error creating image provider: $e');
      return null;
    }
  }

  /// Checks if an image URL is valid and can be displayed
  static bool isValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;
    
    try {
      // Check if it's a local file path
      if (imageUrl.startsWith('file://') || imageUrl.startsWith('/')) {
        return File(imageUrl.replaceFirst('file://', '')).existsSync();
      }
      // Check if it's a network URL
      else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        return true; // Assume network URLs are valid
      }
      return false;
    } catch (e) {
      debugPrint('Error validating image URL: $e');
      return false;
    }
  }
} 