import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/auth/models/mobile_model.dart';
import 'package:provider/provider.dart';

class MobileSignupPage extends StatefulWidget {
  const MobileSignupPage({super.key});

  @override
  State<MobileSignupPage> createState() => _MobileSignupPageState();
}

class _MobileSignupPageState extends State<MobileSignupPage> {
  late final TextEditingController _phoneController = TextEditingController();
  late final FocusNode _phoneFocusNode = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country/Region Dropdown
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: '+1',
                    items: [
                      DropdownMenuItem(value: '+1', child: Text('United States (+1)')),
                      DropdownMenuItem(value: '+91', child: Text('India (+91)')),
                      // Add more options as needed
                    ],
                    onChanged: (value) {
                      // Handle country code change
                    },
                    isExpanded: true, // Make the dropdown take full width
                  ),
                ),
                SizedBox(height: 10), // Add spacing between dropdown and TextField

                // Phone Number TextField
                TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
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
                MobileModel model = MobileModel(
                  mobile: _phoneController.text,
                );
                String data = mobileModelToJson(model);
                context.read<AuthNotifier>().checkMobile(data, context);
              },
              text: "C O N T I N U E",
              btnWidth: ScreenUtil().screenWidth,
              btnHeight: 50,
              radius: 25,
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Divider(thickness: 1)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("or"),
                ),
                Expanded(child: Divider(thickness: 1)),
              ],
            ),
            SizedBox(height: 20),
            _buildSocialButton(
              icon: Icons.email,
              text: "Continue with email",
              onTap: () {
                context.push('/login/email');
              },
            ),
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