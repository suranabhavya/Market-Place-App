import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/custom_text.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/entrypoint/controllers/unread_count_notifier.dart';
import 'package:provider/provider.dart';

class MobileOtpPage extends StatefulWidget {
  final String mobileNumber;

  const MobileOtpPage({super.key, required this.mobileNumber});

  @override
  State<MobileOtpPage> createState() => _MobileOtpPageState();
}

class _MobileOtpPageState extends State<MobileOtpPage> {
  late final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp(BuildContext context) async {
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    final unreadNotifier = context.read<UnreadCountNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Please enter the OTP"), backgroundColor: Colors.red),
      );
      return;
    }

    final success = await authNotifier.verifyOTP(widget.mobileNumber, otp);

    if (!mounted) return;

    if (success) {
      final exists = await authNotifier.checkMobile(widget.mobileNumber);
      
      if (!mounted) return;
      
      if (exists) {
        // Reconnect WebSocket for unread messages
        try {
          unreadNotifier.reconnectIfNeeded();
        } catch (e) {
          debugPrint('UnreadCountNotifier not available: $e');
        }
        messenger.showSnackBar(
          const SnackBar(content: Text("Login Successful"), backgroundColor: Colors.green),
        );
        router.go('/home');
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text("Invalid OTP. Try again."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.close, color: Colors.black),
        title: const Text(
          "Confirm your number",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Mobile Number Display
            Text(
              "Enter the code we sent over SMS to ${widget.mobileNumber}:",
              style: TextStyle(fontSize: 16.sp),
            ),
            const SizedBox(height: 10),

            // OTP Input Field
            CustomTextField(
              controller: _otpController,
              hintText: "Enter OTP",
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            // Verify Button
            Consumer<AuthNotifier>(
              builder: (context, authNotifier, child) {
                return authNotifier.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : CustomButton(
                        onTap: () => _verifyOtp(context),
                        text: "Continue",
                        btnWidth: ScreenUtil().screenWidth,
                        btnHeight: 50,
                        radius: 25,
                      );
              },
            ),

            const SizedBox(height: 20),

            // Resend OTP
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  context.read<AuthNotifier>().generateOTP(
                        '{"mobile_number": "${widget.mobileNumber}"}',
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("OTP Resent"), backgroundColor: Colors.blue),
                  );
                },
                child: const Text("Didn't get an SMS? Send again"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}