import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/const/resource.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/auth/models/email_model.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({super.key});

  @override
  State<EmailSignupPage> createState() => _EmailSignupPageState();
}

class _EmailSignupPageState extends State<EmailSignupPage> {
  late final TextEditingController _emailController = TextEditingController();
  late final FocusNode _emailFocusNode = FocusNode();
  String? _emailError;
  
  // Debounce timer for validation
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Automatically focus on the email field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Request focus and show keyboard
      FocusScope.of(context).requestFocus(_emailFocusNode);
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // Email validation function
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email cannot be empty";
    }
    // More efficient email regex validation
    const pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$';
    if (!RegExp(pattern, caseSensitive: false).hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }
  
  // Validate and update error state
  void _validateAndUpdateError() {
    setState(() {
      _emailError = _validateEmail(_emailController.text);
    });
  }
  
  // Handle validation with debounce
  void _handleValidationWithDebounce(String value) {
    if(_emailError != null) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _emailError = _validateEmail(value);
          });
        }
      });
    }
  }
  
  // Submit email for checking
  void _submitEmail() {
    final validationError = _validateEmail(_emailController.text);
    if (validationError != null) {
      setState(() {
        _emailError = validationError;
      });
      return;
    }
    
    final email = _emailController.text.trim();
    final EmailModel model = EmailModel(email: email);
    final String data = emailModelToJson(model);
    
    context.read<AuthNotifier>().checkEmail(data, context);
  }

  @override
  Widget build(BuildContext context) {
    final authNotifier = context.watch<AuthNotifier>();
    final bool isLoading = authNotifier.isLoading;
    final bool isGoogleLoading = authNotifier.isGoogleLoading;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(
           onTap: () => context.go('/home'),
        ),
        title: Text(
          'Log in or sign up',
          style: appStyle(20, Kolors.kPrimary, FontWeight.bold)
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: ListView(
          children: [
            SizedBox(height: 30.h),
            // Email input field
            EmailTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              radius: 25,
              hintText: "Enter your email address",
              labelText: "Email",
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              prefixIcon: const Icon(CupertinoIcons.mail, size: 20),
              keyboardType: TextInputType.emailAddress,
              onEditingComplete: _validateAndUpdateError,
              onChanged: _handleValidationWithDebounce,
              errorText: _emailError,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitEmail(),
            ),
            SizedBox(height: 20.h),
            
            // Continue button or loading indicator
            isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Kolors.kPrimary,
                    valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                  ),
                )
              : CustomButton(
                  onTap: _submitEmail,
                  text: "C O N T I N U E",
                  textSize: 16,
                  btnWidth: ScreenUtil().screenWidth,
                  btnHeight: 50.h,
                  radius: 25,
                ),
            
            // Divider
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: const Row(
                children: [
                  Expanded(child: Divider(thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("or"),
                  ),
                  Expanded(child: Divider(thickness: 1)),
                ],
              ),
            ),
            
            // Google Sign-In button or loading indicator
            isGoogleLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Kolors.kPrimary,
                    valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                  ),
                )
              : CustomButton(
                  onTap: () => _handleGoogleSignIn(context),
                  text: "Continue with Google",
                  textSize: 16,
                  btnWidth: ScreenUtil().screenWidth,
                  btnHeight: 50.h,
                  radius: 25,
                  borderColor: Kolors.kGray,
                  btnColor: Colors.white,
                  svgPath: R.ASSETS_ICONS_GOOGLE_SVG,
                ),
          ],
        ),
      ),
    );
  }
  
  // Handle Google Sign-In
  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      FocusScope.of(context).unfocus();
      final authNotifier = context.read<AuthNotifier>();
      final router = GoRouter.of(context);

      final success = await authNotifier.signInWithGoogle(context);

      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          router.go('/');
          await Future.delayed(const Duration(milliseconds: 100));
          if (mounted) {
            router.go('/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Google Sign-In failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}