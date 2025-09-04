import 'package:share_plus/share_plus.dart';
import 'package:marketplace_app/src/properties/models/property_detail_model.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_detail_model.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ShareUtils {
  
  /// Check if the current device is an iPad
  static bool get _isIPad {
    return Platform.isIOS && 
           (MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first).size.shortestSide >= 600);
  }
  
  /// Get the share position origin for iPad popover positioning
  static Rect? _getSharePositionOrigin(BuildContext? context) {
    if (!_isIPad || context == null) return null;
    
    // Get the screen size
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;
    
    // Position the popover in the center-right of the screen for better UX
    final centerX = screenSize.width * 0.75;
    final centerY = screenSize.height * 0.5;
    
    return Rect.fromCenter(
      center: Offset(centerX, centerY),
      width: 1,
      height: 1,
    );
  }
  
  /// Simple test method to verify share plugin is working
  static Future<void> testShare([BuildContext? context]) async {
    try {
      developer.log('Testing share functionality...');
      await Share.share(
        'This is a test share from Sublyst app!',
        sharePositionOrigin: _getSharePositionOrigin(context),
      );
      developer.log('Share test completed successfully');
    } catch (e) {
      developer.log('Share test failed: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }
  
  /// Download image from URL and save to temporary directory
  static Future<String?> _downloadAndCacheImage(String imageUrl) async {
    try {
      developer.log('Downloading image: $imageUrl');
      
      // Validate URL
      if (imageUrl.isEmpty) {
        developer.log('Empty image URL provided');
        return null;
      }
      
      final uri = Uri.tryParse(imageUrl);
      if (uri == null || !uri.hasAbsolutePath) {
        developer.log('Invalid image URL: $imageUrl');
        return null;
      }
      
      // Get temporary directory with error handling
      final tempDir = await getTemporaryDirectory();
      
      // Check available storage space (basic check)
      final dirStat = await tempDir.stat();
      developer.log('Temp directory exists: ${dirStat.type != FileSystemEntityType.notFound}');
      
      // Create a unique filename with better extension handling
      final extension = path.extension(uri.path).isNotEmpty 
          ? path.extension(uri.path) 
          : '.jpg';
      final fileName = 'share_image_${DateTime.now().millisecondsSinceEpoch}$extension';
      final filePath = path.join(tempDir.path, fileName);
      
      // Download the image with retry logic
      late http.Response response;
      int retryCount = 0;
      const maxRetries = 2;
      
      while (retryCount <= maxRetries) {
        try {
          response = await http.get(
            Uri.parse(imageUrl),
            headers: {
              'User-Agent': 'Sublyst-App/1.0',
              'Accept': 'image/*',
            },
          ).timeout(const Duration(seconds: 15));
          break;
        } catch (e) {
          retryCount++;
          if (retryCount > maxRetries) {
            developer.log('Failed to download after $maxRetries retries: $e');
            return null;
          }
          developer.log('Retry $retryCount/$maxRetries for image download');
          await Future.delayed(Duration(seconds: retryCount));
        }
      }
      
      if (response.statusCode == 200) {
        // Validate image data
        if (response.bodyBytes.isEmpty) {
          developer.log('Downloaded image is empty');
          return null;
        }
        
        // Check if it's actually an image (basic validation)
        final bytes = response.bodyBytes;
        if (bytes.length < 100) {
          developer.log('Downloaded file too small to be valid image');
          return null;
        }
        
        // Save to temporary file
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        
        // Verify file was written successfully
        if (await file.exists() && await file.length() > 0) {
          developer.log('Image cached successfully: $filePath (${bytes.length} bytes)');
          return filePath;
        } else {
          developer.log('Failed to write image file');
          return null;
        }
      } else {
        developer.log('Failed to download image: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      developer.log('Error downloading image: $e');
      return null;
    }
  }
  
  /// Clean up temporary image files (call this periodically)
  static Future<void> cleanupTempImages() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      int deletedCount = 0;
      int totalSize = 0;
      
      final now = DateTime.now();
      
      for (final file in files) {
        if (file.path.contains('share_image_') && file is File) {
          try {
            // Get file info
            final stat = await file.stat();
            final fileAge = now.difference(stat.modified);
            final fileSize = stat.size;
            
            // Delete files older than 1 hour or if we have too many temp files
            if (fileAge.inHours > 1 || deletedCount > 50) {
              await file.delete();
              deletedCount++;
              totalSize += fileSize;
              developer.log('Deleted temp file: ${path.basename(file.path)} (${fileSize} bytes, ${fileAge.inMinutes} minutes old)');
            }
          } catch (e) {
            developer.log('Could not delete temp file: ${file.path} - $e');
          }
        }
      }
      
      if (deletedCount > 0) {
        developer.log('Cleanup complete: Deleted $deletedCount files, freed ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      }
    } catch (e) {
      developer.log('Error cleaning up temp images: $e');
    }
  }
  
  /// Check and manage storage space for sharing
  static Future<bool> _checkStorageSpace() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();
      
      // Count our temp files
      final shareFiles = files.where((f) => f.path.contains('share_image_')).toList();
      
      // If we have more than 20 temp files, clean up old ones
      if (shareFiles.length > 20) {
        developer.log('Too many temp files (${shareFiles.length}), cleaning up...');
        await cleanupTempImages();
        return true;
      }
      
      return true;
    } catch (e) {
      developer.log('Error checking storage space: $e');
      return false;
    }
  }
  
  /// Share a property detail with formatted text and multiple images (up to 5)
  static Future<void> shareProperty(PropertyDetailModel property, [BuildContext? context]) async {
    try {
      final String formattedRent = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 0,
      ).format(property.rent);
      
      final String shareText = '''
🏠 Check out this amazing property!

📍 ${property.title}
💰 Rent: $formattedRent/month
📍 Location: ${property.address}

📝 Description:
${property.description}

🔗 Get more details about this property and contact verified owner through Sublyst!

🏘️ Explore properties similar to this near your area.

📱 Download Sublyst for iOS:
https://apps.apple.com/us/app/sublyst/id6749684934

#PropertyRental #Housing #Apartment #Sublyst
      '''.trim();

      // Share with primary image if available
      if (property.images != null && property.images!.isNotEmpty) {
        developer.log('Attempting to share property with primary image');
        
        await shareSingleImage(
          property.images!.first, // Use only the first (primary) image
          shareText,
          subject: 'Check out this property: ${property.title}',
          context: context,
        );
        developer.log('Property shared with primary image successfully');
      } else {
        // Fallback to text-only sharing if no images
        await Share.share(
          shareText,
          subject: 'Check out this property: ${property.title}',
          sharePositionOrigin: _getSharePositionOrigin(context),
        );
        developer.log('Property shared (text only - no images available)');
      }
      
    } catch (e) {
      developer.log('Error sharing property: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }

  /// Share a property from list model with formatted text and multiple images (up to 5)
  static Future<void> sharePropertyFromList(PropertyListModel property, [BuildContext? context]) async {
    try {
      final String formattedRent = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 0,
      ).format(property.rent);
      
      final String address = property.hideAddress 
          ? '${property.city ?? ''}, ${property.state ?? ''}'
          : property.address;
      
      final String shareText = '''
🏠 Check out this amazing property!

📍 ${property.title}
💰 Rent: $formattedRent/${property.rentFrequency}
📍 Location: $address

🔗 Get more details about this property and contact verified owner through Sublyst!

🏘️ Explore properties similar to this near your area.

📱 Download Sublyst for iOS:
https://apps.apple.com/us/app/sublyst/id6749684934

#PropertyRental #Housing #Apartment #Sublyst
      '''.trim();

      // Share with primary image if available
      if (property.images != null && property.images!.isNotEmpty) {
        developer.log('Attempting to share property list item with primary image');
        
        await shareSingleImage(
          property.images!.first, // Use only the first (primary) image
          shareText,
          subject: 'Check out this property: ${property.title}',
          context: context,
        );
        developer.log('Property list item shared with primary image successfully');
      } else {
        // Fallback to text-only sharing if no images
        await Share.share(
          shareText,
          subject: 'Check out this property: ${property.title}',
          sharePositionOrigin: _getSharePositionOrigin(context),
        );
        developer.log('Property list item shared (text only - no images available)');
      }
      
    } catch (e) {
      developer.log('Error sharing property from list: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }

  /// Share a marketplace item with formatted text and multiple images (up to 5)
  static Future<void> shareMarketplaceItem(MarketplaceDetailModel item, [BuildContext? context]) async {
    try {
      final String formattedPrice = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 0,
      ).format(item.price);
      
      String originalPriceText = '';
      if (item.originalPrice != null && item.originalPrice! > item.price) {
        final String formattedOriginalPrice = NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
        ).format(item.originalPrice!);
        originalPriceText = ' (was $formattedOriginalPrice)';
      }

      final String shareText = '''
🛍️ Great deal on this item!

📦 ${item.title}
💰 Price: $formattedPrice$originalPriceText
📍 Location: ${item.address}
🏷️ Condition: ${item.condition.toUpperCase()}

📝 Description:
${item.description}

🔗 Get more details about this item and contact verified seller through Sublyst!

🛒 Explore items similar to this near your area.

📱 Download Sublyst for iOS:
https://apps.apple.com/us/app/sublyst/id6749684934

#MarketplaceDeal #ForSale #${item.itemType.replaceAll(' ', '')} #Sublyst
      '''.trim();

      // Share with primary image if available
      if (item.images.isNotEmpty) {
        developer.log('Attempting to share marketplace item with primary image');
        
        // Use only the first (primary) image
        final primaryImageUrl = item.images.first.image;
        
        await shareSingleImage(
          primaryImageUrl,
          shareText,
          subject: 'Check out this marketplace item: ${item.title}',
          context: context,
        );
        developer.log('Marketplace item shared with primary image successfully');
      } else {
        // Fallback to text-only sharing if no images
        await Share.share(
          shareText,
          subject: 'Check out this marketplace item: ${item.title}',
          sharePositionOrigin: _getSharePositionOrigin(context),
        );
        developer.log('Marketplace item shared (text only - no images available)');
      }
      
    } catch (e) {
      developer.log('Error sharing marketplace item: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }

  /// Share a marketplace item from list model with formatted text and multiple images (up to 5)
  static Future<void> shareMarketplaceItemFromList(MarketplaceListModel item, [BuildContext? context]) async {
    try {
      final String formattedPrice = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 0,
      ).format(item.price);
      
      String originalPriceText = '';
      if (item.originalPrice != null && item.originalPrice! > item.price) {
        final String formattedOriginalPrice = NumberFormat.currency(
          symbol: '\$',
          decimalDigits: 0,
        ).format(item.originalPrice!);
        originalPriceText = ' (was $formattedOriginalPrice)';
      }

      final String address = item.hideAddress 
          ? '${item.city ?? ''}, ${item.state ?? ''}'
          : item.address;

      final String shareText = '''
🛍️ Great deal on this item!

📦 ${item.title}
💰 Price: $formattedPrice$originalPriceText
📍 Location: $address
🏷️ Type: ${item.itemType.toUpperCase()}

🔗 Get more details about this item and contact verified seller through Sublyst!

🛒 Explore items similar to this near your area.

📱 Download Sublyst for iOS:
https://apps.apple.com/us/app/sublyst/id6749684934

#MarketplaceDeal #ForSale #${item.itemType.replaceAll(' ', '')} #Sublyst
      '''.trim();

      // Share with primary image if available
      if (item.images.isNotEmpty) {
        developer.log('Attempting to share marketplace list item with primary image');
        
        // Use only the first (primary) image
        final primaryImageUrl = item.images.first.image;
        
        await shareSingleImage(
          primaryImageUrl,
          shareText,
          subject: 'Check out this marketplace item: ${item.title}',
          context: context,
        );
        developer.log('Marketplace list item shared with primary image successfully');
      } else {
        // Fallback to text-only sharing if no images
        await Share.share(
          shareText,
          subject: 'Check out this marketplace item: ${item.title}',
          sharePositionOrigin: _getSharePositionOrigin(context),
        );
        developer.log('Marketplace list item shared (text only - no images available)');
      }
      
    } catch (e) {
      developer.log('Error sharing marketplace item from list: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }

  /// Share text with custom content
  static Future<void> shareCustomText(String text, {String? subject}) async {
    try {
      await Share.share(text, subject: subject);
    } catch (e) {
      developer.log('Error sharing custom text: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }

  /// Share a single image (primary photo) with text
  /// This is a simpler alternative to shareMultipleImages for sharing only the primary photo
  static Future<void> shareSingleImage(String imageUrl, String text, {String? subject, BuildContext? context}) async {
    try {
      developer.log('Attempting to share single image: $imageUrl');
      
      // Check storage space before downloading
      final hasSpace = await _checkStorageSpace();
      if (!hasSpace) {
        developer.log('Insufficient storage space, sharing text only');
        await Share.share(
          text, 
          subject: subject,
          sharePositionOrigin: _getSharePositionOrigin(context),
        );
        return;
      }
      
      // Download the image
      final imagePath = await _downloadAndCacheImage(imageUrl);
      
      if (imagePath != null) {
        developer.log('Sharing single image...');
        
        // Share single image with text
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: text,
          subject: subject,
          sharePositionOrigin: _getSharePositionOrigin(context),
        );
        developer.log('Single image shared successfully');
        
        // Schedule cleanup for later (don't block sharing)
        Future.delayed(const Duration(minutes: 30), () {
          cleanupTempImages().catchError((e) {
            developer.log('Background cleanup failed: $e');
          });
        });
      } else {
        // Fallback to text only if image download failed
        developer.log('Image download failed, sharing text only');
        await Share.share(
          text, 
          subject: subject,
          sharePositionOrigin: _getSharePositionOrigin(context),
        );
      }
      
    } catch (e) {
      developer.log('Error sharing single image: $e');
      // Fallback to text-only sharing
      try {
        await Share.share(
          text, 
          subject: subject,
          sharePositionOrigin: _getSharePositionOrigin(context),
        );
        developer.log('Fallback text sharing successful');
      } catch (fallbackError) {
        developer.log('Fallback text sharing also failed: $fallbackError');
        rethrow;
      }
    }
  }

  /// Share with specific apps (WhatsApp, Facebook, etc.)
  static Future<void> shareToSpecificApp(String text, String packageName) async {
    try {
      // Note: share_plus doesn't support direct app targeting on all platforms
      // But we can use the standard share which will show available apps
      await Share.share(text);
    } catch (e) {
      developer.log('Error sharing to specific app: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }
  
  /// Initialize sharing service (call this in main.dart or app startup)
  static Future<void> initialize() async {
    try {
      developer.log('Initializing ShareUtils...');
      
      // Clean up any old temp files on app startup
      await cleanupTempImages();
      
      // Schedule periodic cleanup every 4 hours
      // Note: This won't run when app is closed, but will clean up during active use
      Timer.periodic(const Duration(hours: 4), (timer) {
        cleanupTempImages().catchError((e) {
          developer.log('Periodic cleanup failed: $e');
        });
      });
      
      developer.log('ShareUtils initialized successfully');
    } catch (e) {
      developer.log('Error initializing ShareUtils: $e');
    }
  }
  
  /// Share multiple images with text (advanced feature - limited platform support)
  /// Note: This works well on Android, limited support on iOS
  /// @deprecated Use shareSingleImage instead - app now shares only primary photo
  static Future<void> shareMultipleImages(List<String> imageUrls, String text, {String? subject}) async {
    try {
      developer.log('Attempting to share multiple images: ${imageUrls.length}');
      
      // Check storage space before downloading
      final hasSpace = await _checkStorageSpace();
      if (!hasSpace) {
        developer.log('Insufficient storage space, sharing text only');
        await Share.share(text, subject: subject);
        return;
      }
      
      // Download all images with progress tracking
      final List<String> imagePaths = [];
      int downloadCount = 0;
      const maxImages = 5;
      
      for (final imageUrl in imageUrls.take(maxImages)) {
        developer.log('Downloading image ${downloadCount + 1}/$maxImages');
        final imagePath = await _downloadAndCacheImage(imageUrl);
        if (imagePath != null) {
          imagePaths.add(imagePath);
          downloadCount++;
        }
        
        // If we have at least 1 image and others are failing, proceed with what we have
        if (imagePaths.isNotEmpty && downloadCount >= 3 && imagePaths.length < downloadCount) {
          developer.log('Some downloads failed, proceeding with ${imagePaths.length} images');
          break;
        }
      }
      
      if (imagePaths.isNotEmpty) {
        developer.log('Sharing ${imagePaths.length} images...');
        
        // Share multiple images
        await Share.shareXFiles(
          imagePaths.map((path) => XFile(path)).toList(),
          text: text,
          subject: subject,
        );
        developer.log('Multiple images shared successfully: ${imagePaths.length}');
        
        // Schedule cleanup for later (don't block sharing)
        Future.delayed(const Duration(minutes: 30), () {
          cleanupTempImages().catchError((e) {
            developer.log('Background cleanup failed: $e');
          });
        });
      } else {
        // Fallback to text only
        developer.log('No images downloaded successfully, sharing text only');
        await Share.share(text, subject: subject);
      }
    } catch (e) {
      developer.log('Error sharing multiple images: $e');
      // Fallback to text only
      try {
        await Share.share(text, subject: subject);
      } catch (fallbackError) {
        developer.log('Fallback text sharing also failed: $fallbackError');
        rethrow;
      }
    }
  }
  

} 