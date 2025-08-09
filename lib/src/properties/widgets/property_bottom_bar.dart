import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/login_bottom_sheet.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/auth/controllers/auth_notifier.dart';
import 'package:marketplace_app/src/chat/utils/chat_utils.dart';
import 'package:marketplace_app/src/message/views/message_screen.dart';
import 'package:marketplace_app/src/message/views/message_modal_screen.dart';
import 'package:provider/provider.dart';

class PropertyBottomBar extends StatefulWidget {
  const PropertyBottomBar({
    super.key,
    required this.senderId,
    required this.senderName,
    this.senderProfilePhoto,
    this.isMarketplaceItem = false,
  });

  final int senderId;
  final String senderName;
  final String? senderProfilePhoto;
  final bool isMarketplaceItem;

  @override
  State<PropertyBottomBar> createState() => _PropertyBottomBarState();
}

class _PropertyBottomBarState extends State<PropertyBottomBar> {
  bool isMessageLoading = false;

  @override
  Widget build(BuildContext context) {
    final String? accessToken = Storage().getString('accessToken');
    final currentUser = context.read<AuthNotifier>().getUserData();

    // Don't show the message button if the item is listed by the current user
    if (currentUser?.id == widget.senderId) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 68.h,
      color: Colors.white.withAlpha((0.6 * 255).toInt()),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
        child: ElevatedButton(
          onPressed: isMessageLoading ? null : () async {
            if (isMessageLoading) return; // Prevent double tap
            
            setState(() {
              isMessageLoading = true;
            });

            try {
              if (accessToken == null) {
                loginBottomSheet(context);
                return;
              }
              
              final chatId = await checkExistingChat(widget.senderId);
              if (!context.mounted) return;
              
              if (chatId != null) {
                // Navigate to the existing chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagePage(
                      chatId: chatId,
                      participants: widget.senderName,
                      otherParticipantId: widget.senderId,
                      otherParticipantProfilePhoto: widget.senderProfilePhoto,
                    ),
                  ),
                );
              } else {
                // Show message modal for new chat
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (BuildContext context) {
                    return Container(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: MessageModalContent(senderId: widget.senderId),
                    );
                  },
                );
              }
            } catch (e) {
              debugPrint('Error handling message tap: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to open chat. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            } finally {
              if (mounted) {
                setState(() {
                  isMessageLoading = false;
                });
              }
            }
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(
              isMessageLoading ? Kolors.kPrimary.withOpacity(0.6) : Kolors.kPrimary
            )
          ),
          child: isMessageLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      MaterialCommunityIcons.message,
                      size: 16,
                      color: Kolors.kWhite,
                    ),
                    SizedBox(width: 12.w),
                    ReusableText(
                      text: widget.isMarketplaceItem ? 'Message Seller' : 'Message',
                      style: appStyle(14, Kolors.kWhite, FontWeight.bold),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}