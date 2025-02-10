// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/error_modal.dart';
import 'package:marketplace_app/src/auth/models/auth_token_model.dart';
import 'package:marketplace_app/src/auth/models/check_email_model.dart';
import 'package:marketplace_app/src/auth/models/check_mobile_model.dart';
import 'package:marketplace_app/src/auth/models/generate_otp_model.dart';
import 'package:marketplace_app/src/auth/models/profile_model.dart';
import 'package:marketplace_app/src/entrypoint/controllers/bottom_tab_notifier.dart';
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

  void setRLoading() {
    _isRLoading = !_isRLoading;
    notifyListeners();
  }
  
  void loginFunc(String data, BuildContext ctx) async{
    setLoading(true);

    try{
      var url = Uri.parse('${Environment.iosAppBaseUrl}/auth/token/login');
      print("data is just before calling url: $data");
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: data
      );
      print("sc: ${response.statusCode}");

      if(response.statusCode == 200) {
        String accessToken = accessTokenModelFromJson(response.body).authToken;

        Storage().setString('accessToken', accessToken);
        
        getuser(accessToken, ctx);
        
        setLoading(false);
        // ctx.go('/home');
      }
      else {
        setLoading(false);
        showErrorPopup(ctx, AppText.kErrorLogin, null, null);
      }
    } catch(e) {
      setLoading(false);
      showErrorPopup(ctx, AppText.kErrorLogin, null, null);
    }
  }
  
  void registrationFunc(String data, BuildContext ctx) async {
    setRLoading();

    try{
      var url = Uri.parse('${Environment.iosAppBaseUrl}/auth/users/');
      print("final data is: $data");
      var response = await  http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: data
      );
      print("response is: ${response.statusCode}");

      if(response.statusCode == 201) {
        setRLoading();
        ctx.go('/login', extra: {'email': jsonDecode(data)['email']});
      } else if(response.statusCode == 400) {
        var data = jsonDecode(response.body);
        showErrorPopup(ctx, data['password'][0], null, null);
        setRLoading();
      }
    } catch(e) {
      showErrorPopup(ctx, AppText.kErrorLogin, null, null);
      setRLoading();
    }
  }

  Future<bool> generateOTP(String data) async {
    setLoading(true);

    try {
      var url = Uri.parse('${Environment.iosAppBaseUrl}/accounts/generate-otp/');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: data
      );

      setLoading(false);

      if (response.statusCode == 200) {
        print('OTP Sent: ${response.body}');
        return true;  // Return true on success
      } else {
        print('Failed to generate OTP: ${response.body}');
        return false; // Return false on failure
      }
    } catch (e) {
      setLoading(false);
      print("Error generating OTP: $e");
      return false; // Return false if there's an exception
    }
  }

  void checkEmail(String data, BuildContext ctx) async{
    setLoading(true);

    try{
      var url = Uri.parse('${Environment.iosAppBaseUrl}/accounts/check-email/');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: data
      );

      if(response.statusCode == 200) {
        String message = checkEmailModelFromJson(response.body).message;

        print('message is: $message');
        if(message == "Email not found") {
          print(jsonDecode(data)['email']);
          ctx.go('/register', extra: {'email': jsonDecode(data)['email']});
        } else if (message == "Email exists") {
          print(jsonDecode(data)['email']);
          ctx.go('/login', extra: {'email': jsonDecode(data)['email']});
        }
        
        setLoading(false);
      }
    } catch(e) {
      setLoading(false);
      showErrorPopup(ctx, AppText.kErrorLogin, null, null);
    }
  }

  void getuser(String accessToken, BuildContext ctx) async {
    try {
      var url = Uri.parse('${Environment.iosAppBaseUrl}/auth/users/me/');
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $accessToken'
        },
      );

      if(response.statusCode == 200) {
        print("response body: ${response.body}");
        Storage().setString(accessToken, response.body);
        ctx.read<TabIndexNotifier>().setIndex(0);
        ctx.go('/home');
      }
    } catch(e) { 
      setLoading(false);
      showErrorPopup(ctx, AppText.kErrorLogin, null, null
      );
    }
  }

  ProfileModel? getUserData() {
    String? accessToken = Storage().getString('accessToken');

    if(accessToken != null) {
      var data = Storage().getString(accessToken);
      if(data != null) {
        print("data is: $data");
        return profileModelFromJson(data);
      }
    }
    return null;
  }

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
        // getuser(accessToken, ctx);
        return true;
      } else {
        print("Failed to verify OTP: ${response.body}");
        return false;
      }
    } catch (e) {
      setLoading(false);
      print("Error verifying OTP: $e");
      return false;
    }
  }

  Future<bool> checkMobile(String mobileNumber) async {
    setLoading(true);

    try {
      var url = Uri.parse('${Environment.iosAppBaseUrl}/accounts/check-mobile/');
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
        print("Failed to check mobile number: ${response.body}");
        return false;
      }
    } catch (e) {
      setLoading(false);
      print("Error checking mobile number: $e");
      return false;
    }
  }
}