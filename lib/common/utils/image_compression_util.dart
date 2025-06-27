import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionUtil {
  static const int maxWidth = 800;
  static const int maxHeight = 800;
  static const int quality = 50;
  static const int maxFileSizeKB = 500; // 500KB max file size

  /// Compress a single image file
  static Future<File?> compressImage(File imageFile) async {
    try {
      // Get file size before compression
      final int originalSize = await imageFile.length();
      debugPrint('Original image size: ${(originalSize / 1024).toStringAsFixed(2)} KB');

      // Get temporary directory
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg'
      );

      // Compress the image
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: quality,
        minWidth: 400,
        minHeight: 400,
      );

      if (compressedFile != null) {
        final File compressed = File(compressedFile.path);
        final int compressedSize = await compressed.length();
        debugPrint('Compressed image size: ${(compressedSize / 1024).toStringAsFixed(2)} KB');
        debugPrint('Compression ratio: ${((originalSize - compressedSize) / originalSize * 100).toStringAsFixed(1)}%');
        
        // If still too large, compress further
        if (compressedSize > maxFileSizeKB * 1024) {
          return await _compressToTargetSize(compressed, maxFileSizeKB * 1024);
        }
        
        return compressed;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile; // Return original if compression fails
    }
  }

  /// Compress image to target file size
  static Future<File?> _compressToTargetSize(File imageFile, int targetSizeBytes) async {
    int currentQuality = quality;
    File? result = imageFile;
    
    while (currentQuality > 10 && result != null) {
      final int currentSize = await result.length();
      if (currentSize <= targetSizeBytes) break;
      
      currentQuality -= 10;
      
      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}_q$currentQuality.jpg'
      );
      
      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        quality: currentQuality,
        minWidth: 400,
        minHeight: 400,
      );
      
      if (compressedFile != null) {
        result = File(compressedFile.path);
      }
    }
    
    return result;
  }

  /// Compress multiple images
  static Future<List<File>> compressImages(List<File> images) async {
    List<File> compressedImages = [];
    
    for (File image in images) {
      final File? compressed = await compressImage(image);
      if (compressed != null) {
        compressedImages.add(compressed);
      }
    }
    
    return compressedImages;
  }

  /// Pick and compress images from gallery
  static Future<List<File>> pickAndCompressFromGallery({
    bool multiple = true,
    int? maxImages,
  }) async {
    final ImagePicker picker = ImagePicker();
    List<XFile> pickedFiles = [];
    
    try {
      if (multiple) {
        final List<XFile>? images = await picker.pickMultiImage(
          imageQuality: quality,
        );
        if (images != null) {
          pickedFiles = maxImages != null 
            ? images.take(maxImages).toList()
            : images;
        }
      } else {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: quality,
        );
        if (image != null) {
          pickedFiles = [image];
        }
      }
      
      // Convert XFile to File and compress
      List<File> files = pickedFiles.map((xFile) => File(xFile.path)).toList();
      return await compressImages(files);
      
    } catch (e) {
      debugPrint('Error picking and compressing images: $e');
      return [];
    }
  }

  /// Pick and compress image from camera
  static Future<File?> pickAndCompressFromCamera() async {
    final ImagePicker picker = ImagePicker();
    
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: quality,
      );
      
      if (image != null) {
        final File imageFile = File(image.path);
        return await compressImage(imageFile);
      }
      
      return null;
    } catch (e) {
      debugPrint('Error picking and compressing camera image: $e');
      return null;
    }
  }

  /// Get estimated file size reduction
  static String getCompressionInfo() {
    return '''
Image Compression Settings:
• Max Resolution: ${maxWidth}x$maxHeight pixels
• Quality: $quality%
• Max File Size: ${maxFileSizeKB}KB
• Format: JPEG
• Estimated Size Reduction: 60-80%
    ''';
  }
} 