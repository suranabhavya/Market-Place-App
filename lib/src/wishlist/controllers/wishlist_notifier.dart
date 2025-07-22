import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:http/http.dart' as http;

class WishlistNotifier with ChangeNotifier {
  String? error;
  List<String> _wishlist = [];
  bool _isLoading = false;
  String? _currentAccessToken;

  List<String> get wishlist => _wishlist;
  bool get isLoading => _isLoading;

  void setError(String e) {
    error = e;
    notifyListeners();
  }

  // Clear wishlist data (called on logout)
  void clearWishlist() {
    _wishlist.clear();
    _currentAccessToken = null;
    error = null;
    notifyListeners();
    debugPrint('Wishlist cleared');
  }

  // Check if user changed and handle accordingly
  void _checkUserChange() {
    final accessToken = Storage().getString('accessToken');
    
    // If token changed (user logged out or different user logged in)
    if (_currentAccessToken != accessToken) {
      if (accessToken == null) {
        // User logged out - clear wishlist
        clearWishlist();
      } else {
        // Different user or new login - load their wishlist
        _currentAccessToken = accessToken;
        fetchWishlist();
      }
    }
  }

  Future<void> fetchWishlist() async {
    final accessToken = Storage().getString('accessToken');
    
    // If no access token, clear wishlist and return
    if (accessToken == null) {
      clearWishlist();
      return;
    }

    // Check if user changed
    _checkUserChange();

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
        _currentAccessToken = accessToken;
        debugPrint('Fetched ${_wishlist.length} wishlist items for user');
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
    
    // If no access token, clear wishlist and return
    if (accessToken == null) {
      clearWishlist();
      return;
    }

    // Check if user changed
    _checkUserChange();

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

      // Only save to storage if we have a valid access token
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

  // Load wishlist from local storage for the current user
  void loadWishlistFromStorage() {
    final accessToken = Storage().getString('accessToken');
    
    if (accessToken == null) {
      clearWishlist();
      return;
    }

    final storedWishlist = Storage().getString('${accessToken}_wishlist');
    if (storedWishlist != null) {
      try {
        final List<dynamic> decoded = jsonDecode(storedWishlist);
        _wishlist = decoded.map((item) => item.toString()).toList();
        _currentAccessToken = accessToken;
        notifyListeners();
        debugPrint('Loaded ${_wishlist.length} wishlist items from storage');
      } catch (e) {
        debugPrint('Error loading wishlist from storage: $e');
        _wishlist = [];
      }
    } else {
      _wishlist = [];
    }
    
    notifyListeners();
  }
}
