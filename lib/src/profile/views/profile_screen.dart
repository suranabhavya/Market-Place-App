import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:marketplace_app/common/widgets/help_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/auth/views/email_signup_screen.dart';
import 'package:marketplace_app/src/entrypoint/controllers/bottom_tab_notifier.dart';
import 'package:marketplace_app/src/entrypoint/controllers/unread_count_notifier.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:marketplace_app/src/profile/widgets/tile_widget.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load user data when profile screen initializes
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    await Future.delayed(Duration.zero); // Allow widget to build before provider calls
    
    if (mounted) {
      try {
        context.read<ProfileNotifier>().loadUserFromStorage();
      } catch (e) {
        debugPrint("Error loading user data: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _updateProfilePhoto() async {
    final profileNotifier = context.read<ProfileNotifier>();
    bool success = await profileNotifier.updateProfilePhoto();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile photo updated successfully"), 
          backgroundColor: Colors.green
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update profile photo"), 
          backgroundColor: Colors.red
        ),
      );
    }
  }
  
  Future<void> _logout(BuildContext rootContext) async {
    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          "Logout",
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to logout?",
          style: appStyle(14, Kolors.kDark, FontWeight.normal),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              "Cancel",
              style: appStyle(14, Kolors.kGray, FontWeight.normal),
            ),
          ),
          TextButton(
            onPressed: () {
              // First close the dialog
              Navigator.pop(dialogContext);
              
              // Clear user data
              Storage().removeKey('accessToken');
              Storage().removeKey('user');
              
              // Clear wishlist data
              try {
                rootContext.read<WishlistNotifier>().clearWishlist();
              } catch (e) {
                debugPrint('Error clearing wishlist: $e');
              }
              
              // Reset unread count and disconnect WebSocket
              try {
                rootContext.read<UnreadCountNotifier>().resetUnreadCount();
              } catch (e) {
                debugPrint('Error resetting unread count: $e');
              }
              
              // Use root context for navigation
              rootContext.read<TabIndexNotifier>().setIndex(0);
              rootContext.go('/home');
              
              // Then reload user state
              rootContext.read<ProfileNotifier>().loadUserFromStorage();
            },
            child: Text(
              "Logout",
              style: appStyle(14, Kolors.kRed, FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is logged in
    if (Storage().getString('accessToken') == null) {
      return const EmailSignupPage();
    }

    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Kolors.kPrimary),
              ),
            )
          : Consumer<ProfileNotifier>(
              builder: (context, profileNotifier, _) {
                final user = profileNotifier.user;
                
                if (user == null) {
                  return const EmailSignupPage();
                }

                return RefreshIndicator(
                  onRefresh: _loadUserData,
                  color: Kolors.kPrimary,
                  child: ListView(
                    children: [
                      // Profile Header Section
                      Column(
                        children: [
                          SizedBox(height: 30.h),
                          
                          // Profile Picture with Verification Badge
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _updateProfilePhoto,
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.grey,
                                  backgroundImage: user.profilePhoto?.isNotEmpty == true
                                      ? NetworkImage(user.profilePhoto!)
                                      : null,
                                  child: user.profilePhoto?.isEmpty ?? true
                                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                                      : null,
                                ),
                              ),
                              
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
                          
                          SizedBox(height: 10.h),
                          
                          ReusableText(
                            text: user.email,
                            style: appStyle(11, Kolors.kGray, FontWeight.normal)
                          ),
                          
                          SizedBox(height: 7.h),
                          
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
                          
                          // Email Verification Warning
                          if (user.schoolEmailVerified == false) ...[
                            SizedBox(height: 8.h),
                            InkWell(
                              onTap: () => context.push('/profile/verify-school-email'),
                              child: Row(
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
                            ),
                          ],
                        ],
                      ),
                      
                      SizedBox(height: 30.h),
                      
                      // Profile Options Section
                      Container(
                        color: Kolors.kOffWhite,
                        child: Column(
                          children: [
                            ProfileTileWidget(
                              title: 'My Account',
                              leading: CupertinoIcons.profile_circled,
                              onTap: () => context.push('/account', extra: user),
                            ),
                            
                            ProfileTileWidget(
                              title: 'My Listings',
                              leading: CupertinoIcons.building_2_fill,
                              onTap: () {
                                final userId = user.id;
                                context.push('/my-listings/$userId');
                              },
                            ),

                            ProfileTileWidget(
                              title: 'My Marketplace',
                              leading: CupertinoIcons.shopping_cart,
                              onTap: () {
                                final userId = user.id;
                                context.push('/my-marketplace/$userId');
                              },
                            ),
                            
                            ProfileTileWidget(
                              title: 'Help Center',
                              leading: AntDesign.customerservice,
                              onTap: () => showHelpCenterBottomSheet(context),
                            ),
                            
                            // ProfileTileWidget(
                            //   title: 'Settings',
                            //   leading: MaterialIcons.settings,
                            //   onTap: () => context.push('/settings'),
                            // ),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 30.h),
                      
                      // Logout Button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: CustomButton(
                          text: "L O G O U T",
                          textSize: 16,
                          btnColor: Kolors.kRed,
                          btnHeight: 35.h,
                          radius: 25,
                          btnWidth: ScreenUtil().screenWidth,
                          onTap: () => _logout(context),
                        ),
                      ),
                      
                      SizedBox(height: 20.h),
                    ],
                  ),
                );
              },
            ),
    );
  }
}