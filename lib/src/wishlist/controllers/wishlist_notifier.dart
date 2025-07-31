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

  void clearError() {
    error = null;
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
        Uri.parse('${Environment.baseUrl}/api/wishlist/'),
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

    // Store the original state for rollback if needed
    final bool wasInWishlist = _wishlist.contains(id);
    
    // Optimistic update - immediately update UI
    if (wasInWishlist) {
      _wishlist.remove(id);
      debugPrint('Optimistically removed $type item from wishlist: $id');
    } else {
      _wishlist.add(id);
      debugPrint('Optimistically added $type item to wishlist: $id');
    }
    
    // Update UI immediately
    notifyListeners();

    _isLoading = true;
    
    try {
      Uri url = Uri.parse('${Environment.baseUrl}/api/wishlist/toggle/?id=$id&type=$type');
      debugPrint('Toggling wishlist for $type item: $id');
      debugPrint('Request URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Token $accessToken",
          "Content-Type": "application/json",
        },
      ).timeout(const Duration(seconds: 15)); // Increased timeout for Cloud Run cold starts

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        // Item was added successfully
        if (!_wishlist.contains(id)) {
          _wishlist.add(id);
        }
        debugPrint('Successfully added $type item to wishlist: $id');
      } else if (response.statusCode == 204) {
        // Item was removed successfully
        _wishlist.remove(id);
        debugPrint('Successfully removed $type item from wishlist: $id');
      } else if (response.statusCode == 401) {
        // Authentication error
        debugPrint('Authentication error - clearing access token');
        Storage().removeKey('accessToken');
        clearWishlist();
        error = 'Session expired. Please log in again.';
        _rollbackOptimisticUpdate(id, wasInWishlist);
      } else if (response.statusCode == 404) {
        // Not found error
        error = 'Item not found.';
        _rollbackOptimisticUpdate(id, wasInWishlist);
      } else if (response.statusCode == 502) {
        // Bad Gateway - Cloud Run cold start issue
        debugPrint('502 Bad Gateway - likely Cloud Run cold start');
        error = 'Service temporarily unavailable due to cold start. Please try again.';
        _rollbackOptimisticUpdate(id, wasInWishlist);
      } else if (response.statusCode >= 500) {
        // Server error
        debugPrint('Server error: ${response.statusCode}');
        error = 'Server temporarily unavailable. Please try again later.';
        _rollbackOptimisticUpdate(id, wasInWishlist);
      } else {
        // Other error
        debugPrint('Error toggling wishlist: ${response.statusCode} ${response.body}');
        _rollbackOptimisticUpdate(id, wasInWishlist);
        error = 'Failed to update wishlist. Please try again.';
      }

    } catch (e) {
      debugPrint('Network error toggling wishlist: $e');
      _rollbackOptimisticUpdate(id, wasInWishlist);
      
      if (e.toString().contains('TimeoutException')) {
        error = 'Request timed out. The server may be starting up, please try again.';
      } else {
        error = 'Network error. Please check your connection and try again.';
      }
    }

    // Save to storage only if no error occurred
    if (error == null) {
      Storage().setString('${accessToken}_wishlist', jsonEncode(_wishlist));
    }
        
    _isLoading = false;
    notifyListeners();
    refetch();
  }

  /// Rollback optimistic update to original state
  void _rollbackOptimisticUpdate(String id, bool wasInWishlist) {
    if (wasInWishlist) {
      // Rollback: add it back
      if (!_wishlist.contains(id)) {
        _wishlist.add(id);
        debugPrint('Rolled back: added item back to wishlist: $id');
      }
    } else {
      // Rollback: remove it
      if (_wishlist.contains(id)) {
        _wishlist.remove(id);
        debugPrint('Rolled back: removed item from wishlist: $id');
      }
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
