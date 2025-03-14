import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/app_routes.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/help_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/main.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/auth/models/auth_model.dart';
import 'package:marketplace_app/src/auth/models/profile_model.dart';
import 'package:marketplace_app/src/auth/views/email_signup_screen.dart';
import 'package:marketplace_app/src/auth/views/login_screen.dart';
import 'package:marketplace_app/src/entrypoint/controllers/bottom_tab_notifier.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:marketplace_app/src/profile/widgets/tile_widget.dart';
import 'package:marketplace_app/src/properties/controllers/property_notifier.dart';
import 'package:marketplace_app/src/properties/models/property_list_model.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Load the user data when the profile screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileNotifier>(context, listen: false).loadUserFromStorage();
    });
  }

  @override
  Widget build(BuildContext context) {

    String? accessToken = Storage().getString('accessToken');

    if(accessToken == null) {
      return const EmailSignupPage();
    }

    return Scaffold(
      body: Consumer<ProfileNotifier>(
        builder: (context, profileNotifier, child) {
          final user = profileNotifier.user;

          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 30.h,
                  ),

                  Stack(
                    children: [
                      // Profile Picture
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey,
                        backgroundImage: user.profilePhoto != null && user.profilePhoto!.isNotEmpty
                            ? NetworkImage(user.profilePhoto!)
                            : null,
                        child: user.profilePhoto == null || user.profilePhoto!.isEmpty
                            ? const Icon(Icons.person, size: 50, color: Colors.white)
                            : null,
                      ),

                      // Blue Tick Badge if Verified
                      if (user.schoolEmailVerified == true)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 20.sp,
                            ),
                          ),
                        ),
                    ],
                  ),

                  SizedBox(
                    height: 10.h,
                  ),

                  ReusableText(
                    text: user.email,
                    style: appStyle(11, Kolors.kGray, FontWeight.normal)
                  ),

                  SizedBox(
                    height: 7.h,
                  ),

                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 15.w),
                    decoration: BoxDecoration(
                      color: Kolors.kOffWhite,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ReusableText(
                      text: user.name,
                      style: appStyle(14, Kolors.kDark, FontWeight.w600)
                    ),
                  ),

                  SizedBox(
                    height: 10.h,
                  ),

                  // Show verification warning if email is not verified
                  if (user.schoolEmailVerified == false) ...[
                    SizedBox(height: 8.h), // Spacing
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 24.sp),
                        SizedBox(width: 5.w),
                        Text(
                          "Verify your account",
                          style: appStyle(12.sp, Colors.amber.shade700, FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              SizedBox(
                height: 30.h,
              ),

              Container(
                color: Kolors.kOffWhite,
                child: Column(
                  children: [
                    ProfileTileWidget(
                      title: 'My Account',
                      leading: CupertinoIcons.profile_circled,
                      onTap: () {
                        context.push('/account', extra: user);
                      },
                    ),

                    ProfileTileWidget(
                      title: 'My Listings',
                      leading: CupertinoIcons.building_2_fill,
                      onTap: () {
                        final userId = context.read<ProfileNotifier>().user?.id;
                        if (userId != null) {
                          context.push('/my-listings/$userId');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Error fetching user ID")),
                          );
                        }
                      },
                    ),

                    // ProfileTileWidget(
                    //   title: 'Privacy Policy',
                    //   leading: MaterialIcons.policy,
                    //   onTap: () {
                    //     context.push('/policy');
                    //   },
                    // ),

                    ProfileTileWidget(
                      title: 'Help Center',
                      leading: AntDesign.customerservice,
                      onTap: () => showHelpCenterBottomSheet(context),
                    ),

                    ProfileTileWidget(
                      title: 'Settings',
                      leading: MaterialIcons.settings,
                      onTap: () {
                        context.push('/addresses');
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 30.h,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0),
                child: CustomButton(
                  text: "Logout".toUpperCase(),
                  btnColor: Kolors.kRed,
                  btnHeight: 35,
                  btnWidth: ScreenUtil().screenWidth - 60,
                  onTap: () {
                    Storage().removeKey('accessToken');
                    Storage().removeKey('user');
                    context.read<TabIndexNotifier>().setIndex(0);
                    context.go('/home');
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}