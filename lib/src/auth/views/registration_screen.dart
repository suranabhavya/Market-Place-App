import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/app_routes.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/password_field.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/auth/models/registration_model.dart';
import 'package:provider/provider.dart';

class RegistrationPage extends StatefulWidget {
  final String? prefilledEmail;

  const RegistrationPage({super.key, this.prefilledEmail});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  
  late final TextEditingController _emailController;
  late final TextEditingController _usernameController = TextEditingController();
  late final TextEditingController _passwordController = TextEditingController();
  late final TextEditingController _confirmPasswordController = TextEditingController();
  
  final FocusNode _passwordNode = FocusNode();
  final FocusNode _confirmPasswordNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-fill the email if provided
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
    print("text is: ${_emailController.text}");
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordNode.dispose();
    _confirmPasswordNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const AppBackButton(),
      ),

      body: ListView(
        children: [
          SizedBox(
            height: 160.h,
          ),

          Text(
            "Lease Me",
            textAlign: TextAlign.center,
            style: appStyle(24, Kolors.kPrimary, FontWeight.bold)
          ),
          
          SizedBox(
            height: 10.h,
          ),

          Text(
            "Hi! Welcome back. You've been missed!",
            textAlign: TextAlign.center,
            style: appStyle(13, Kolors.kGray, FontWeight.normal),
          ),

          SizedBox(
            height: 25.h,
          ),

          Padding(padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              EmailTextField(
                radius: 25,
                hintText: "Username",
                controller: _usernameController,
                prefixIcon: const Icon(
                  CupertinoIcons.profile_circled,
                  size: 20,
                  color: Kolors.kGray
                ),
                keyboardType: TextInputType.name,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(_passwordNode);
                },
              ),

              SizedBox(
                height: 25.h,
              ),

              EmailTextField(
                radius: 25,
                focusNode: _passwordNode,
                hintText: "Email",
                controller: _emailController,
                prefixIcon: const Icon(
                  CupertinoIcons.mail,
                  size: 20,
                  color: Kolors.kGray
                ),
                keyboardType: TextInputType.emailAddress,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(_passwordNode);
                },
              ),

              SizedBox(
                height: 25.h,
              ),

              PasswordField(
                controller: _passwordController,
                focusNode: _passwordNode,
                radius: 25,
                hintText: "Password",
              ),
            
              SizedBox(
                height: 20.h,
              ),

              PasswordField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordNode,
                radius: 25,
                hintText: "Confirm Password",
              ),
              
              SizedBox(height: 20.h),

              context.watch<AuthNotifier>().isRLoading ?
              const Center(
                child: CircularProgressIndicator(
                  backgroundColor: Kolors.kPrimary,
                  valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                ),
              ) :
              CustomButton(
                onTap: () {
                  RegistrationModel model = RegistrationModel(
                    email: _emailController.text,
                    username: _usernameController.text,
                    password: _passwordController.text,
                    re_password: _confirmPasswordController.text
                  );

                  String data = registrationModelToJson(model);

                  context.read<AuthNotifier>().registrationFunc(data, context);
                },
                text: "S I G N U P",
                btnWidth: ScreenUtil().screenWidth,
                btnHeight: 40,
                radius: 20,
              )
            ],
          ),)
        ],
      ),
    );
  }
}