import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/app_routes.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/auth/models/auth_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Periodic token validation timer
  Timer? _validationTimer;
  static const Duration _validationInterval = Duration(minutes: 15);

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
    
    // Stop periodic validation
    stopPeriodicValidation();
    
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

  // Start periodic token validation
  void startPeriodicValidation() {
    // Stop any existing timer first
    stopPeriodicValidation();
    
    _validationTimer = Timer.periodic(_validationInterval, (_) async {
      try {
        final String? token = Storage().getString('accessToken');
        
        if (token == null) {
          // No token, stop validation
          stopPeriodicValidation();
          return;
        }
        
        
        // Use existing validation method which already handles logout on failure
        final isValid = await validateTokenWithServer(token);
        
        if (!isValid) {
          // Token invalid - user has already been logged out by validateTokenWithServer()
          // Navigate to login screen if we have a valid context
          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            context.go('/login');
          }
          
          // Stop further validation since user is now logged out
          stopPeriodicValidation();
        }
      } catch (e) {
        debugPrint('Error during periodic token validation: $e');
      }
    });
  }

  // Stop periodic token validation
  void stopPeriodicValidation() {
    if (_validationTimer != null) {
      _validationTimer?.cancel();
      _validationTimer = null;
    }
  }

  // Check if periodic validation is running
  bool get isPeriodicValidationActive => _validationTimer?.isActive ?? false;

  // Delete account permanently
  Future<bool> deleteAccount() async {
    final String? token = Storage().getString('accessToken');
    
    if (token == null) {
      return false;
    }

    try {
      final response = await http.delete(
        Uri.parse('${Environment.baseUrl}/accounts/delete-account/'),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Account successfully deleted, clear all local data
        stopPeriodicValidation();
        await Storage().clearAuthData();
        return true;
      } else {
        debugPrint('Failed to delete account: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }
} 