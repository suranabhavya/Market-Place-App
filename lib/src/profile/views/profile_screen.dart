import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/app_routes.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/help_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/main.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/auth/models/profile_model.dart';
import 'package:marketplace_app/src/auth/views/login_screen.dart';
import 'package:marketplace_app/src/entrypoint/controllers/bottom_tab_notifier.dart';
import 'package:marketplace_app/src/profile/widgets/tile_widget.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    String? accessToken = Storage().getString('accessToken');

    if(accessToken == null) {
      return const LoginPage();
    }

    return Scaffold(
      body: Consumer<AuthNotifier> (
        builder: (context, authNotifier, child) {
          ProfileModel? user = authNotifier.getUserData();
          return ListView(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: 30.h,
                  ),

                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Kolors.kOffWhite,
                    backgroundImage: NetworkImage(
                      AppText.kProfilePic
                    ),
                  ),

                  SizedBox(
                    height: 15.h,
                  ),

                  ReusableText(
                    text: user!.email,
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
                      text: user.username,
                      style: appStyle(14, Kolors.kDark, FontWeight.w600)
                    ),
                  )
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
                        context.push('/orders');
                      },
                    ),

                    ProfileTileWidget(
                      title: 'Privacy Policy',
                      leading: MaterialIcons.policy,
                      onTap: () {
                        context.push('/policy');
                      },
                    ),

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
                    context.read<TabIndexNotifier>().setIndex(0);
                    context.go('/home');
                  },
                ),
              ),
            ],
          );
        }
      )
    );
  }
}