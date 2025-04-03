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
import 'package:marketplace_app/src/auth/models/registration_model.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class RegistrationPage extends StatefulWidget {
  final String? prefilledEmail;

  const RegistrationPage({super.key, this.prefilledEmail});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  
  late final TextEditingController _emailController;
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _passwordNode = FocusNode();
  final FocusNode _confirmPasswordNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  
  // Validation error states
  String? _emailError;
  String? _nameError;
  String? _passwordError;
  String? _confirmPasswordError;
  
  // Debounce timer for validation
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    
    // Set focus based on whether email is pre-filled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
        // Email is pre-filled, focus on name field
        FocusScope.of(context).requestFocus(_nameFocusNode);
      } else {
        // No email pre-filled, focus on email field first
        FocusScope.of(context).requestFocus(_emailFocusNode);
      }
    });
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _passwordNode.dispose();
    _confirmPasswordNode.dispose();
    _emailFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  // Consolidated validation function
  String? _validateField(String fieldName, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName cannot be empty";
    }
    
    switch (fieldName) {
      case "Email":
        const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$';
        if (!RegExp(pattern, caseSensitive: false).hasMatch(value)) {
          return "Enter a valid email";
        }
        break;
      case "Confirm Password":
        if (value != _passwordController.text) {
          return "Passwords do not match";
        }
        break;
    }
    
    return null;
  }
  
  // Simplified debounce validation that only runs if the field needs to be validated
  void _validateWithDebounce(String value, String fieldName, Function(String?) errorSetter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        errorSetter(_validateField(fieldName, value));
      }
    });
  }
  
  // Simplified error setters
  void _setError(String fieldName, String? error) {
    setState(() {
      switch (fieldName) {
        case "Email":
          _emailError = error;
          break;
        case "Name":
          _nameError = error;
          break;
        case "Password":
          _passwordError = error;
          break;
        case "Confirm Password":
          _confirmPasswordError = error;
          break;
      }
    });
  }
  
  // Validate all fields and update error states
  void _validateAllFields() {
    setState(() {
      _emailError = _validateField("Email", _emailController.text);
      _nameError = _validateField("Name", _nameController.text);
      _passwordError = _validateField("Password", _passwordController.text);
      _confirmPasswordError = _validateField("Confirm Password", _confirmPasswordController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
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
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "HomiSwap",
                  textAlign: TextAlign.center,
                  style: appStyle(24, Kolors.kPrimary, FontWeight.bold)
                ),
                
                SizedBox(height: 10.h),
            
                Text(
                  "Hey Homie! Let's get you set up and rolling!",
                  textAlign: TextAlign.center,
                  style: appStyle(13, Kolors.kGray, FontWeight.normal),
                ),
            
                SizedBox(height: 25.h),
            
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      // Email field with inline validation
                      EmailTextField(
                        radius: 25,
                        hintText: "Email",
                        controller: _emailController,
                        focusNode: _emailFocusNode,
                        prefixIcon: const Icon(
                          CupertinoIcons.mail,
                          size: 20,
                          color: Kolors.kGray
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onEditingComplete: () {
                          FocusScope.of(context).requestFocus(_nameFocusNode);
                        },
                        onChanged: (value) => _validateWithDebounce(
                          value, "Email", (error) => _setError("Email", error)
                        ),
                        errorText: _emailError,
                        validator: (value) => _validateField("Email", value),
                      ),
              
                      SizedBox(height: 20.h),
  
                      // Name field with inline validation
                      EmailTextField(
                        radius: 25,
                        hintText: "Full Name",
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        prefixIcon: const Icon(
                          CupertinoIcons.profile_circled,
                          size: 20,
                          color: Kolors.kGray
                        ),
                        keyboardType: TextInputType.name,
                        onEditingComplete: () {
                          FocusScope.of(context).requestFocus(_passwordNode);
                        },
                        onChanged: (value) => _validateWithDebounce(
                          value, "Name", (error) => _setError("Name", error)
                        ),
                        errorText: _nameError,
                        validator: (value) => _validateField("Name", value),
                      ),
              
                      SizedBox(height: 20.h),
              
                      // Password field
                      PasswordField(
                        controller: _passwordController,
                        focusNode: _passwordNode,
                        radius: 25,
                        hintText: "Password",
                        errorText: _passwordError,
                        onChanged: (value) => _validateWithDebounce(
                          value, "Password", (error) => _setError("Password", error)
                        ),
                        onEditingComplete: () {
                          FocusScope.of(context).requestFocus(_confirmPasswordNode);
                        },
                      ),
                    
                      SizedBox(height: 20.h),
              
                      // Confirm password field
                      PasswordField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordNode,
                        radius: 25,
                        hintText: "Confirm Password",
                        errorText: _confirmPasswordError,
                        onChanged: (value) => _validateWithDebounce(
                          value, "Confirm Password", (error) => _setError("Confirm Password", error)
                        ),
                        onEditingComplete: _handleRegistration,
                      ),
                      
                      SizedBox(height: 20.h),
              
                      Consumer<AuthNotifier>(
                        builder: (context, authNotifier, _) {
                          return authNotifier.isRLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  backgroundColor: Kolors.kPrimary,
                                  valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                                ),
                              )
                            : CustomButton(
                                onTap: _handleRegistration,
                                text: "S I G N U P",
                                textSize: 16,
                                btnWidth: ScreenUtil().screenWidth,
                                btnHeight: 50.h,
                                radius: 25,
                              );
                        },
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _handleRegistration() {
    // Validate all fields and update error states
    _validateAllFields();
    
    // Check if there are any validation errors
    if (_emailError != null || _nameError != null || 
        _passwordError != null || _confirmPasswordError != null) {
      return; // Stop execution if there are validation errors
    }

    // Create registration model and submit using camelCase naming
    final model = RegistrationModel(
      email: _emailController.text,
      username: _emailController.text,
      name: _nameController.text,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text
    );

    final data = registrationModelToJson(model);
    context.read<AuthNotifier>().registrationFunc(data, context);
  }
}