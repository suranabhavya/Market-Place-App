import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/src/auth/models/auth_model.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/src/auth/models/profile_model.dart';

class ProfileNotifier with ChangeNotifier {
  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  void setUpdating(bool value) {
    _isUpdating = value;
    notifyListeners();
  }

  User? _user;
  User? get user => _user;

  void loadUserFromStorage() {
    final userJson = Storage().getString('user');
    if (userJson != null) {
      _user = User.fromJson(jsonDecode(userJson));
      notifyListeners(); // Notify UI about the update
    }
  }


  // Future<void> fetchUserData() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse('${Environment.iosAppBaseUrl}/auth/users/me/'),
  //       headers: {'Authorization': 'Token ${Storage().getString('accessToken')}'},
  //     );

  //     if (response.statusCode == 200) {
  //       _user = ProfileModel.fromJson(jsonDecode(response.body));
  //       notifyListeners();
  //     }
  //   } catch (e) {
  //     print("Error fetching user data: $e");
  //   }
  // }

  // Future<bool> updateEmail(String newEmail) async {
  //   final String url = '${Environment.iosAppBaseUrl}/accounts/user/update/';
  //   final String? token = Storage().getString('accessToken');

  //   if (token == null) {
  //     return false;
  //   }

  //   try {
  //     setUpdating(true);

  //     final response = await http.patch(
  //       Uri.parse(url),
  //       headers: {
  //         'Authorization': 'Token $token',
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode({
  //         "email": newEmail,
  //       }),
  //     );

  //     setUpdating(false);

  //     if (response.statusCode == 200) {
  //       return true;
  //     } else {
  //       print("Failed to update email: ${response.body}");
  //       return false;
  //     }
  //   } catch (e) {
  //     setUpdating(false);
  //     print("Error updating email: $e");
  //     return false;
  //   }
  // }

  // Future<bool> updatePassword(String newPassword) async {
  //   final String url = '${Environment.iosAppBaseUrl}/accounts/user/update/';
  //   final String? token = Storage().getString('accessToken');

  //   if (token == null) {
  //     return false;
  //   }

  //   try {
  //     setUpdating(true);

  //     final response = await http.patch(
  //       Uri.parse(url),
  //       headers: {
  //         'Authorization': 'Token $token',
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode({
  //         "password": newPassword,
  //       }),
  //     );

  //     setUpdating(false);

  //     if (response.statusCode == 200) {
  //       return true;
  //     } else {
  //       print("Failed to update password: ${response.body}");
  //       return false;
  //     }
  //   } catch (e) {
  //     setUpdating(false);
  //     print("Error updating password: $e");
  //     return false;
  //   }
  // }

  // Future<bool> updateProfile(String name, String mobileNumber) async {
  //   final String url = '${Environment.iosAppBaseUrl}/accounts/user/update/';
  //   final String? token = Storage().getString('accessToken');

  //   if (token == null) {
  //     return false;
  //   }

  //   try {
  //     setUpdating(true);

  //     final response = await http.put(
  //       Uri.parse(url),
  //       headers: {
  //         'Authorization': 'Token $token',
  //         'Content-Type': 'application/json',
  //       },
  //       body: jsonEncode({
  //         "name": name,
  //         "mobile_number": mobileNumber,
  //       }),
  //     );

  //     setUpdating(false);

  //     if (response.statusCode == 200) {
  //       Storage().setString('user', jsonEncode({"name": name, "mobile_number": mobileNumber}));
  //       return true;
  //     } else {
  //       print("Failed to update profile: ${response.body}");
  //       return false;
  //     }
  //   } catch (e) {
  //     setUpdating(false);
  //     return false;
  //   }
  // }

  Future<bool> updateUserDetails(Map<String, dynamic> updatedFields) async {
    final String url = '${Environment.iosAppBaseUrl}/accounts/user/update/';
    final String? token = Storage().getString('accessToken');

    if (token == null) return false;

    try {
      setUpdating(true);

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updatedFields),
      );

      setUpdating(false);

      if (response.statusCode == 200) {        
        // Update locally stored user details
        final userJson = Storage().getString('user');
        if (userJson != null) {
          Map<String, dynamic> userData = jsonDecode(userJson);
          userData.addAll(updatedFields); // Update only provided fields
          Storage().setString('user', jsonEncode(userData));
          loadUserFromStorage();
          return true;
        }
        return false;
      } else {
        print("Failed to update user details: ${response.body}");
        return false;
      }
    } catch (e) {
      setUpdating(false);
      print("Error updating user details: $e");
      return false;
    }
  }

  Future<bool> updateProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // Open image picker

    if (pickedFile == null) return false; // User canceled selection

    final String url = '${Environment.iosAppBaseUrl}/accounts/user/update/';
    final String? token = Storage().getString('accessToken');

    if (token == null) return false;

    try {
      setUpdating(true);

      var request = http.MultipartRequest("PUT", Uri.parse(url));
      request.headers['Authorization'] = 'Token $token';
      request.headers['Content-Type'] = 'multipart/form-data';

      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_photo',
          pickedFile.path,
          filename: path.basename(pickedFile.path),
        ),
      );

      var response = await request.send();
      var responseData = await http.Response.fromStream(response);

      setUpdating(false);

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData.body);
        String newProfilePhoto = data['profile_photo'];

        // Retrieve and update stored user data
        final userJson = Storage().getString('user');
        if (userJson != null) {
          Map<String, dynamic> userData = jsonDecode(userJson);
          userData['profile_photo'] = newProfilePhoto; // Update only profile photo
          Storage().setString('user', jsonEncode(userData)); // Save updated data
          loadUserFromStorage();
          notifyListeners();
          return true;
        }
        return false;
      } else {
        print("Failed to update profile photo: ${responseData.body}");
        return false;
      }
    } catch (e) {
      setUpdating(false);
      print("Error updating profile photo: $e");
      return false;
    }
  }


  Future<bool> sendSchoolEmailOtp(String email) async {
    final String url = '${Environment.iosAppBaseUrl}/accounts/generate-school-email-otp/';
    final String? token = Storage().getString('accessToken');

    if (token == null) return false;

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Token $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"school_email": email}),
      );

      if (response.statusCode == 200) {
        print("OTP Sent Successfully");
        return true;
      }

      print("Failed to send OTP: ${response.body}");
      return false;
    } catch (e) {
      print("Error sending OTP: $e");
      return false;
    }
  }


  Future<bool> verifySchoolEmailOtp(String email, String otp) async {
    final String url = '${Environment.iosAppBaseUrl}/accounts/verify-school-email-otp/';
    final String? token = Storage().getString('accessToken');

    if (token == null) return false;

    try {
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

      if (response.statusCode == 200) {
        print("School Email Verified Successfully");
        return true;
      }

      print("Failed to verify school email: ${response.body}");
      return false;
    } catch (e) {
      print("Error verifying school email: $e");
      return false;
    }
  }
}