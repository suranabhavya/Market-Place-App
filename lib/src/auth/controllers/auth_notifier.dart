import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/services/push_notification_service.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/error_modal.dart';
import 'package:marketplace_app/src/auth/models/auth_model.dart';
import 'package:marketplace_app/src/auth/models/check_email_model.dart';
import 'package:marketplace_app/src/entrypoint/controllers/unread_count_notifier.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

class AuthNotifier with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool b) {
    _isLoading = b;
    notifyListeners();
  }

  bool _isRLoading = false;

  bool get isRLoading => _isRLoading;

  void setRLoading(bool b) {
    _isRLoading = b;
    notifyListeners();
  }
  
  bool _isGoogleLoading = false;
  
  bool get isGoogleLoading => _isGoogleLoading;
  
  void setGoogleLoading(bool b) {
    _isGoogleLoading = b;
    notifyListeners();
  }
  
  void _handleApiError(BuildContext context, String errorMessage, [String? fallbackMessage]) {
    showErrorPopup(context, errorMessage, null, null);
  }
  
  void _reconnectUnreadNotifier(BuildContext context) {
    try {
      final unreadNotifier = context.read<UnreadCountNotifier>();
      unreadNotifier.reconnectIfNeeded();
    } catch (e) {
      // UnreadCountNotifier might not be available in all contexts
      debugPrint('UnreadCountNotifier not available: $e');
    }
  }
  
  void _initializeUserState(BuildContext context) {
    // Reconnect unread notifier
    _reconnectUnreadNotifier(context);
    
    // Initialize wishlist for the newly logged in user
    try {
      final wishlistNotifier = context.read<WishlistNotifier>();
      wishlistNotifier.loadWishlistFromStorage();
      wishlistNotifier.fetchWishlist();
    } catch (e) {
      debugPrint('WishlistNotifier not available: $e');
    }
  }
  
  Future<void> loginFunc(String data, BuildContext ctx) async {
    setLoading(true);

    try {
      var url = Uri.parse('${Environment.baseUrl}/accounts/login/');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: data
      );

      setLoading(false);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        AuthModel authData = AuthModel.fromJson(responseData);

        // Store token and user details
        Storage().setString('accessToken', authData.token);
        Storage().setString('user', jsonEncode(authData.user.toJson()));

        // Update FCM token association with user (skip on iOS if push notifications disabled)
        try {
          await PushNotificationService().updateUserAssociation();
        } catch (e) {
          // Silently handle iOS APNS errors during development
          debugPrint('Push notification setup skipped: $e');
        }

        if (ctx.mounted) {
          _initializeUserState(ctx);
          ctx.go('/home');
        }
      }
      else if (ctx.mounted) {
        var errorMessage = jsonDecode(response.body)['message'] ?? AppText.kErrorLogin;
        _handleApiError(ctx, errorMessage, null);
      }
    } catch (e) {
      setLoading(false);
      if (ctx.mounted) {
        _handleApiError(ctx, AppText.kErrorLogin, null);
      }
    }
  }
  
  Future<void> registrationFunc(String data, BuildContext ctx) async {
    setRLoading(true);

    try {
      var url = Uri.parse('${Environment.baseUrl}/accounts/register/');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: data
      );

      setRLoading(false);

      if (response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        AuthModel authData = AuthModel.fromJson(responseData);

        // Store token and user details
        Storage().setString('accessToken', authData.token);
        Storage().setString('user', jsonEncode(authData.user.toJson()));

        // Update FCM token association with user (skip on iOS if push notifications disabled)
        try {
          await PushNotificationService().updateUserAssociation();
        } catch (e) {
          // Silently handle iOS APNS errors during development
          debugPrint('Push notification setup skipped: $e');
        }

        if (ctx.mounted) {
          _initializeUserState(ctx);
          ctx.go('/home');
        }
      } else if (ctx.mounted) {
        var errorMessage = jsonDecode(response.body)['message'] ?? "Registration failed.";
        _handleApiError(ctx, errorMessage, null);
      }
    } catch (e) {
      setRLoading(false);
      if (ctx.mounted) {
        _handleApiError(ctx, AppText.kErrorLogin, null);
      }
    }
  }

  User? getUserData() {
    // String? accessToken = Storage().getString('accessToken');

    // if(accessToken != null) {
    //   var data = Storage().getString(accessToken);
    //   if(data != null) {
    //     print("data is: $data");
    //     return profileModelFromJson(data);
    //   }
    // }
    // return null;
    String? userData = Storage().getString('user');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  Future<bool> generateOTP(String data) async {
    setLoading(true);

    try {
      var url = Uri.parse('${Environment.baseUrl}/accounts/generate-otp/');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: data
      );

      setLoading(false);

      if (response.statusCode == 200) {
        debugPrint('OTP Sent: ${response.body}');
        return true;  // Return true on success
      } else {
        debugPrint('Failed to generate OTP: ${response.body}');
        return false; // Return false on failure
      }
    } catch (e) {
      setLoading(false);
      debugPrint("Error generating OTP: $e");
      return false; // Return false if there's an exception
    }
  }

  Future<void> checkEmail(String data, BuildContext ctx) async {
    if (!ctx.mounted) return;
    
    setLoading(true);

    try {
      final url = Uri.parse('${Environment.baseUrl}/accounts/check-email/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: data
      );

      // Set loading to false before using BuildContext
      setLoading(false);
      
      if (!ctx.mounted) return;
      
      final email = jsonDecode(data)['email'];
      
      switch (response.statusCode) {
        case 200:
          final responseData = checkEmailModelFromJson(response.body);
          if (responseData.message == "Email not found") {
            ctx.go('/register', extra: {'email': email});
          } else if (responseData.message == "Email exists") {
            ctx.go('/login', extra: {'email': email});
          }
          break;
          
        case 400:
          final responseData = checkEmailModelFromJson(response.body);
          if (responseData.error != null && responseData.authProvider != null) {
            _handleApiError(ctx, responseData.error!);
          } else {
            _handleApiError(ctx, "Invalid email or request. Please try again.");
          }
          break;
          
        default:
          _handleApiError(ctx, "An error occurred. Please try again later.");
          break;
      }
    } catch (e) {
      setLoading(false);
      if (ctx.mounted) {
        _handleApiError(ctx, "Network error. Please check your connection and try again.");
      }
    }
  }

  // void getuser(String accessToken, BuildContext ctx) async {
  //   try {
  //     var url = Uri.parse('${Environment.iosAppBaseUrl}/auth/users/me/');
  //     var response = await http.get(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Authorization': 'Token $accessToken'
  //       },
  //     );

  //     if(response.statusCode == 200) {
  //       print("response body: ${response.body}");
  //       Storage().setString(accessToken, response.body);
  //       ctx.read<TabIndexNotifier>().setIndex(0);
  //       ctx.go('/home');
  //     }
  //   } catch(e) { 
  //     setLoading(false);
  //     showErrorPopup(ctx, AppText.kErrorLogin, null, null
  //     );
  //   }
  // }

  Future<bool> verifyOTP(String mobileNumber, String otp) async {
    setLoading(true);

    try {
      var url = Uri.parse('${Environment.iosAppBaseUrl}/accounts/token/login/');
      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "mobile_number": mobileNumber,
          "otp": otp,
        }),
      );

      setLoading(false);

      if (response.statusCode == 200) {
        String accessToken = jsonDecode(response.body)['auth_token'];
        Storage().setString('accessToken', accessToken);
        
        // Update FCM token association with user (skip on iOS if push notifications disabled)
        try {
          await PushNotificationService().updateUserAssociation();
        } catch (e) {
          // Silently handle iOS APNS errors during development
          debugPrint('Push notification setup skipped: $e');
        }
        
        return true;
      } else {
        debugPrint("Failed to verify OTP: ${response.body}");
        return false;
      }
    } catch (e) {
      setLoading(false);
      debugPrint("Error verifying OTP: $e");
      return false;
    }
  }

  Future<bool> checkMobile(String mobileNumber) async {
    setLoading(true);

    try {
      var url = Uri.parse('${Environment.baseUrl}/accounts/check-mobile/');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"mobile_number": mobileNumber}),
      );

      setLoading(false);

      if (response.statusCode == 200) {
        String message = jsonDecode(response.body)['message'];
        return message == "Mobile Number exists";
      } else {
        debugPrint("Failed to check mobile number: ${response.body}");
        return false;
      }
    } catch (e) {
      setLoading(false);
      debugPrint("Error checking mobile number: $e");
      return false;
    }
  }

  // Handle Google Sign-In
  Future<bool> signInWithGoogle(BuildContext context) async {
    if (!context.mounted) return false;
    
    setGoogleLoading(true);
    
    try {
      debugPrint("Starting Google Sign-In process...");
      
      // Configure GoogleSignIn with proper scopes for ID token
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        serverClientId: Environment.googleOAuthServerClientId,
      );

      // Sign out first to ensure a fresh authentication flow
      debugPrint("Signing out from previous session...");
      await googleSignIn.signOut();
      
      // Get Google user - this will show the Google account picker
      debugPrint("Showing Google account picker...");
      final GoogleSignInAccount? user = await googleSignIn.signIn();
      
      // If user cancels the Google Sign-In flow
      if (user == null) {
        debugPrint("User cancelled the Google Sign-In flow");
        setGoogleLoading(false);
        return false;
      }
      
      debugPrint("User selected: ${user.email}");
      
      // Explicitly request authentication to get tokens
      debugPrint("Requesting authentication tokens...");
      final GoogleSignInAuthentication auth = await user.authentication;
      
      // If ID token is null, we can't proceed with server verification
      if (auth.idToken == null) {
        debugPrint("Failed to obtain Google ID token - this is required for server verification");
        setGoogleLoading(false);
        if (context.mounted) {
          _handleApiError(context, "Failed to obtain authentication token from Google. Please try again.");
        }
        return false;
      }
      
      debugPrint("Successfully obtained ID token, proceeding with server authentication...");
      
      // Send to Django backend for authentication/registration
      final url = Uri.parse('${Environment.baseUrl}/accounts/google-auth/');
      
      // Prepare data for Django backend with ID token for verification
      final requestData = {
        "email": user.email,
        "display_name": user.displayName ?? '',
        "google_id": user.id,
        "id_token": auth.idToken,
      };
      
      debugPrint("Sending authentication request to server...");
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestData),
      );
      
      setGoogleLoading(false);
      
      if (!context.mounted) return false;
      
      debugPrint("Server response status: ${response.statusCode}");
      debugPrint("Server response body: ${response.body}");
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Parse the response using AuthModel
        final AuthModel authData = AuthModel.fromJson(responseData);
        
        // Store token and user details
        Storage().setString('accessToken', authData.token);
        Storage().setString('user', jsonEncode(authData.user.toJson()));
        
        // Update FCM token association with user (skip on iOS if push notifications disabled)
        try {
          await PushNotificationService().updateUserAssociation();
        } catch (e) {
          // Silently handle iOS APNS errors during development
          debugPrint('Push notification setup skipped: $e');
        }
        
        // Reconnect WebSocket for unread messages
        if (context.mounted) {
          _initializeUserState(context);
        }
        
        return true;
      } else {
        if (context.mounted) {
          String errorMessage;
          try {
            errorMessage = jsonDecode(response.body)['message'] ?? "Google sign-in failed";
          } catch (e) {
            errorMessage = "Google sign-in failed: Server error (${response.statusCode})";
          }
          _handleApiError(context, errorMessage);
        }
        return false;
      }
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      setGoogleLoading(false);
      if (context.mounted) {
        _handleApiError(context, "Failed to sign in with Google. Please try again.");
      }
      return false;
    }
  }
}