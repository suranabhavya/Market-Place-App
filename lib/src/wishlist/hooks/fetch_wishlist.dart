import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';

class WishlistHookResult {
  final List<PropertyListModel> properties;
  final bool isLoading;
  final String? error;
  final VoidCallback refetch;

  WishlistHookResult({
    required this.properties,
    required this.isLoading,
    this.error,
    required this.refetch,
  });
}

WishlistHookResult useFetchWishlist() {
  final properties = useState<List<PropertyListModel>>([]);
  final isLoading = useState<bool>(true);
  final error = useState<String?>(null);

  Future<void> fetchWishlist() async {
    try {
      String? token = Storage().getString('accessToken');
      print("token is $token");
      final response = await http.get(
        Uri.parse('${Environment.iosAppBaseUrl}/api/wishlist/'),
        headers: {
          "Authorization": "Token $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        print("response is: ${response.body}");
        final List<dynamic> data = json.decode(response.body);
        // properties.value =
        //     data.map((item) => PropertyListModel.fromJson(item)).toList();
        properties.value = data.map((item) {
          try {
            return PropertyListModel.fromJson(item);
          } catch (e) {
            print("Error parsing item: $item. Error: $e");
            return null; // This will help identify problematic items
          }
        }).whereType<PropertyListModel>().toList();
      } else {
        error.value = 'Failed to fetch wishlist: ${response.reasonPhrase}';
      }
    } catch (e) {
      error.value = 'An error occurred: $e';
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
    properties: properties.value,
    isLoading: isLoading.value,
    error: error.value,
    refetch: refetch
  );
}