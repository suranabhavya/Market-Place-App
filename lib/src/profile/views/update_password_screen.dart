import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/password_field.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Validation error states
  String? _passwordError;
  String? _confirmPasswordError;
  
  // Debounce timer for validation
  Timer? _debounceTimer;
  
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    
    // Set focus to the password field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_passwordFocusNode);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }
  
  // Validation function for fields
  String? _validateField(String fieldName, String? value) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName cannot be empty";
    }
    
    if (fieldName == "Password") {
      if (value.length < 8) {
        return "Password must be at least 8 characters long";
      }
      
      // Check for at least one uppercase letter, one lowercase letter, and one number
      bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
      bool hasLowercase = value.contains(RegExp(r'[a-z]'));
      bool hasNumber = value.contains(RegExp(r'[0-9]'));
      
      if (!hasUppercase || !hasLowercase || !hasNumber) {
        return "Password must contain uppercase, lowercase, and numbers";
      }
    } else if (fieldName == "Confirm Password") {
      if (value != _passwordController.text) {
        return "Passwords do not match";
      }
    }
    
    return null;
  }
  
  // Debounce validation
  void _validateWithDebounce(String value, String fieldName, Function(String?) errorSetter) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        errorSetter(_validateField(fieldName, value));
      }
    });
  }
  
  // Update error state
  void _setError(String fieldName, String? error) {
    setState(() {
      switch (fieldName) {
        case "Password":
          _passwordError = error;
          break;
        case "Confirm Password":
          _confirmPasswordError = error;
          break;
      }
    });
  }
  
  // Validate all fields
  bool _validateAllFields() {
    setState(() {
      _passwordError = _validateField("Password", _passwordController.text);
      _confirmPasswordError = _validateField("Confirm Password", _confirmPasswordController.text);
    });
    
    return _passwordError == null && _confirmPasswordError == null;
  }

  Future<void> _updatePassword(BuildContext context) async {
    if (!_validateAllFields()) {
      return;
    }
    
    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    final String newPassword = _passwordController.text;

    final success = await profileNotifier.updateUserDetails({"password": newPassword});

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Password updated successfully"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Navigate back to AccountPage
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update password"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: ReusableText(
          text: "Update Password",
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "New password*",
              style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
            ),
            SizedBox(height: 5.h),
            PasswordField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              radius: 12,
              hintText: "Enter new password",
              errorText: _passwordError,
              onChanged: (value) => _validateWithDebounce(
                value, "Password", (error) => _setError("Password", error)
              ),
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
              },
            ),

            SizedBox(height: 20.h),
            
            Text(
              "Confirm Password*",
              style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
            ),
            SizedBox(height: 5.h),
            PasswordField(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              radius: 12,
              hintText: "Confirm new password",
              errorText: _confirmPasswordError,
              onChanged: (value) => _validateWithDebounce(
                value, "Confirm Password", (error) => _setError("Confirm Password", error)
              ),
              onEditingComplete: () => _updatePassword(context),
            ),

            SizedBox(height: 30.h),

            Consumer<ProfileNotifier>(
              builder: (context, profileNotifier, child) {
                return profileNotifier.isUpdating
                  ? Center(
                      child: Container(
                        width: ScreenUtil().screenWidth,
                        height: 50.h,
                        decoration: BoxDecoration(
                          color: Kolors.kPrimaryLight,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            backgroundColor: Kolors.kPrimary,
                            valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                          ),
                        ),
                      ),
                    )
                  : CustomButton(
                      onTap: () => _updatePassword(context),
                      text: "Update Password",
                      textSize: 16,
                      btnHeight: 50.h,
                      radius: 25,
                      btnWidth: ScreenUtil().screenWidth,
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}