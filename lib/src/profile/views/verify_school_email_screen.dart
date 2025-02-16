import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/custom_text.dart';
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
  bool isEmailValid = false;
  bool isOtpSent = false;
  bool isVerifying = false;

  // Function to validate edu email
  void validateEmail(String email) {
    setState(() {
      isEmailValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.edu$').hasMatch(email);
    });
  }

  Future<void> sendOtp(BuildContext context) async {
    if (!isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid EDU email"), backgroundColor: Colors.red),
      );
      return;
    }

    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    bool otpSent = await profileNotifier.sendSchoolEmailOtp(_emailController.text.trim());

    if (otpSent) {
      setState(() {
        isOtpSent = true;
      });
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
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the OTP"), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      isVerifying = true;
    });

    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    bool otpVerified = await profileNotifier.verifySchoolEmailOtp(
      _emailController.text.trim(),
      _otpController.text.trim(),
    );

    setState(() {
      isVerifying = false;
    });

    if (otpVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("School Email Verified Successfully"), backgroundColor: Colors.green),
      );

      // Navigate to home or next page
      Navigator.pushNamed(context, '/home');
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileNotifier>(context, listen: false).fetchUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify School Email"),
        centerTitle: true,
      ),
      body: Consumer<ProfileNotifier>(
        builder: (context, profileNotifier, child) {
          final user = profileNotifier.user;

          print("verification: ${user?.school_email_verified}");

          if (user?.school_email_verified == true) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 80),
                  const SizedBox(height: 20),
                  Text(
                    "Your school email ID ${user?.school_email} is verified. Thank you!",
                    style: appStyle(16, Kolors.kPrimary, FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.all(20.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email Field
                const Text("Enter your School Email"),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "example@school.edu",
                    hintStyle: appStyle(14, Kolors.kGray, FontWeight.normal),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(
                      isEmailValid ? Icons.check_circle : Icons.cancel,
                      color: isEmailValid ? Colors.green : Colors.red,
                    ),
                  ),
                  onChanged: validateEmail,
                ),
                const SizedBox(height: 20),

                // Send OTP Button
                CustomButton(
                  onTap: isEmailValid ? () => sendOtp(context) : null,
                  text: "Send OTP",
                  btnWidth: double.infinity,
                  btnHeight: 50,
                  radius: 25,
                ),
                const SizedBox(height: 20),

                if (isOtpSent) ...[
                  // OTP Input Field
                  const Text("Enter OTP"),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: "Enter 6-digit OTP",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  isVerifying
                      ? const Center(child: CircularProgressIndicator())
                      : CustomButton(
                          onTap: () => verifyOtp(context),
                          text: "Verify OTP",
                          btnWidth: double.infinity,
                          btnHeight: 50,
                          radius: 25,
                        ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}