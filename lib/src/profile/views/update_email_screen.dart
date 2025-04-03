import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class UpdateEmailPage extends StatefulWidget {
  const UpdateEmailPage({super.key});

  @override
  State<UpdateEmailPage> createState() => _UpdateEmailPageState();
}

class _UpdateEmailPageState extends State<UpdateEmailPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  
  // Validation error states
  String? _emailError;
  String? _confirmEmailError;
  
  // Debounce timer for validation
  Timer? _debounceTimer;
  
  // Focus nodes for keyboard navigation
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _confirmEmailFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    
    // Set focus to the email field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocusNode);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _confirmEmailController.dispose();
    _emailFocusNode.dispose();
    _confirmEmailFocusNode.dispose();
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
    } else if (fieldName == "Confirm Email") {
      if (value != _emailController.text) {
        return "Emails do not match";
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
        case "Email":
          _emailError = error;
          break;
        case "Confirm Email":
          _confirmEmailError = error;
          break;
      }
    });
  }
  
  // Validate all fields
  bool _validateAllFields() {
    setState(() {
      _emailError = _validateField("Email", _emailController.text);
      _confirmEmailError = _validateField("Confirm Email", _confirmEmailController.text);
    });
    
    return _emailError == null && _confirmEmailError == null;
  }

  Future<void> _updateEmail(BuildContext context) async {
    if (!_validateAllFields()) {
      return;
    }
    
    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    final String newEmail = _emailController.text.trim();

    final success = await profileNotifier.updateUserDetails({"email": newEmail});

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Email updated successfully"), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Navigate back to account page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update email"), backgroundColor: Colors.red),
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
          text: "Update Email",
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
              "New Email*",
              style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
            ),
            SizedBox(height: 5.h),
            EmailTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              hintText: "Enter new email",
              keyboardType: TextInputType.emailAddress,
              radius: 12,
              errorText: _emailError,
              prefixIcon: const Icon(
                CupertinoIcons.mail,
                size: 20,
                color: Kolors.kGray
              ),
              onChanged: (value) => _validateWithDebounce(
                value, "Email", (error) => _setError("Email", error)
              ),
              validator: (value) => _validateField("Email", value),
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_confirmEmailFocusNode);
              },
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),

            SizedBox(height: 20.h),

            Text(
              "Confirm Email*",
              style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
            ),
            SizedBox(height: 5.h),
            EmailTextField(
              controller: _confirmEmailController,
              focusNode: _confirmEmailFocusNode,
              hintText: "Confirm new email",
              keyboardType: TextInputType.emailAddress,
              radius: 12,
              errorText: _confirmEmailError,
              prefixIcon: const Icon(
                CupertinoIcons.mail,
                size: 20,
                color: Kolors.kGray
              ),
              onChanged: (value) => _validateWithDebounce(
                value, "Confirm Email", (error) => _setError("Confirm Email", error)
              ),
              validator: (value) => _validateField("Confirm Email", value),
              onEditingComplete: () => _updateEmail(context),
              floatingLabelBehavior: FloatingLabelBehavior.never,
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
                      onTap: () => _updateEmail(context),
                      text: "Update Email",
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