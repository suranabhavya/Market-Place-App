import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/auth/models/email_model.dart';
import 'package:provider/provider.dart';

class EmailSignupPage extends StatefulWidget {
  const EmailSignupPage({super.key});

  @override
  State<EmailSignupPage> createState() => _EmailSignupPageState();
}

class _EmailSignupPageState extends State<EmailSignupPage> {
  late final TextEditingController _emailController = TextEditingController();
  late final FocusNode _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // Email validation function
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Email cannot be empty";
    }
    // Basic email regex validation
    String emailPattern =
        r'^[a-zA-Z0-9.a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
    RegExp regex = RegExp(emailPattern);
    if (!regex.hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(
           onTap: () {
            context.go('/home');
           },
        ),
        title: Text(
          'Log in or sign up',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            SizedBox(height: 30),
            EmailTextField(
              radius: 25,
              focusNode: _emailFocusNode,
              hintText: "Email",
              controller: _emailController,
              prefixIcon: const Icon(
                CupertinoIcons.mail,
                size: 20,
                color: Kolors.kGray
              ),
              keyboardType: TextInputType.emailAddress,
              onEditingComplete: () {
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
            ),
            SizedBox(height: 20),
            context.watch<AuthNotifier>().isLoading ?
            const Center(
              child: CircularProgressIndicator(
                backgroundColor: Kolors.kPrimary,
                valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
              ),
            ) :
            CustomButton(
              onTap: () {
                String? validationError = _validateEmail(_emailController.text);
                if (validationError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(validationError),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                EmailModel model = EmailModel(
                  email: _emailController.text,
                );
                String data = emailModelToJson(model);
                print("data is $data");
                context.read<AuthNotifier>().checkEmail(data, context);
              },
              text: "C O N T I N U E",
              btnWidth: ScreenUtil().screenWidth,
              btnHeight: 50,
              radius: 25,
            ),
            SizedBox(height: 20.h),
            const Row(
              children: [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("or"),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),
            SizedBox(height: 20.h),
            _buildSocialButton(
              icon: MaterialCommunityIcons.apple,
              text: "Continue with Apple",
              onTap: () {
                // Handle Apple login
              },
            ),
            _buildSocialButton(
              icon: MaterialCommunityIcons.google,
              text: "Continue with Google",
              onTap: () {
                // Handle Google login
              },
            ),
            _buildSocialButton(
              icon: Icons.facebook,
              text: "Continue with Facebook",
              onTap: () {
                // Handle Facebook login
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({required IconData icon, required String text, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24, color: Kolors.kPrimary,),
        label: Text(text, ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14),
          textStyle: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}