import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_app/common/services/auth_service.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/entrypoint/controllers/bottom_tab_notifier.dart';
import 'package:marketplace_app/src/profile/controllers/profile_notifier.dart';
import 'package:marketplace_app/src/profile/widgets/tile_widget.dart';
import 'package:marketplace_app/src/wishlist/controllers/wishlist_notifier.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDeleting = false;

  Future<void> _showDeleteAccountConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _DeleteConfirmationDialog(
          onConfirm: () async {
            Navigator.of(dialogContext).pop();
            // Small delay to ensure dialog is fully disposed before deletion
            await Future.delayed(const Duration(milliseconds: 100));
            await _deleteAccount();
          },
          onCancel: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final authService = AuthService();
      bool success = await authService.deleteAccount();

      if (success && mounted) {
        // Clear all local data
        try {
          context.read<WishlistNotifier>().clearWishlist();
          context.read<ProfileNotifier>().clearUserData();
        } catch (e) {
          debugPrint('Error clearing local data: $e');
        }

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account deleted successfully"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to home and reset tab
        context.read<TabIndexNotifier>().setIndex(0);
        context.go('/home');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Failed to delete account. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: ReusableText(
          text: "Settings",
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          SizedBox(height: 20.h),
          
          // Settings Options
          Container(
            color: Kolors.kOffWhite,
            child: Column(
              children: [
                // TODO: Add push notifications settings
                // ProfileTileWidget(
                //   title: 'Push Notifications',
                //   leading: Icons.notifications_outlined,
                //   onTap: () {
                //     // TODO: Implement notification settings
                //   },
                // ),
                
                // Account Deletion Option
                ProfileTileWidget(
                  title: 'Delete Account',
                  leading: MaterialIcons.delete_outline,
                  titleColor: Kolors.kRed,
                  onTap: _showDeleteAccountConfirmation,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 30.h),
          
          // Warning text
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red.shade600,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Account Deletion",
                          style: appStyle(14, Colors.red.shade800, FontWeight.w600),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Deleting your account is permanent and cannot be undone. Your listings and profile will be removed, but your messages will remain visible to other users as 'Deleted User'.",
                          style: appStyle(12, Colors.red.shade700, FontWeight.normal),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_isDeleting) ...[
            SizedBox(height: 30.h),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Kolors.kRed),
            ),
            SizedBox(height: 10.h),
            Text(
              "Deleting account...",
              style: appStyle(14, Kolors.kGray, FontWeight.normal),
            ),
          ],
        ],
      ),
    );
  }
}

class _DeleteConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _DeleteConfirmationDialog({
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<_DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<_DeleteConfirmationDialog> {
  late final TextEditingController _confirmationController;
  bool _canDelete = false;

  @override
  void initState() {
    super.initState();
    _confirmationController = TextEditingController();
  }

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Kolors.kRed,
            size: 24.sp,
          ),
          SizedBox(width: 8.w),
          Text(
            "Delete Account",
            style: appStyle(18, Kolors.kRed, FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "This action is permanent and cannot be undone.",
              style: appStyle(14, Kolors.kDark, FontWeight.w600),
            ),
            SizedBox(height: 12.h),
            Text(
              "Deleting your account will permanently remove:",
              style: appStyle(14, Kolors.kDark, FontWeight.normal),
            ),
            SizedBox(height: 8.h),
            ...[ 
              "• All your property listings",
              "• All your marketplace items", 
              "• Your wishlist items",
              "• Your profile information",
              "• All associated account data",
            ].map((item) => Padding(
              padding: EdgeInsets.only(bottom: 4.h),
              child: Text(
                item,
                style: appStyle(13, Kolors.kGray, FontWeight.normal),
              ),
            )),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      "Your messages will remain visible to other users but will show as 'Deleted User'.",
                      style: appStyle(12, Colors.blue.shade700, FontWeight.normal),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Type "DELETE" to confirm:',
              style: appStyle(14, Kolors.kDark, FontWeight.w600),
            ),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _confirmationController,
              decoration: InputDecoration(
                hintText: "Type DELETE here",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(color: Kolors.kRed),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _canDelete = value.toUpperCase() == "DELETE";
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(
            "Cancel",
            style: appStyle(14, Kolors.kGray, FontWeight.normal),
          ),
        ),
        ElevatedButton(
          onPressed: _canDelete ? widget.onConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _canDelete ? Kolors.kRed : Kolors.kGray,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            "Delete Account",
            style: appStyle(14, Kolors.kWhite, FontWeight.bold),
          ),
        ),
      ],
    );
  }
}