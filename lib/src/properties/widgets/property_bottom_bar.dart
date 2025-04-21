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

class PropertyBottomBar extends StatelessWidget {
  const PropertyBottomBar({
    super.key,
    required this.senderId,
    required this.senderName,
    this.senderProfilePhoto
  });

  final int senderId;
  final String senderName;
  final String? senderProfilePhoto;

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');
    final currentUser = context.read<AuthNotifier>().getUserData();
    
    // Don't show the message button if the property is listed by the current user
    if (currentUser?.id == senderId) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 68.h,
      color: Colors.white.withOpacity(.6),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        child: ElevatedButton(
          onPressed: () async {
            if(accessToken == null) {
              loginBottomSheet(context);
            } else {
              final chatId = await checkExistingChat(senderId);
              if (chatId != null) {
                // Navigate to the existing chat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MessagePage(
                      chatId: chatId,
                      participants: senderName,
                      otherParticipantId: senderId,
                      otherParticipantProfilePhoto: senderProfilePhoto,
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
                      child: MessageModalContent(senderId: senderId),
                    );
                  },
                );
              }
            }
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Kolors.kPrimary)
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                MaterialCommunityIcons.message,
                size: 16,
                color: Kolors.kWhite,
              ),
              SizedBox(
                width: 12.w,
              ),
              ReusableText(
                text: 'Message',
                style: appStyle(14, Kolors.kWhite, FontWeight.bold)
              ),
            ],
          )
        ),
      ),
    );
  }
}