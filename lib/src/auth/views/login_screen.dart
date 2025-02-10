import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/app_routes.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/password_field.dart';
import 'package:marketplace_app/main.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/auth/models/login_model.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  final String? prefilledEmail;

  const LoginPage({super.key, this.prefilledEmail});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController = TextEditingController();
  
  final FocusNode _passwordNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Pre-fill the email if provided
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
    print("text is: ${_emailController.text}");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: AppBackButton(
           onTap: () {
            context.go('/home');
           },
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
                Text(
                  "HomiSwap",
                  textAlign: TextAlign.center,
                  style: appStyle(24, Kolors.kPrimary, FontWeight.bold)
                ),
                
                SizedBox(
                  height: 10.h,
                ),

                Text(
                  "Hey Homie! Welcome back. You've been missed!",
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
                      prefixIcon: const Icon(CupertinoIcons.mail, size: 20, color: Kolors.kGray,),
                      keyboardType: TextInputType.name,
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

                    context.watch<AuthNotifier>().isLoading ?
                    const Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Kolors.kPrimary,
                        valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                      ),
                    ) :
                    CustomButton(
                      onTap: () {
                        LoginModel model = LoginModel(
                          email: _emailController.text,
                          password: _passwordController.text
                        );
                        String data = loginModelToJson(model);
                        print("login data: $data");

                        context.read<AuthNotifier>().loginFunc(data, context);
                      },
                      text: "L O G I N",
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

      // body: ListView(
      //   children: [
      //     SizedBox(
      //       height: 160.h,
      //     ),

      //     Text(
      //       "HomiSwap",
      //       textAlign: TextAlign.center,
      //       style: appStyle(24, Kolors.kPrimary, FontWeight.bold)
      //     ),
          
      //     SizedBox(
      //       height: 10.h,
      //     ),

      //     Text(
      //       "Hey Homie! Welcome back. You've been missed!",
      //       textAlign: TextAlign.center,
      //       style: appStyle(13, Kolors.kGray, FontWeight.normal),
      //     ),

      //     SizedBox(
      //       height: 25.h,
      //     ),

      //     Padding(padding: EdgeInsets.symmetric(horizontal: 20.w),
      //     child: Column(
      //       children: [
      //         EmailTextField(
      //           radius: 25,
      //           focusNode: _passwordNode,
      //           hintText: "Email",
      //           controller: _emailController,
      //           prefixIcon: const Icon(CupertinoIcons.mail, size: 20, color: Kolors.kGray,),
      //           keyboardType: TextInputType.name,
      //           onEditingComplete: () {
      //             FocusScope.of(context).requestFocus(_passwordNode);
      //           },
      //         ),

      //         SizedBox(
      //           height: 25.h,
      //         ),

      //         PasswordField(
      //           controller: _passwordController,
      //           focusNode: _passwordNode,
      //           radius: 25,
      //           hintText: "Password",
      //         ),
            
      //         SizedBox(
      //           height: 20.h,
      //         ),

      //         context.watch<AuthNotifier>().isLoading ?
      //         const Center(
      //           child: CircularProgressIndicator(
      //             backgroundColor: Kolors.kPrimary,
      //             valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
      //           ),
      //         ) :
      //         CustomButton(
      //           onTap: () {
      //             LoginModel model = LoginModel(
      //               email: _emailController.text,
      //               password: _passwordController.text
      //             );
      //             String data = loginModelToJson(model);
      //             print("login data: $data");

      //             context.read<AuthNotifier>().loginFunc(data, context);
      //           },
      //           text: "L O G I N",
      //           btnWidth: ScreenUtil().screenWidth,
      //           btnHeight: 40,
      //           radius: 20,
      //         )
      //       ],
      //     ),)
      //   ],
      // ),
      bottomNavigationBar: SizedBox(
        height: 130.h,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 110),
            child: GestureDetector(
              onTap: () {
                context.push('/register');
              },
              child: Text(
                'Do not have an account? Register a new one',
                style: appStyle(12, Colors.blue, FontWeight.normal),
              ),
            ),
          ),
        ),
      ),
    );
  }
}