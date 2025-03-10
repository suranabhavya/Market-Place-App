import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:http/http.dart' as http;

class WishlistNotifier with ChangeNotifier {
  String? error;
  List<String> _wishlist = [];

  List<String> get wishlist => _wishlist;

  void setError(String e) {
    error = e;
    notifyListeners();
  }

  Future<void> fetchWishlist() async {
    final accessToken = Storage().getString('accessToken');
    if (accessToken == null) return;

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
        notifyListeners();
      } else {
        error = 'Failed to fetch wishlist: ${response.reasonPhrase}';
      }
    } catch (e) {
      error = 'An error occurred: $e';
    }
  }

  void toggleWishlist(String id, Function refetch) async {
    final accessToken = Storage().getString('accessToken');
    if (accessToken == null) return;

    try {
      Uri url = Uri.parse('${Environment.iosAppBaseUrl}/api/wishlist/toggle/?id=$id');
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Token $accessToken",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 201) {
        _wishlist.add(id);
      } else if (response.statusCode == 204) {
        _wishlist.remove(id);
      }

      Storage().setString('${accessToken}_wishlist', jsonEncode(_wishlist));
      notifyListeners();
      refetch(); // Ensure UI updates immediately
    } catch (e) {
      error = e.toString();
    }
  }
}
