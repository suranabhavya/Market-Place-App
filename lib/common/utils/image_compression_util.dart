import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCompressionUtil {
  // Smart compression settings for different use cases
  static const int defaultMaxWidth = 1920;
  static const int defaultMaxHeight = 1920;
  static const int defaultQuality = 85; // High quality to avoid artifacts
  
  // Aggressive upload-optimized settings (much smaller files for cloud storage)
  static const int uploadMaxWidth = 1400; // Reduced from 1600
  static const int uploadMaxHeight = 1400; // Reduced from 1600
  static const int uploadQuality = 65; // Reduced from 75 for more compression
  
  // Very aggressive settings for large files
  static const int aggressiveMaxWidth = 1200;
  static const int aggressiveMaxHeight = 1200;
  static const int aggressiveQuality = 55; // Much more aggressive
  
  // Thumbnail settings for very small files
  static const int thumbnailMaxWidth = 800;
  static const int thumbnailMaxHeight = 800;
  static const int thumbnailQuality = 60; // Reduced from 70
  
  // File size thresholds for smart compression
  static const int veryLargeSizeThreshold = 4 * 1024 * 1024; // 4MB
  static const int largeSizeThreshold = 2 * 1024 * 1024; // 2MB
  static const int mediumSizeThreshold = 1 * 1024 * 1024; // 1MB

  /// Smart image compression with adaptive settings based on file size.
  /// Uses JPEG format only to avoid iOS color space issues with WebP.
  static Future<File> compressImage(
    File imageFile, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    bool forUpload = false, // Use optimized settings for cloud uploads
  }) async {
    try {
      final int originalSize = await imageFile.length();
      debugPrint('📷 Original image size: ${(originalSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Use upload-optimized settings if requested
      if (forUpload) {
        maxWidth = uploadMaxWidth;
        maxHeight = uploadMaxHeight;
        quality = uploadQuality;
      }

      final Directory tempDir = await getTemporaryDirectory();
      final String targetPath = path.join(
        tempDir.path,
        'compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      final XFile? compressedFile = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        targetPath,
        format: CompressFormat.jpeg, // Always use JPEG for consistency
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        keepExif: false, // Remove EXIF to reduce size and avoid rotation issues
      );

      if (compressedFile != null) {
        final File result = File(compressedFile.path);
        final int newSize = await result.length();
        final double compressionRatio = ((originalSize - newSize) / originalSize * 100);
        debugPrint('📷 Compressed image size: ${(newSize / 1024 / 1024).toStringAsFixed(2)} MB');
        debugPrint('📷 Compression ratio: ${compressionRatio.toStringAsFixed(1)}%');
        return result;
      } else {
        debugPrint('Compression failed, returning original');
        return imageFile;
      }
    } catch (e) {
      debugPrint('Error compressing image: $e');
      return imageFile;
    }
  }

  /// Optimized compression specifically for cloud uploads.
  /// Applies much stronger compression while maintaining JPEG format for iOS compatibility.
  static Future<File> compressForUpload(File imageFile) async {
    final int originalSize = await imageFile.length();
    
    // Choose compression level based on original file size
    int maxWidth, maxHeight, quality;
    
    if (originalSize > veryLargeSizeThreshold) {
      // Very large files: maximum compression
      maxWidth = aggressiveMaxWidth;
      maxHeight = aggressiveMaxHeight;
      quality = aggressiveQuality;
      debugPrint('📷 Very large file detected (${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB), using maximum compression');
    } else if (originalSize > largeSizeThreshold) {
      // Large files: aggressive compression
      maxWidth = uploadMaxWidth;
      maxHeight = uploadMaxHeight; 
      quality = 60; // More aggressive than before
      debugPrint('📷 Large file detected (${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB), using aggressive compression');
    } else if (originalSize > mediumSizeThreshold) {
      // Medium files: moderate compression
      maxWidth = uploadMaxWidth;
      maxHeight = uploadMaxHeight;
      quality = uploadQuality; // Now 65%
      debugPrint('📷 Medium file detected (${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB), using moderate compression');
    } else {
      // Small files: still compress for upload optimization
      maxWidth = uploadMaxWidth; // Changed from defaultMaxWidth
      maxHeight = uploadMaxHeight; // Changed from defaultMaxHeight
      quality = 75; // Still compress small files, but less aggressively
      debugPrint('📷 Small file detected (${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB), using light compression');
    }
    
    return await compressImage(
      imageFile,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality,
    );
  }

  /// Compress multiple images with the same settings
  static Future<List<File>> compressImages(
    List<File> images, {
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    bool forUpload = false,
  }) async {
    List<File> results = [];
    for (final img in images) {
      results.add(await compressImage(
        img,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
        forUpload: forUpload,
      ));
    }
    return results;
  }

  /// Compress multiple images for cloud upload with smart compression
  static Future<List<File>> compressImagesForUpload(List<File> images) async {
    List<File> results = [];
    for (final img in images) {
      results.add(await compressForUpload(img));
    }
    return results;
  }

  /// Pick and compress images from gallery.
  /// Uses conservative compression settings for iOS compatibility.
  static Future<List<File>> pickAndCompressFromGallery({
    bool multiple = true,
    int? maxImages,
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    bool forUpload = false,
  }) async {
    final ImagePicker picker = ImagePicker();
    List<XFile> pickedFiles = [];

    try {
      if (multiple) {
        final List<XFile> images = await picker.pickMultiImage();
        pickedFiles = maxImages != null ? images.take(maxImages).toList() : images;
      } else {
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) pickedFiles = [image];
      }

      final List<File> files = pickedFiles.map((x) => File(x.path)).toList();
      
      if (forUpload) {
        return await compressImagesForUpload(files);
      } else {
        return await compressImages(
          files,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
      }
    } catch (e) {
      debugPrint('Error picking/compressing from gallery: $e');
      return [];
    }
  }

  /// Pick and compress a single image from camera.
  static Future<File?> pickAndCompressFromCamera({
    int maxWidth = defaultMaxWidth,
    int maxHeight = defaultMaxHeight,
    int quality = defaultQuality,
    bool forUpload = false,
  }) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return null;
      
      if (forUpload) {
        return await compressForUpload(File(image.path));
      } else {
        return await compressImage(
          File(image.path),
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
      }
    } catch (e) {
      debugPrint('Error picking/compressing from camera: $e');
      return null;
    }
  }

  /// Convenience method: Pick and compress images optimized for upload
  static Future<List<File>> pickAndCompressForUpload({
    bool multiple = true,
    int? maxImages,
  }) async {
    return await pickAndCompressFromGallery(
      multiple: multiple,
      maxImages: maxImages,
      forUpload: true,
    );
  }

  /// Convenience method: Pick and compress single image from camera for upload
  static Future<File?> pickAndCompressFromCameraForUpload() async {
    return await pickAndCompressFromCamera(forUpload: true);
  }

  /// Create thumbnail version of an image (very small file size)
  static Future<File> createThumbnail(File imageFile) async {
    return await compressImage(
      imageFile,
      maxWidth: thumbnailMaxWidth,
      maxHeight: thumbnailMaxHeight,
      quality: thumbnailQuality,
    );
  }

  /// Ultra-aggressive compression for maximum file size reduction
  /// WARNING: This may result in noticeable quality loss for large images
  static Future<File> compressUltraAggressive(File imageFile) async {
    final int originalSize = await imageFile.length();
    debugPrint('📷 Ultra-aggressive compression requested for ${(originalSize / 1024 / 1024).toStringAsFixed(1)}MB file');
    
    return await compressImage(
      imageFile,
      maxWidth: 1000, // Very small dimensions
      maxHeight: 1000,
      quality: 45, // Very aggressive quality reduction
    );
  }

  /// Batch ultra-aggressive compression
  static Future<List<File>> compressImagesUltraAggressive(List<File> images) async {
    List<File> results = [];
    for (final img in images) {
      results.add(await compressUltraAggressive(img));
    }
    return results;
  }

  /// Convenience method: Pick and compress with ultra-aggressive settings
  static Future<List<File>> pickAndCompressUltraAggressive({
    bool multiple = true,
    int? maxImages,
  }) async {
    final ImagePicker picker = ImagePicker();
    List<XFile> pickedFiles = [];

    try {
      if (multiple) {
        final List<XFile> images = await picker.pickMultiImage();
        pickedFiles = maxImages != null ? images.take(maxImages).toList() : images;
      } else {
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) pickedFiles = [image];
      }

      final List<File> files = pickedFiles.map((x) => File(x.path)).toList();
      return await compressImagesUltraAggressive(files);
    } catch (e) {
      debugPrint('Error picking/compressing ultra-aggressively: $e');
      return [];
    }
  }
}