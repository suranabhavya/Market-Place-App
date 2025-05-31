import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:http/http.dart' as http;

class WishlistNotifier with ChangeNotifier {
  String? error;
  List<String> _wishlist = [];
  bool _isLoading = false;

  List<String> get wishlist => _wishlist;
  bool get isLoading => _isLoading;

  void setError(String e) {
    error = e;
    notifyListeners();
  }

  Future<void> fetchWishlist() async {
    final accessToken = Storage().getString('accessToken');
    if (accessToken == null) return;

    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await http.get(
        Uri.parse('${Environment.iosAppBaseUrl}/api/wishlist/'),
        headers: {
          "Authorization": "Token $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _wishlist = data.map((item) => item['id'].toString()).toList();
        Storage().setString('${accessToken}_wishlist', jsonEncode(_wishlist));
        debugPrint('Fetched ${_wishlist.length} wishlist items');
      } else {
        error = 'Failed to fetch wishlist: ${response.reasonPhrase}';
        debugPrint('Failed to fetch wishlist: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (e) {
      error = 'An error occurred: $e';
      debugPrint('Wishlist error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleWishlist(String id, Function refetch, {String type = 'property'}) async {
    final accessToken = Storage().getString('accessToken');
    if (accessToken == null) return;

    _isLoading = true;
    notifyListeners();
    
    try {
      Uri url = Uri.parse('${Environment.iosAppBaseUrl}/api/wishlist/toggle/?id=$id&type=$type');
      debugPrint('Toggling wishlist for $type item: $id');
      
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Token $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 201) {
        if (!_wishlist.contains(id)) {
          _wishlist.add(id);
          debugPrint('Added $type item to wishlist: $id');
        }
      } else if (response.statusCode == 204) {
        _wishlist.remove(id);
        debugPrint('Removed $type item from wishlist: $id');
      } else {
        debugPrint('Error toggling wishlist: ${response.statusCode} ${response.body}');
      }

      Storage().setString('${accessToken}_wishlist', jsonEncode(_wishlist));
      notifyListeners();
      refetch();
    } catch (e) {
      error = e.toString();
      debugPrint('Error toggling wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
