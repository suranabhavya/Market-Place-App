import 'dart:convert';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:provider/provider.dart';

class VerifySchoolEmailPage extends StatefulWidget {
  const VerifySchoolEmailPage({super.key});

  @override
  State<VerifySchoolEmailPage> createState() => _VerifySchoolEmailPageState();
}

class _VerifySchoolEmailPageState extends State<VerifySchoolEmailPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _otpFocusNode = FocusNode();
  
  // Email validation and error states
  String? _emailError;
  Timer? _debounceTimer;
  bool isOtpSent = false;
  bool isSchoolEmailVerified = false;
  String? schoolEmail;
  
  // Resend OTP timer
  int _resendSeconds = 60;
  Timer? _resendTimer;
  bool _canResendOtp = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Set focus to the email field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_emailFocusNode);
    });
  }

  // Load user data from Storage
  void _loadUserData() {
    final userJson = Storage().getString('user');
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      setState(() {
        schoolEmail = userData['school_email'];
        isSchoolEmailVerified = userData['school_email_verified'] ?? false;
      });
    }
  }

  // Start resend timer
  void _startResendTimer() {
    setState(() {
      _canResendOtp = false;
      _resendSeconds = 60;
    });
    
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendSeconds > 0) {
          _resendSeconds--;
        } else {
          _canResendOtp = true;
          timer.cancel();
        }
      });
    });
  }

  // Validation function specifically for edu emails
  String? _validateSchoolEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email cannot be empty";
    }
    
    const pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.edu$';
    if (!RegExp(pattern, caseSensitive: false).hasMatch(value)) {
      return "Enter a valid school email ending with .edu";
    }
    
    return null;
  }
  
  // Validation function for OTP
  String? _validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "OTP cannot be empty";
    }
    
    if (value.length < 6) {
      return "Enter a valid 6-digit OTP";
    }
    
    return null;
  }
  
  // Debounce validation
  void _validateWithDebounce(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _emailError = _validateSchoolEmail(value);
        });
      }
    });
  }

  Future<void> sendOtp(BuildContext context) async {
    final emailError = _validateSchoolEmail(_emailController.text);
    setState(() {
      _emailError = emailError;
    });
    
    if (emailError != null) {
      return;
    }

    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    bool otpSent = await profileNotifier.sendSchoolEmailOtp(_emailController.text.trim());

    if (otpSent) {
      setState(() {
        isOtpSent = true;
      });
      
      // Start the resend timer
      _startResendTimer();
      
      // Move focus to OTP field
      FocusScope.of(context).requestFocus(_otpFocusNode);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Sent to Email"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send OTP. Try again."), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> verifyOtp(BuildContext context) async {
    final otpError = _validateOtp(_otpController.text);
    if (otpError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(otpError), backgroundColor: Colors.red),
      );
      return;
    }

    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    bool otpVerified = await profileNotifier.verifySchoolEmailOtp(
      _emailController.text.trim(),
      _otpController.text.trim(),
    );

    if (otpVerified) {
      // Refresh the UI to show verified status
      _loadUserData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("School Email Verified Successfully"), backgroundColor: Colors.green),
      );

      // Navigate back to previous screen
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP. Try again."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _emailFocusNode.dispose();
    _otpFocusNode.dispose();
    _debounceTimer?.cancel();
    _resendTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access notifier to check loading states
    final profileNotifier = Provider.of<ProfileNotifier>(context);
    
    if (isSchoolEmailVerified) {
      return Scaffold(
        appBar: AppBar(
          leading: const AppBackButton(),
          title: ReusableText(
            text: "Verify School Email",
            style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 80),
                SizedBox(height: 20.h),
                Text(
                  "Your school email ID $schoolEmail is verified.",
                  style: appStyle(16, Kolors.kPrimary, FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10.h),
                Text(
                  "Thank you!",
                  style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: ReusableText(
          text: "Verify School Email",
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // School Email Field
            Text(
              "School Email*",
              style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
            ),
            SizedBox(height: 5.h),
            EmailTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              hintText: "example@school.edu",
              keyboardType: TextInputType.emailAddress,
              radius: 12,
              errorText: _emailError,
              prefixIcon: const Icon(
                CupertinoIcons.mail,
                size: 20,
                color: Kolors.kGray
              ),
              onChanged: (value) => _validateWithDebounce(value),
              validator: _validateSchoolEmail,
              onEditingComplete: () => sendOtp(context),
              floatingLabelBehavior: FloatingLabelBehavior.never,
            ),
            
            SizedBox(height: 20.h),
            
            // Send OTP Button
            profileNotifier.isSendingOtp
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
                  onTap: isOtpSent && !_canResendOtp 
                    ? null // Disable button during cooldown
                    : () => sendOtp(context),
                  text: isOtpSent 
                    ? _canResendOtp 
                      ? "Resend OTP" 
                      : "Resend OTP in $_resendSeconds s"
                    : "Send OTP",
                  textSize: 16,
                  btnHeight: 50.h,
                  radius: 25,
                  btnWidth: ScreenUtil().screenWidth,
                  btnColor: isOtpSent && !_canResendOtp
                    ? Kolors.kGray // Gray out button during cooldown
                    : Kolors.kPrimaryLight,
                ),
            
            if (isOtpSent) ...[
              SizedBox(height: 30.h),
              
              // OTP Field
              Text(
                "Enter OTP*",
                style: appStyle(14, Kolors.kPrimary, FontWeight.bold),
              ),
              SizedBox(height: 5.h),
              EmailTextField(
                controller: _otpController,
                focusNode: _otpFocusNode,
                hintText: "Enter 6-digit OTP",
                keyboardType: TextInputType.number,
                radius: 12,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  size: 20,
                  color: Kolors.kGray
                ),
                onEditingComplete: () => verifyOtp(context),
                floatingLabelBehavior: FloatingLabelBehavior.never,
              ),
              
              SizedBox(height: 20.h),
              
              // Verify OTP Button
              profileNotifier.isVerifyingOtp
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
                    onTap: () => verifyOtp(context),
                    text: "Verify OTP",
                    textSize: 16,
                    btnHeight: 50.h,
                    radius: 25,
                    btnWidth: ScreenUtil().screenWidth,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}