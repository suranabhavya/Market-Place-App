import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/email_textfield.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/auth/models/auth_model.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _mobileFocusNode = FocusNode();
  
  String? _nameError;
  String? _mobileError;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with data from provider after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<ProfileNotifier>(context, listen: false).user;
      if (user != null) {
        _nameController.text = user.name;
        _mobileController.text = user.mobileNumber ?? '';
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update controllers when user data changes
    final user = Provider.of<ProfileNotifier>(context).user;
    if (user != null) {
      if (_nameController.text != user.name) {
        _nameController.text = user.name;
      }
      if (_mobileController.text != (user.mobileNumber ?? '')) {
        _mobileController.text = user.mobileNumber ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _nameFocusNode.dispose();
    _mobileFocusNode.dispose();
    super.dispose();
  }

  // Validation for name field
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Name cannot be empty";
    }
    return null;
  }

  // Validation for mobile number (optional field)
  String? _validateMobile(String? value) {
    if (value != null && value.isNotEmpty) {
      // Simple pattern for international phone numbers
      const pattern = r'^\+?[0-9]{10,15}$';
      if (!RegExp(pattern).hasMatch(value)) {
        return "Enter a valid phone number";
      }
    }
    return null;
  }

  // Validate all fields before update
  bool _validateFields() {
    setState(() {
      _nameError = _validateName(_nameController.text);
      _mobileError = _validateMobile(_mobileController.text);
    });
    
    return _nameError == null && _mobileError == null;
  }

  // Update profile using ProfileNotifier
  Future<void> _updateProfile(BuildContext context) async {
    if (!_validateFields()) {
      return;
    }

    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
    final success = await profileNotifier.updateUserDetails({
      "name": _nameController.text.trim(),
      "mobile_number": _mobileController.text.trim()
    });

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileNotifier>(
      builder: (context, profileNotifier, child) {
        final user = profileNotifier.user;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        return Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: ReusableText(
              text: AppText.kAccount,
              style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Profile Image
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey,
                  backgroundImage: user.profilePhoto != null && user.profilePhoto!.isNotEmpty
                      ? NetworkImage(user.profilePhoto!)
                      : null,
                  child: user.profilePhoto == null || user.profilePhoto!.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
            
                TextButton(
                  onPressed: () async {
                    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);
                    bool success = await profileNotifier.updateProfilePhoto();
            
                    if (success && mounted) {
                      // Force refresh the UI by calling loadUserFromStorage
                      profileNotifier.refreshUserData();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile photo updated successfully"), backgroundColor: Colors.green),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to update profile photo"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Text(
                    "Change Photo",
                    style: appStyle(14, Colors.blue, FontWeight.bold)
                  ),
                ),
            
                const SizedBox(height: 20),
                
                // Account options section
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      // Email Option
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Primary Email",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),
                      ),
                      SizedBox(height: 5.h),
                      AccountOptionButton(
                        onTap: () => context.push('/update-email'),
                        text: user.email,
                        icon: AntDesign.rightcircle,
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Password Option
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Password",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),
                      ),
                      SizedBox(height: 5.h),
                      AccountOptionButton(
                        onTap: () => context.push('/update-password'),
                        text: "****************",
                        icon: AntDesign.rightcircle,
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // School Email Verification Option
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Verify School Email",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),
                      ),
                      SizedBox(height: 5.h),
                      AccountOptionButton(
                        onTap: () => context.push('/profile/verify-school-email'),
                        text: user.schoolEmail != null && user.schoolEmail!.isNotEmpty ? user.schoolEmail! : "-",
                        icon: AntDesign.rightcircle,
                        trailing: user.schoolEmailVerified 
                          ? const Icon(Icons.verified, color: Colors.green, size: 18)
                          : null,
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Name Field
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Name",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),
                      ),
                      SizedBox(height: 5.h),
                      EmailTextField(
                        controller: _nameController,
                        focusNode: _nameFocusNode,
                        hintText: "Name",
                        keyboardType: TextInputType.name,
                        radius: 12,
                        errorText: _nameError,
                        onEditingComplete: () => FocusScope.of(context).requestFocus(_mobileFocusNode),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      
                      SizedBox(height: 20.h),
                      
                      // Phone Number Field
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Primary Phone Number",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),
                      ),
                      SizedBox(height: 5.h),
                      EmailTextField(
                        controller: _mobileController,
                        focusNode: _mobileFocusNode,
                        hintText: "+1-234567890 / +1234567890",
                        keyboardType: TextInputType.phone,
                        radius: 12,
                        errorText: _mobileError,
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                      ),
                      
                      SizedBox(height: 30.h),
                      
                      // Update Profile Button
                      profileNotifier.isUpdating
                        ? Center(
                            child: Container(
                              width: ScreenUtil().screenWidth,
                              height: 50.h,
                              decoration: BoxDecoration(
                                color: Kolors.kPrimaryLight,
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  backgroundColor: Kolors.kPrimary,
                                  valueColor: AlwaysStoppedAnimation<Color>(Kolors.kWhite),
                                ),
                              ),
                            ),
                          )
                        : CustomButton(
                            onTap: () => _updateProfile(context),
                            text: "Update Profile",
                            textSize: 16,
                            btnHeight: 50.h,
                            btnWidth: ScreenUtil().screenWidth,
                            radius: 25,
                          ),
                    ],
                  ),
                ),
                SizedBox(height: 20.h),
              ],
            ),
          ),
        );
      }
    );
  }
}

// Custom button for account options
class AccountOptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData icon;
  final Widget? trailing;
  
  const AccountOptionButton({
    super.key,
    required this.text,
    required this.onTap,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ScreenUtil().screenWidth,
        height: 50.h,
        decoration: BoxDecoration(
          color: Kolors.kOffWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Kolors.kGray.withOpacity(0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  text,
                  style: appStyle(14, Kolors.kDark, FontWeight.normal),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) 
                Row(
                  children: [
                    trailing!,
                    SizedBox(width: 8.w),
                  ],
                ),
              Icon(
                icon,
                color: Kolors.kPrimary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}