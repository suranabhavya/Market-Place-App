import 'dart:convert';
import 'dart:ui';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:marketplace_app/src/marketplace/models/marketplace_list_model.dart';
import 'package:flutter/material.dart';

class WishlistItem {
  final String id;
  final String title;
  final dynamic item;
  final String itemType; // 'property' or 'marketplace'
  final List<String> images;

  WishlistItem({
    required this.id,
    required this.title,
    required this.item,
    required this.itemType,
    required this.images,
  });
}

class WishlistHookResult {
  final List<WishlistItem> wishlistItems;
  final bool isLoading;
  final String? error;
  final VoidCallback refetch;

  WishlistHookResult({
    required this.wishlistItems,
    required this.isLoading,
    this.error,
    required this.refetch,
  });
}

WishlistHookResult useFetchWishlist() {
  final wishlistItems = useState<List<WishlistItem>>([]);
  final isLoading = useState<bool>(true);
  final error = useState<String?>(null);

  Future<void> fetchWishlist() async {
    try {
      String? token = Storage().getString('accessToken');
      if (token == null) {
        // Clear wishlist data if no user is logged in
        wishlistItems.value = [];
        isLoading.value = false;
        debugPrint('No user logged in - cleared wishlist');
        return;
      }

      final response = await http.get(
        Uri.parse('${Environment.iosAppBaseUrl}/api/wishlist/'),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<WishlistItem> items = [];
        
        for (var item in data) {
          try {
            String itemType = item['wishlist_item_type'] ?? 'property'; // Default to property for backward compatibility
            
            if (itemType == 'property') {
              // Parse as property
              final property = PropertyListModel.fromJson(item);
              items.add(WishlistItem(
                id: property.id,
                title: property.title,
                item: property,
                itemType: 'property',
                images: property.images != null ? List<String>.from(property.images!) : [],
              ));
            } else if (itemType == 'marketplace') {
              // Parse marketplace item images
              List<String> imageUrls = [];
              if (item['images'] != null) {
                if (item['images'] is List) {
                  // Directly use string URLs from the list
                  imageUrls = List<String>.from(item['images']);
                } else if (item['images'] is String) {
                  // Single image as string
                  imageUrls = [item['images']];
                }
              }
              
              // Parse as marketplace item
              items.add(WishlistItem(
                id: item['id'] ?? '',
                title: item['title'] ?? '',
                item: item, // Store raw item data
                itemType: 'marketplace',
                images: imageUrls,
              ));
              debugPrint('Added marketplace wishlist item: ${item['title']}, images: ${imageUrls.length}');
            }
          } catch (e) {
            debugPrint('Error parsing wishlist item: $e');
          }
        }
        
        wishlistItems.value = items;
        debugPrint('Fetched ${items.length} wishlist items for user');
      } else {
        error.value = 'Failed to fetch wishlist: ${response.reasonPhrase}';
        debugPrint('Failed to fetch wishlist: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      error.value = 'An error occurred: $e';
      debugPrint('Wishlist fetch error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  useEffect(() {
    fetchWishlist();
    return;
  }, const []);

  void refetch() {
    isLoading.value = true;
    fetchWishlist();
  }

  return WishlistHookResult(
    wishlistItems: wishlistItems.value,
    isLoading: isLoading.value,
    error: error.value,
    refetch: refetch,
  );
}
