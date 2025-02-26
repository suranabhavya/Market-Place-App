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
import 'package:marketplace_app/common/widgets/custom_text.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/auth/models/auth_model.dart';
import 'package:marketplace_app/src/auth/models/profile_model.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late TextEditingController _nameController;
  late TextEditingController _mobileController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _mobileController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<ProfileNotifier>(context).user;
    if (user != null) {
      // Update controllers if the provider's user has changed
      if (_nameController.text != user.name) {
        _nameController.text = user.name;
      }
      if (_mobileController.text != (user.mobileNumber ?? '')) {
        _mobileController.text = user.mobileNumber ?? '';
      }
    }
  }

  void _loadUserData() {
    final userJson = Storage().getString('user');
    if (userJson != null) {
      final user = User.fromJson(jsonDecode(userJson));
      _nameController = TextEditingController(text: user.name);
      _mobileController = TextEditingController(text: user.mobileNumber ?? '');
    } else {
      _nameController = TextEditingController();
      _mobileController = TextEditingController();
    }
  }

  Future<void> _updateProfile(BuildContext context) async {
    final profileNotifier = Provider.of<ProfileNotifier>(context, listen: false);

    final success = await profileNotifier.updateUserDetails({
      "name": _nameController.text.trim(),
      "mobile_number": _mobileController.text.trim()
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully"), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update profile"), backgroundColor: Colors.red),
      );
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
            
                    if (success) {
                      setState(() {
                        _loadUserData();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile photo updated successfully"), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Failed to update profile photo"), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: const Text("Change Photo", style: TextStyle(color: Colors.blue)),
                ),
            
                const SizedBox(height: 20),
                Divider(
                  color: Kolors.kGrayLight,
                  thickness: 2.h,
                ),
                ListTile(
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    "Primary Email",
                    style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                  ),
                  subtitle: Text(
                    user.email,
                    style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                  ),
                  trailing: const Icon(
                    AntDesign.rightcircle,
                    color: Kolors.kPrimary,
                    size: 22
                  ),
                  onTap: () {
                    context.push('/update-email');
                  },
                ),
                Divider(
                  color: Kolors.kGrayLight,
                  thickness: 2.h,
                ),
                ListTile(
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    "Password",
                    style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                  ),
                  subtitle: Text(
                    "****************",
                    style: appStyle(14, Kolors.kPrimary, FontWeight.normal)
                  ),
                  trailing: const Icon(
                    AntDesign.rightcircle,
                    color: Kolors.kPrimary,
                    size: 22
                  ),
                  onTap: () {
                    context.push('/update-password');
                  },
                ),
                Divider(
                  color: Kolors.kGrayLight,
                  thickness: 2.h,
                ),
                ListTile(
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    "School Email",
                    style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                  ),
                  subtitle: Text(
                    user.schoolEmail.isNotEmpty == true ? user.schoolEmail : "-",
                    style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                  ),
                  trailing: const Icon(
                    AntDesign.rightcircle,
                    color: Kolors.kPrimary,
                    size: 22
                  ),
                  onTap: () {
                    context.push('/profile/verify-school-email');
                  },
                ),
                Divider(
                  color: Kolors.kGrayLight,
                  thickness: 2.h,
                ),
                
                SizedBox(
                  height: 16.h,
                ),
            
                // Name Field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Name",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),
                      ),
                      SizedBox(height: 5.h),
                      CustomTextField(
                        controller: _nameController,
                        maxLines: 1,
                        hintText: "Name",
                        keyboardType: TextInputType.name,
                      ),
                      SizedBox(height: 20.h),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Primary Phone Number",
                          style: appStyle(14, Kolors.kPrimary, FontWeight.bold)
                        ),
                      ),
                      SizedBox(height: 5.h),
                      CustomTextField(
                        controller: _mobileController,
                        maxLines: 1,
                        hintText: "Primary Phone Number",
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),
            
                const SizedBox(height: 20),
            
                // Update Profile Button
                Consumer<ProfileNotifier>(
                  builder: (context, profileNotifier, child) {
                    return profileNotifier.isUpdating
                        ? const Center(child: CircularProgressIndicator())
                        : CustomButton(
                            onTap: () => _updateProfile(context),
                            text: "Update Profile",
                            btnHeight: 45.h,
                            btnWidth: ScreenUtil().screenWidth * 0.9,
                            radius: 16,
                          );
                  },
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}