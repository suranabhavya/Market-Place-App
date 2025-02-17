import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/custom_text.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:provider/provider.dart';

class UpdateEmailPage extends StatefulWidget {
  const UpdateEmailPage({super.key});

  @override
  State<UpdateEmailPage> createState() => _UpdateEmailPageState();
}

class _UpdateEmailPageState extends State<UpdateEmailPage> {
  late TextEditingController _emailController;
  late TextEditingController _confirmEmailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _confirmEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _confirmEmailController.dispose();
    super.dispose();
  }

  Future<void> _updateEmail(BuildContext context) async {
    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);

    if (_emailController.text != _confirmEmailController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Emails do not match"), backgroundColor: Colors.red),
      );
      return;
    }

    final success = await profileNotifier.updateEmail(_emailController.text);

    if (success) {
      await profileNotifier.fetchUserData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email updated successfully"), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back to account page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update email"), backgroundColor: Colors.red),
      );
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
            SizedBox(height: 8.h),
            CustomTextField(
              controller: _emailController,
              hintText: "Enter new email",
              keyboardType: TextInputType.emailAddress,
            ),
            // const TextField(
            //   decoration: InputDecoration(
            //     border: OutlineInputBorder(),
            //     hintText: "Enter new email",
            //   ),
            // ),

            SizedBox(height: 16.h),

            Text(
              "Confirm Email*",
              style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
            ),
            SizedBox(height: 8.h),
            CustomTextField(
              controller: _confirmEmailController,
              hintText: "Confirm new email",
              keyboardType: TextInputType.emailAddress,
            ),
            // const TextField(
            //   decoration: InputDecoration(
            //     border: OutlineInputBorder(),
            //     hintText: "Confirm email",
            //   ),
            // ),

            SizedBox(height: 24.h),

            Consumer<ProfileNotifier>(
              builder: (context, profileNotifier, child) {
                return profileNotifier.isUpdating
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        onTap: () => _updateEmail(context),
                        text: "Update Email",
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