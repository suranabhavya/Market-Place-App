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
  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  
  final FocusNode _passwordNode = FocusNode();
  final FocusNode _confirmPasswordNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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

      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  "HomiSwap",
                  textAlign: TextAlign.center,
                  style: appStyle(24, Kolors.kPrimary, FontWeight.bold)
                ),
                
                SizedBox(
                  height: 10.h,
                ),
            
                Text(
                  "Hey Homie! Let’s get you set up and rolling!",
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Email cannot be empty";
                        }
                        return null;
                      },
                    ),
            
                    SizedBox(
                      height: 25.h,
                    ),

                    EmailTextField(
                      radius: 25,
                      hintText: "Full Name",
                      controller: _nameController,
                      prefixIcon: const Icon(
                        CupertinoIcons.profile_circled,
                        size: 20,
                        color: Kolors.kGray
                      ),
                      keyboardType: TextInputType.name,
                      onEditingComplete: () {
                        FocusScope.of(context).requestFocus(_passwordNode);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Name cannot be empty";
                        }
                        return null;
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
                      height: 25.h,
                    ),
            
                    PasswordField(
                      controller: _confirmPasswordController,
                      focusNode: _confirmPasswordNode,
                      radius: 25,
                      hintText: "Confirm Password",
                    ),
                    
                    SizedBox(height: 25.h),
            
                    context.watch<AuthNotifier>().isRLoading ?
                    const Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Kolors.kPrimary,
                        valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                      ),
                    ) :
                    CustomButton(
                      onTap: () {
                        String? emailError;
                        String? nameError;
                        String? passwordError;
                        String? confirmPasswordError;

                        // Validate Email
                        if (_emailController.text.trim().isEmpty) {
                          emailError = "Email cannot be empty";
                        } else {
                          String emailPattern =
                              r'^[a-zA-Z0-9.a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
                          RegExp regex = RegExp(emailPattern);
                          if (!regex.hasMatch(_emailController.text)) {
                            emailError = "Enter a valid email";
                          }
                        }

                        // Validate Name
                        if (_nameController.text.trim().isEmpty) {
                          nameError = "Name cannot be empty";
                        }

                        // Validate Password
                        if (_passwordController.text.isEmpty) {
                          passwordError = "Password cannot be empty";
                        }

                        // Validate Confirm Password
                        if (_confirmPasswordController.text.isEmpty) {
                          confirmPasswordError = "Confirm Password cannot be empty";
                        } else if (_passwordController.text != _confirmPasswordController.text) {
                          confirmPasswordError = "Passwords do not match";
                        }

                        // Collect all errors
                        List<String> errors = [];
                        if (emailError != null) errors.add(emailError);
                        if (nameError != null) errors.add(nameError);
                        if (passwordError != null) errors.add(passwordError);
                        if (confirmPasswordError != null) errors.add(confirmPasswordError);

                        // Show errors if there are any
                        if (errors.isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: errors.map((e) => Text(e)).toList(),
                              ),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                          return; // Stop execution if errors exist
                        }

                        RegistrationModel model = RegistrationModel(
                          email: _emailController.text,
                          name: _nameController.text,
                          username: _emailController.text,
                          password: _passwordController.text,
                          confirm_password: _confirmPasswordController.text
                        );
            
                        String data = registrationModelToJson(model);

                        print("data is: $data");
            
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
          ),
        ),
      ),
    );
  }
}