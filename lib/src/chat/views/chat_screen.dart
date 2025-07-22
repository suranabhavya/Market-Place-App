import 'dart:convert';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/auth/views/email_signup_screen.dart';
import 'package:marketplace_app/src/entrypoint/controllers/unread_count_notifier.dart';
import 'package:marketplace_app/src/message/views/message_screen.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<dynamic> chats = [];
  bool isLoading = true;
  int? currentUserId;
  WebSocketChannel? channel;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    connectWebSocket();
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

  void connectWebSocket() {
    final String? token = Storage().getString('accessToken');
    if (token == null) return;

    final wsUrl = Environment.iosWsBaseUrl;

    // Connect to the user chats WebSocket endpoint.
    channel = WebSocketChannel.connect(
      Uri.parse("$wsUrl/ws/user_chats/?token=$token"),
    );
    channel!.stream.listen((data) {
      try {
        final decoded = jsonDecode(data);
        // If the payload contains the key "chats", update our local chat list.
        if (decoded.containsKey("chats")) {
          setState(() {
            chats = decoded["chats"];
            isLoading = false;
          });
          // Calculate total unread count from all chats.
          final int totalUnread = (decoded["chats"] as List)
              .fold(0, (int prev, chat) => prev + (chat["unread_messages_count"] ?? 0) as int);
          // Update the global unread count in the notifier.
          if (mounted) {
            Provider.of<UnreadCountNotifier>(context, listen: false)
                .setGlobalUnreadCount(totalUnread);
          }
        }
      } catch (e) {
        debugPrint("Error decoding WS data: $e");
      }
    });
  }

  @override
  void dispose() {
    if (channel != null) {
      channel!.sink.close();
    }
    super.dispose();
  }

  /// Helper to format ISO timestamps to HH:mm format.
  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return "";
    try {
      final dt = DateTime.parse(timestamp);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    String? accessToken = Storage().getString('accessToken');

    if(accessToken == null) {
      return const EmailSignupPage();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: ReusableText(
          text: AppText.kMessaging,
          style: appStyle(16, Kolors.kPrimary, FontWeight.bold)
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : chats.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Kolors.kGray,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        "No conversations yet",
                        style: appStyle(18, Kolors.kDark, FontWeight.w600),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "Start messaging someone to begin a conversation",
                        style: appStyle(14, Kolors.kGray, FontWeight.w400),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
              itemCount: chats.length,
              itemBuilder: (context, index) {
                final chat = chats[index];
                // In the WS response, participants is already a comma-joined string.
                final String displayName = chat["participants"] ?? "Unknown";
                final String lastMessage = chat["last_message"] ?? "No messages yet";
                final int? lastMessageSenderId = chat["last_message_sender_id"];
                final String lastUpdated = formatTimestamp(chat["last_updated"]);
                final int unreadCount = chat["unread_messages_count"] ?? 0;

                String messagePreview;
                if (lastMessageSenderId == currentUserId) {
                  messagePreview = "You: $lastMessage";
                } else {
                  messagePreview = "$displayName: $lastMessage";
                }

                return ListTile(
                  leading: CircleAvatar(
                    radius: 24.w,
                    backgroundColor: Colors.grey,
                    backgroundImage: (chat["sender_profile_photo"] != null &&
                            (chat["sender_profile_photo"] as String).isNotEmpty)
                        ? NetworkImage(chat["sender_profile_photo"])
                        : null,
                    child: (chat["sender_profile_photo"] == null ||
                            (chat["sender_profile_photo"] as String).isEmpty)
                        ? Icon(Icons.person, size: 48.w)
                        : null,
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        displayName,
                        style: appStyle(15, Kolors.kPrimary, FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "$unreadCount",
                            style: appStyle(12, Colors.white, FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          messagePreview,
                          style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                          overflow: TextOverflow.ellipsis
                        ),
                      ),
                      if (lastUpdated.isNotEmpty)
                        Text(
                          lastUpdated,
                          style: appStyle(10, Kolors.kPrimary, FontWeight.normal),
                        ),
                    ],
                  ),
                  onTap: () async {
                    // Get the notifier before async operation
                    final notifier = Provider.of<UnreadCountNotifier>(context, listen: false);
                    
                    // Navigate to the MessagePage. (Marking messages as read will be handled there.)
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessagePage(
                          chatId: chat["id"],
                          participants: displayName,
                          otherParticipantProfilePhoto: chat["sender_profile_photo"],
                          otherParticipantId: chat["sender_id"],
                        ),
                      ),
                    );
                    
                    // Refresh unread count when returning from message screen
                    if (mounted) {
                      try {
                        notifier.refreshUnreadCount();
                      } catch (e) {
                        debugPrint('Error refreshing unread count: $e');
                      }
                    }
                  },
                );
              },
            ),
    );
  }
}