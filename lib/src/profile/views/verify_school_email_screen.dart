import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/custom_text.dart';

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

  // Function to validate edu email
  void validateEmail(String email) {
    setState(() {
      isEmailValid = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.edu$').hasMatch(email);
    });
  }

  // Simulate sending OTP
  void sendOtp() {
    if (isEmailValid) {
      setState(() {
        isOtpSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Sent to Email"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid EDU email"), backgroundColor: Colors.red),
      );
    }
  }

  // Simulate verifying OTP
  void verifyOtp() {
    if (_otpController.text.trim() == "123456") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("OTP Verified Successfully"), backgroundColor: Colors.green),
      );
      // Navigate to home or next page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP. Try again."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verify School Email"),
        centerTitle: true,
      ),
      body: Padding(
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
              onTap: isEmailValid ? sendOtp : null,
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

              // Verify OTP Button
              CustomButton(
                onTap: verifyOtp,
                text: "Verify OTP",
                btnWidth: double.infinity,
                btnHeight: 50,
                radius: 25,
              ),
            ],
          ],
        ),
      ),
    );
  }
}