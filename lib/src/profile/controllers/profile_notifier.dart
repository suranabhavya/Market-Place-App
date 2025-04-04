import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/src/auth/models/auth_model.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';

class ProfileNotifier with ChangeNotifier {
  // Loading states
  bool _isUpdating = false;
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  
  // Getters for loading states
  bool get isUpdating => _isUpdating;
  bool get isSendingOtp => _isSendingOtp;
  bool get isVerifyingOtp => _isVerifyingOtp;
  
  // State setters that notify listeners
  void setUpdating(bool value) {
    _isUpdating = value;
    notifyListeners();
  }

  void setSendingOtp(bool value) {
    _isSendingOtp = value;
    notifyListeners();
  }

  void setVerifyingOtp(bool value) {
    _isVerifyingOtp = value;
    notifyListeners();
  }

  // User data
  User? _user;
  User? get user => _user;

  // Load user from local storage
  void loadUserFromStorage() {
    final userJson = Storage().getString('user');
    if (userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson));
        notifyListeners();
      } catch (e) {
        debugPrint("Error parsing user data: $e");
      }
    } else {
      // If no user data in storage, clear the user
      _user = null;
      notifyListeners();
    }
  }

  // Update user profile details (name, email, password, mobile)
  Future<bool> updateUserDetails(Map<String, dynamic> updateData) async {
    final String url = '${Environment.iosAppBaseUrl}/accounts/user/update/';
    final String? token = Storage().getString('accessToken');

    if (token == null) return false;

    try {
      setUpdating(true);
      
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateData),
      );
      
      if (response.statusCode == 200) {
        // Update the user in storage
        final updatedUser = jsonDecode(response.body);
        final userJson = Storage().getString('user');
        
        if (userJson != null) {
          Map<String, dynamic> userData = jsonDecode(userJson);
          updateData.forEach((key, value) {
            // Convert snake_case keys to camelCase if needed
            final storageKey = key == 'mobile_number' ? 'mobile_number' : key;
            userData[storageKey] = value;
          });
          
          Storage().setString('user', jsonEncode(userData));
          loadUserFromStorage();
        }
        
        setUpdating(false);
        return true;
      }

      setUpdating(false);
      debugPrint("Failed to update user details: ${response.body}");
      return false;
    } catch (e) {
      setUpdating(false);
      debugPrint("Error updating user details: $e");
      return false;
    }
  }

  // Update profile photo
  Future<bool> updateProfilePhoto() async {
    final String url = '${Environment.iosAppBaseUrl}/accounts/upload-profile-photo/';
    final String? token = Storage().getString('accessToken');
    
    if (token == null) return false;

    try {
      setUpdating(true);
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) {
        setUpdating(false);
        return false;
      }
      
      File imageFile = File(image.path);
      String fileName = path.basename(imageFile.path);
      
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.headers.addAll({'Authorization': 'Token $token'});
      
      request.files.add(
        await http.MultipartFile.fromPath('profile_photo', imageFile.path, filename: fileName),
      );
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      setUpdating(false);
      
      if (response.statusCode == 200) {
        // Update the user in storage
        final responseData = jsonDecode(response.body);
        final profilePhotoUrl = responseData['profile_photo'];
        
        final userJson = Storage().getString('user');
        if (userJson != null) {
          Map<String, dynamic> userData = jsonDecode(userJson);
          userData['profile_photo'] = profilePhotoUrl;
          Storage().setString('user', jsonEncode(userData));
          loadUserFromStorage();
        }
        
        return true;
      }
      
      debugPrint("Failed to update profile photo: ${response.body}");
      return false;
    } catch (e) {
      setUpdating(false);
      debugPrint("Error updating profile photo: $e");
      return false;
    }
  }

  // Send OTP to verify school email
  Future<bool> sendSchoolEmailOtp(String email) async {
    final String url = '${Environment.iosAppBaseUrl}/accounts/generate-school-email-otp/';
    final String? token = Storage().getString('accessToken');

    if (token == null) return false;

    try {
      setSendingOtp(true);
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"school_email": email}),
      );
      
      setSendingOtp(false);

      if (response.statusCode == 200) {
        // Store the school_email in local storage
        final userJson = Storage().getString('user');
        if (userJson != null) {
          Map<String, dynamic> userData = jsonDecode(userJson);
          userData['school_email'] = email;
          Storage().setString('user', jsonEncode(userData));
          loadUserFromStorage();
        }
        
        return true;
      }

      debugPrint("Failed to send OTP: ${response.body}");
      return false;
    } catch (e) {
      setSendingOtp(false);
      debugPrint("Error sending OTP: $e");
      return false;
    }
  }

  // Verify school email with OTP
  Future<bool> verifySchoolEmailOtp(String email, String otp) async {
    final String url = '${Environment.iosAppBaseUrl}/accounts/verify-school-email-otp/';
    final String? token = Storage().getString('accessToken');

    if (token == null) return false;

    try {
      setVerifyingOtp(true);
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "school_email": email,
          "otp": otp,
        }),
      );
      
      setVerifyingOtp(false);

      if (response.statusCode == 200) {
        // Update the storage with verified status
        final userJson = Storage().getString('user');
        if (userJson != null) {
          Map<String, dynamic> userData = jsonDecode(userJson);
          userData['school_email'] = email;
          userData['school_email_verified'] = true;
          Storage().setString('user', jsonEncode(userData));
          loadUserFromStorage();
        }
        
        return true;
      }

      debugPrint("Failed to verify school email: ${response.body}");
      return false;
    } catch (e) {
      setVerifyingOtp(false);
      debugPrint("Error verifying school email: $e");
      return false;
    }
  }
}