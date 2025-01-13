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
      var url = Uri.parse('${Environment.appBaseUrl}/auth/token/login');
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
    } catch(e) {
      setLoading(false);
      showErrorPopup(ctx, AppText.kErrorLogin, null, null);
    }
  }
  
  void registrationFunc(String data, BuildContext ctx) async {
    setRLoading();

    try{
      var url = Uri.parse('${Environment.appBaseUrl}/auth/users/');
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
        setRLoading();
        var data = jsonDecode(response.body);
        showErrorPopup(ctx, data['password'][0], null, null
        );
      }
    } catch(e) {
      setRLoading();
      showErrorPopup(ctx, AppText.kErrorLogin, null, null);
    }
  }

  void checkMobile(String data, BuildContext ctx) async{
    setLoading(true);

    try{
      var url = Uri.parse('${Environment.appBaseUrl}/accounts/check-mobile/');
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: data
      );

      if(response.statusCode == 200) {
        // String accessToken = accessTokenModelFromJson(response.body).authToken;
        String message = checkMobileModelFromJson(response.body).message;

        print('message is: $message');
        // Storage().setString('accessToken', accessToken);
        
        // getuser(accessToken, ctx);
        
        setLoading(false);
        // ctx.go('/home');
      }
    } catch(e) {
      setLoading(false);
      showErrorPopup(ctx, AppText.kErrorLogin, null, null);
    }
  }

  void checkEmail(String data, BuildContext ctx) async{
    setLoading(true);

    try{
      var url = Uri.parse('${Environment.appBaseUrl}/accounts/check-email/');
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
      var url = Uri.parse('${Environment.appBaseUrl}/auth/users/me/');
      var response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $accessToken'
        },
      );

      if(response.statusCode == 200) {
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
        return profileModelFromJson(data);
      }
    }
    return null;
  }
}