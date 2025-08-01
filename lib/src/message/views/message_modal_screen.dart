import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/src/message/views/message_screen.dart';

void showMessageModal(BuildContext context, int senderId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        padding: const EdgeInsets.all(24.0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: MessageModalContent(senderId: senderId),
      );
    },
  );
}

class MessageModalContent extends StatefulWidget {
  final int senderId;

  const MessageModalContent({super.key, required this.senderId});

  @override
  MessageModalContentState createState() => MessageModalContentState();
}

class MessageModalContentState extends State<MessageModalContent> {
  final TextEditingController _messageController = TextEditingController();
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  void _loadCurrentUser() {
    final String? userJson = Storage().getString('user');
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      setState(() {
        currentUserId = userData['id']; // Get current user ID
      });
    }
  }

  void sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final String? token = Storage().getString('accessToken');
    if (token == null) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Create chat
    final createChatResponse = await http.post(
      Uri.parse('${Environment.iosAppBaseUrl}/api/messaging/chats/create/'),
      headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'participants': [widget.senderId, currentUserId]}),
    );

    if (createChatResponse.statusCode == 201) {
      final chatData = jsonDecode(createChatResponse.body);
      final chatId = chatData['id'];

      // Send message
      final sendMessageResponse = await http.post(
        Uri.parse('${Environment.iosAppBaseUrl}/api/messaging/chats/$chatId/send/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'content': messageText}),
      );

      if (sendMessageResponse.statusCode == 201) {
        final messageData = jsonDecode(sendMessageResponse.body);
        
        // Close the modal first
        navigator.pop();
        // Then navigate to the MessagePage
        navigator.push(
          MaterialPageRoute(
            builder: (context) => MessagePage(
              chatId: chatId,
              participants: messageData['receiver_name'] ?? 'User',
              otherParticipantProfilePhoto: messageData['receiver_profile_photo'],
              otherParticipantId: widget.senderId,
            ),
          ),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Failed to send message'), backgroundColor: Colors.red),
        );
      }
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Failed to create chat'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Type your message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          CustomButton(
            text: 'Send Message',
            onTap: sendMessage,
            btnWidth: double.infinity,
            btnHeight: 40.h,
            textSize: 16,
            radius: 24,
          ),
        ],
      ),
    );
  }
} 