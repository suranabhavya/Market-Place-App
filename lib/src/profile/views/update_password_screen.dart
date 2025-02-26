import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/custom_text.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:provider/provider.dart';

class UpdatePasswordPage extends StatefulWidget {
  const UpdatePasswordPage({super.key});

  @override
  State<UpdatePasswordPage> createState() => _UpdatePasswordPageState();
}

class _UpdatePasswordPageState extends State<UpdatePasswordPage> {
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  
  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword(BuildContext context) async {
    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    final String newPassword = _passwordController.text;
    final String confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fields cannot be empty"), backgroundColor: Colors.red),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match"), backgroundColor: Colors.red),
      );
      return;
    }

    final success = await profileNotifier.updateUserDetails({"password": newPassword});

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // ✅ Navigate back to AccountPage
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update password"), backgroundColor: Colors.red),
      );
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
            SizedBox(height: 8.h),
            CustomTextField(
              controller: _passwordController,
              hintText: "Enter new password",
              keyboardType: TextInputType.name,
            ),

            SizedBox(height: 16.h),
            Text(
              "Confirm Password*",
              style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
            ),
            SizedBox(height: 8.h),
            CustomTextField(
              controller: _confirmPasswordController,
              hintText: "Confirm new password",
              keyboardType: TextInputType.name,
            ),

            SizedBox(height: 24.h),

            Consumer<ProfileNotifier>(
              builder: (context, profileNotifier, child) {
                return profileNotifier.isUpdating
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        onTap: () => _updatePassword(context),
                        text: "Update Password",
                        btnHeight: 35.h,
                        radius: 16,
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