import 'package:share_plus/share_plus.dart';
import 'package:marketplace_app/src/properties/models/property_detail_model.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_detail_model.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:developer' as developer;

class ShareUtils {
  
  /// Simple test method to verify share plugin is working
  static Future<void> testShare() async {
    try {
      developer.log('Testing share functionality...');
      await Share.share('This is a test share from Sublyst app!');
      developer.log('Share test completed successfully');
    } catch (e) {
      developer.log('Share test failed: $e');
      rethrow;
    }
  }
  
  /// Share a property detail with formatted text
  static Future<void> shareProperty(PropertyDetailModel property) async {
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

🔗 View more details and contact the owner through our app!

#PropertyRental #Housing #Apartment #Sublyst
      '''.trim();

      await Share.share(
        shareText,
        subject: 'Check out this property: ${property.title}',
      );
    } catch (e) {
      developer.log('Error sharing property: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }

  /// Share a property from list model with formatted text
  static Future<void> sharePropertyFromList(PropertyListModel property) async {
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

🔗 View more details and contact the owner through our app!

#PropertyRental #Housing #Apartment #Sublyst
      '''.trim();

      await Share.share(
        shareText,
        subject: 'Check out this property: ${property.title}',
      );
    } catch (e) {
      developer.log('Error sharing property from list: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }

  /// Share a marketplace item with formatted text and image
  static Future<void> shareMarketplaceItem(MarketplaceDetailModel item) async {
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

🔗 Get this item through our marketplace!

#MarketplaceDeal #ForSale #${item.itemType.replaceAll(' ', '')} #Sublyst
      '''.trim();

      // Share the formatted text
      await Share.share(
        shareText,
        subject: 'Check out this marketplace item: ${item.title}',
      );
    } catch (e) {
      developer.log('Error sharing marketplace item: $e');
      if (e is PlatformException) {
        developer.log('Platform exception details: ${e.message}');
      }
      rethrow;
    }
  }

  /// Share a marketplace item from list model with formatted text
  static Future<void> shareMarketplaceItemFromList(MarketplaceListModel item) async {
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

🔗 Get this item through our marketplace!

#MarketplaceDeal #ForSale #${item.itemType.replaceAll(' ', '')} #Sublyst
      '''.trim();

      // Share the formatted text
      await Share.share(
        shareText,
        subject: 'Check out this marketplace item: ${item.title}',
      );
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
} 