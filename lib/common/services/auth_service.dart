import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/auth/models/auth_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Check if user is authenticated (locally first, then server if needed)
  Future<bool> isAuthenticated() async {
    final String? token = Storage().getString('accessToken');
    
    if (token == null) {
      return false;
    }

    // Check local expiration first (faster)
    if (Storage().isTokenExpiredLocally()) {
      await logout();
      return false;
    }

    // If local check passes, verify with server
    return await validateTokenWithServer(token);
  }

  // Validate token with server
  Future<bool> validateTokenWithServer(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.baseUrl}/accounts/validate-token/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Token is valid, update user data if needed
        final responseData = jsonDecode(response.body);
        if (responseData['user'] != null) {
          Storage().setString('user', jsonEncode(responseData['user']));
        }
        return true;
      } else {
        // Token is invalid or expired
        await logout();
        return false;
      }
    } catch (e) {
      debugPrint('Error validating token: $e');
      // On network error, trust local validation for now
      return !Storage().isTokenExpiredLocally();
    }
  }

  // Get current user from storage
  User? getCurrentUser() {
    String? userData = Storage().getString('user');
    if (userData != null) {
      try {
        return User.fromJson(jsonDecode(userData));
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  // Logout and clear all auth data
  Future<void> logout() async {
    final String? token = Storage().getString('accessToken');
    
    // Try to logout from server (optional, don't block on this)
    if (token != null) {
      try {
        await http.post(
          Uri.parse('${Environment.baseUrl}/accounts/logout/'),
          headers: {
            'Authorization': 'Token $token',
            'Content-Type': 'application/json',
          },
        );
      } catch (e) {
        debugPrint('Error logging out from server: $e');
        // Continue with local logout even if server logout fails
      }
    }

    // Clear local storage
    await Storage().clearAuthData();
  }

  // Store authentication data with timestamp
  void storeAuthData(String token, User user) {
    Storage().setTokenWithTimestamp(token);
    Storage().setString('user', jsonEncode(user.toJson()));
  }
} 