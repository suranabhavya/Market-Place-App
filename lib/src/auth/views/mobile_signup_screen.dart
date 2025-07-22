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
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  AuthNotifier? _authNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store the provider reference when dependencies change
    _authNotifier = Provider.of<AuthNotifier>(context, listen: false);
  }

  Future<void> _generateOtp(BuildContext context) async {
    if (!mounted) return;
    
    String mobileNumber = _phoneController.text.trim();

    if (mobileNumber.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your mobile number"), backgroundColor: Colors.red),
      );
      return;
    }

    MobileModel model = MobileModel(mobileNumber: mobileNumber);
    String data = mobileModelToJson(model);

    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final success = await _authNotifier?.generateOTP(data);
    
    if (!mounted) return;
    
    if (success == true) {
      router.push('/login/mobile/otp', extra: {"mobileNumber": mobileNumber});
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text("Failed to generate OTP. Try again."), backgroundColor: Colors.red),
      );
    }
  }

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
        title: const Text(
          'Log in or sign up',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ListView(
          children: [
            const SizedBox(height: 30),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: '+1',
                    items: const [
                      DropdownMenuItem(value: '+1', child: Text('United States (+1)')),
                    ],
                    onChanged: (value) {
                      // Handle country code change
                    },
                    isExpanded: true,
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _phoneController,
                  focusNode: _phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "Phone number",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Consumer<AuthNotifier>(
              builder: (context, authNotifier, child) {
                return authNotifier.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          backgroundColor: Kolors.kPrimary,
                          valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                        ),
                      )
                    : CustomButton(
                        onTap: () => _generateOtp(context),
                        text: "C O N T I N U E",
                        btnWidth: ScreenUtil().screenWidth,
                        btnHeight: 50,
                        radius: 25,
                      );
              },
            ),

            const SizedBox(height: 20),
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
            const SizedBox(height: 20),
            _buildSocialButton(
              icon: Icons.email,
              text: "Continue with email",
              onTap: () {
                context.push('/check-email');
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

  Widget _buildSocialButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 24, color: Kolors.kPrimary),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}