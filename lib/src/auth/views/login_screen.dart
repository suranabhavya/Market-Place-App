import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/password_field.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/auth/models/login_model.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class LoginPage extends StatefulWidget {
  final String? prefilledEmail;

  const LoginPage({super.key, this.prefilledEmail});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController = TextEditingController();
  
  // Focus nodes
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordNode = FocusNode();
  
  // Validation error states
  String? _emailError;
  String? _passwordError;
  
  // Debounce timer for validation
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
    
    // Set focus based on whether email is pre-filled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
        FocusScope.of(context).requestFocus(_passwordNode);
      } else {
        FocusScope.of(context).requestFocus(_emailFocusNode);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  // Validation function for fields
  String? _validateField(String fieldName, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName cannot be empty";
    }
    
    if (fieldName == "Email") {
      const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$';
      if (!RegExp(pattern, caseSensitive: false).hasMatch(value)) {
        return "Enter a valid email";
      }
    }
    
    return null;
  }
  
  // Validate with debounce to prevent excessive validation calls
  void _validateWithDebounce(String value, String fieldName) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          if (fieldName == "Email") {
            _emailError = _validateField(fieldName, value);
          } else if (fieldName == "Password") {
            _passwordError = _validateField(fieldName, value);
          }
        });
      }
    });
  }
  
  // Validate all fields and return if valid
  bool _validateAllFields() {
    setState(() {
      _emailError = _validateField("Email", _emailController.text);
      _passwordError = _validateField("Password", _passwordController.text);
    });
    
    return _emailError == null && _passwordError == null;
  }
  
  // Handle login process
  void _handleLogin() {
    // Validate fields before proceeding
    if (!_validateAllFields()) {
      return; // Stop if validation fails
    }
    
    final model = LoginModel(
      email: _emailController.text,
      password: _passwordController.text
    );
    
    final data = loginModelToJson(model);
    context.read<AuthNotifier>().loginFunc(data, context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = context.watch<AuthNotifier>().isLoading;
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(
           onTap: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header section
                Text(
                  "HomiSwap",
                  textAlign: TextAlign.center,
                  style: appStyle(24, Kolors.kPrimary, FontWeight.bold)
                ),
                SizedBox(height: 10.h),
                Text(
                  "Hey Homie! Welcome back. You've been missed!",
                  textAlign: TextAlign.center,
                  style: appStyle(13, Kolors.kGray, FontWeight.normal),
                ),
                
                SizedBox(height: 25.h),
                
                // Login form section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      // Email field
                      EmailTextField(
                        radius: 25,
                        focusNode: _emailFocusNode,
                        hintText: "Email",
                        controller: _emailController,
                        prefixIcon: const Icon(CupertinoIcons.mail, size: 20, color: Kolors.kGray),
                        keyboardType: TextInputType.emailAddress,
                        onEditingComplete: () => FocusScope.of(context).requestFocus(_passwordNode),
                        onChanged: (value) => _validateWithDebounce(value, "Email"),
                        errorText: _emailError,
                      ),
                
                      SizedBox(height: 25.h),
                
                      // Password field
                      PasswordField(
                        controller: _passwordController,
                        focusNode: _passwordNode,
                        radius: 25,
                        hintText: "Password",
                        errorText: _passwordError,
                        onChanged: (value) => _validateWithDebounce(value, "Password"),
                        onEditingComplete: _handleLogin,
                      ),
                    
                      SizedBox(height: 20.h),
                
                      // Login button or loading indicator
                      isLoading 
                        ? const Center(
                            child: CircularProgressIndicator(
                              backgroundColor: Kolors.kPrimary,
                              valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                            ),
                          )
                        : CustomButton(
                            onTap: _handleLogin,
                            text: "L O G I N",
                            textSize: 16,
                            btnWidth: ScreenUtil().screenWidth,
                            btnHeight: 50.h,
                            radius: 25,
                          )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 130.h,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 110),
            child: GestureDetector(
              onTap: () => context.push('/register'),
              child: Text(
                'Do not have an account? Register a new one',
                style: appStyle(12, Colors.blue, FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }
}