import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/utils/kstrings.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/auth/views/email_signup_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/src/properties/views/public_profile_screen.dart';

class MessagePage extends StatefulWidget {
  final int chatId;
  final String participants;
  final String? otherParticipantProfilePhoto;
  final int? otherParticipantId;

  const MessagePage({
    super.key,
    required this.chatId,
    required this.participants,
    this.otherParticipantProfilePhoto,
    this.otherParticipantId,
  });

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  List<dynamic> messages = [];
  bool isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  late WebSocketChannel channel;
  int? currentUserId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
    fetchMessages();
    connectWebSocket();
    markMessagesAsRead();
  }

  void fetchCurrentUser() {
    final String? userJson = Storage().getString('user');
    if (userJson != null) {
      final userData = jsonDecode(userJson);
      setState(() {
        currentUserId = userData['id'];
      });
    }
  }

  void connectWebSocket() {
    final String? token = Storage().getString('accessToken');
    if (token == null) return;
    print("chat_id: ${widget.chatId}");
    channel = WebSocketChannel.connect(
      Uri.parse("ws://127.0.0.1:8000/ws/chat/${widget.chatId}/?token=$token"),
    );
    channel.stream.listen((message) {
      try {
        final decodedMessage = jsonDecode(message);
        setState(() {
          messages.insert(0, decodedMessage);
        });
        // Optionally scroll to the bottom after receiving a message.
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e) {
        debugPrint("Error decoding WS message: $e");
      }
    });
  }

  Future<void> fetchMessages() async {
    final String? token = Storage().getString('accessToken');
    if (token == null) {
      const EmailSignupPage();
      return;
    }
    final response = await http.get(
      Uri.parse('${Environment.iosAppBaseUrl}/api/messaging/chats/${widget.chatId}/messages/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      setState(() {
        messages = List.from(jsonDecode(response.body).reversed); // Reverse for correct order
        isLoading = false;
      });
      debugPrint("messages are: $messages");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load messages"), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> markMessagesAsRead() async {
    final String? token = Storage().getString('accessToken');
    if (token == null) return;
    final response = await http.post(
      Uri.parse('${Environment.iosAppBaseUrl}/api/messaging/chats/${widget.chatId}/read/'),
      headers: {'Authorization': 'Token $token'},
    );
    if (response.statusCode == 200) {
      debugPrint("Messages marked as read");
    } else {
      debugPrint("Failed to mark messages as read");
    }
  }

  void sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;
    final messageJson = jsonEncode({"message": messageText});
    channel.sink.add(messageJson);
    _messageController.clear();
  }
  
  @override
  void dispose() {
    channel.sink.close(ws_status.goingAway);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PublicProfilePage(userId: widget.otherParticipantId!),
                  ),
                );
              },
              child: CircleAvatar(
                radius: 18,
                backgroundImage: widget.otherParticipantProfilePhoto != null && widget.otherParticipantProfilePhoto!.isNotEmpty
                    ? NetworkImage(widget.otherParticipantProfilePhoto!)
                    : null,
                child: widget.otherParticipantProfilePhoto == null || widget.otherParticipantProfilePhoto!.isEmpty
                    ? const Icon(Icons.person, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PublicProfilePage(userId: widget.otherParticipantId!),
                    ),
                  );
                },
                child: ReusableText(
                  text: widget.participants,
                  style: appStyle(16, Kolors.kPrimary, FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final bool isMine = (message['sender'] is int && message['sender'] == currentUserId);
                      // Safely extract content and timestamp.
                      final String content = message['content'] ?? "";
                      final String timestampStr = message['timestamp'] ?? "";
                      final String timeDisplay = timestampStr.isNotEmpty && timestampStr.length >= 16
                          ? timestampStr.substring(11, 16)
                          : "";
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMine ? Colors.blue[200] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(content),
                              Text(
                                timeDisplay,
                                style: const TextStyle(fontSize: 10, color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}