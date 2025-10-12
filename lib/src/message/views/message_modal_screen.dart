import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/widgets/custom_button.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:marketplace_app/src/message/views/message_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  bool isLoading = false;

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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void sendMessage() async {
    if (isLoading) return; // Prevent double tap
    
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String? token = Storage().getString('accessToken');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User data not loaded. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint('Creating chat with senderId: ${widget.senderId}, currentUserId: $currentUserId');
      
      // Create chat
      final createChatResponse = await http.post(
        Uri.parse('${Environment.iosAppBaseUrl}/api/messaging/chats/create/'),
        headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'participants': [widget.senderId, currentUserId]}),
      );

      debugPrint('Create chat response status: ${createChatResponse.statusCode}');
      debugPrint('Create chat response body: ${createChatResponse.body}');

      if (createChatResponse.statusCode == 201) {
        final chatData = jsonDecode(createChatResponse.body);
        final chatId = chatData['id'];

        debugPrint('Chat created successfully with ID: $chatId');

        // Send message using WebSocket approach instead of HTTP API
        try {
          // Connect to WebSocket and send message
          final wsUrl = Environment.wsBaseUrl;
          final wsChannel = WebSocketChannel.connect(
            Uri.parse("$wsUrl/ws/chat/$chatId/?token=$token"),
          );
          
          // Wait a moment for connection then send message
          await Future.delayed(const Duration(milliseconds: 500));
          
          final messageJson = jsonEncode({"message": messageText});
          wsChannel.sink.add(messageJson);
          
          debugPrint('Message sent via WebSocket successfully');
          
          // Close WebSocket connection
          await wsChannel.sink.close();
          
          // Get receiver information from the chat participants
          String receiverName = 'User';
          String? receiverProfilePhoto;
          
          try {
            final participants = chatData['participants'] as List<dynamic>;
            for (final participant in participants) {
              if (participant['id'] != currentUserId) {
                receiverName = participant['name'] ?? 'User';
                break;
              }
            }
          } catch (e) {
            debugPrint('Error parsing participants: $e');
          }

          // Close the modal first
          if (mounted) {
            Navigator.of(context).pop();
            
            // Add small delay to ensure modal is closed before navigation
            await Future.delayed(const Duration(milliseconds: 100));
            
            // Navigate to the MessagePage
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MessagePage(
                    chatId: chatId,
                    participants: receiverName,
                    otherParticipantProfilePhoto: receiverProfilePhoto,
                    otherParticipantId: widget.senderId,
                  ),
                ),
              );
            }
          }
        } catch (wsError) {
          debugPrint('WebSocket send failed: $wsError, falling back to HTTP API');
          
          // Fallback to original HTTP API approach
          final sendMessageResponse = await http.post(
            Uri.parse('${Environment.iosAppBaseUrl}/api/messaging/chats/$chatId/send/'),
            headers: {'Authorization': 'Token $token', 'Content-Type': 'application/json'},
            body: jsonEncode({'content': messageText}),
          );

          debugPrint('Send message response status: ${sendMessageResponse.statusCode}');
          debugPrint('Send message response body: ${sendMessageResponse.body}');

          if (sendMessageResponse.statusCode == 201) {
            final messageData = jsonDecode(sendMessageResponse.body);
            
            debugPrint('Message sent successfully via HTTP API');
            
            // Close the modal first
            if (mounted) {
              Navigator.of(context).pop();
              
              // Add small delay to ensure modal is closed before navigation
              await Future.delayed(const Duration(milliseconds: 100));
              
              // Then navigate to the MessagePage
              if (mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => MessagePage(
                      chatId: chatId,
                      participants: messageData['receiver_name'] ?? 'User',
                      otherParticipantProfilePhoto: messageData['receiver_profile_photo'],
                      otherParticipantId: widget.senderId,
                    ),
                  ),
                );
              }
            }
          } else {
            debugPrint('Failed to send message via HTTP API. Status: ${sendMessageResponse.statusCode}');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to send message. Status: ${sendMessageResponse.statusCode}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } else {
        debugPrint('Failed to create chat. Status: ${createChatResponse.statusCode}, Body: ${createChatResponse.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create chat. Status: ${createChatResponse.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }
} 