import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:marketplace_app/common/utils/kcolors.dart';
import 'package:marketplace_app/common/widgets/app_style.dart';
import 'package:marketplace_app/common/widgets/back_button.dart';
import 'package:marketplace_app/common/widgets/reusable_text.dart';
import 'package:marketplace_app/src/auth/views/email_signup_screen.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/src/properties/views/public_profile_screen.dart';
import 'package:marketplace_app/src/entrypoint/controllers/unread_count_notifier.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
      Uri.parse("${Environment.iosWsBaseUrl}/ws/chat/${widget.chatId}/?token=$token"),
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
      // Refresh the unread count
      context.read<UnreadCountNotifier>().refreshUnreadCount();
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
                radius: 18.w,
                backgroundColor: Colors.grey,
                backgroundImage: widget.otherParticipantProfilePhoto != null && widget.otherParticipantProfilePhoto!.isNotEmpty
                    ? NetworkImage(widget.otherParticipantProfilePhoto!)
                    : null,
                child: widget.otherParticipantProfilePhoto == null || widget.otherParticipantProfilePhoto!.isEmpty
                    ? Icon(Icons.person, size: 36.w)
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
            TextButton(
              onPressed: () => _scheduleTour(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                backgroundColor: Kolors.kPrimaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(
                "Schedule Tour",
                style: appStyle(14, Colors.white, FontWeight.bold),
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
                      final bool isTourMessage = message['message_type'] == 'tour';
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
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75, // 75% of screen width
                          ),
                          decoration: BoxDecoration(
                            color: isMine ? Kolors.kPrimary : Colors.grey[200],
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isMine ? 16 : 0),
                              bottomRight: Radius.circular(isMine ? 0 : 16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isTourMessage)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Virtual Tour Scheduled',
                                      style: appStyle(
                                        14,
                                        isMine ? Colors.white : Kolors.kPrimary,
                                        FontWeight.normal
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: () async {
                                        final tourLink = message['tour_link'];
                                        if (tourLink != null) {
                                          final uri = Uri.parse(tourLink);
                                          if (await canLaunchUrl(uri)) {
                                            await launchUrl(uri);
                                          }
                                        }
                                      },
                                      child: Text(
                                        'Join Tour',
                                        style: appStyle(
                                          14,
                                          isMine ? Colors.white : Kolors.kPrimary,
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Text.rich(
                                  TextSpan(
                                    children: _parseMessageContent(content),
                                  ),
                                  style: appStyle(
                                    14,
                                    isMine ? Colors.white : Kolors.kPrimary,
                                    FontWeight.normal,
                                  ),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                timeDisplay,
                                style: appStyle(
                                  14,
                                  isMine ? Colors.white.withOpacity(0.7) : Kolors.kPrimary,
                                  FontWeight.normal
                                )
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: 100.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      textCapitalization: TextCapitalization.sentences,
                      style: appStyle(14, Kolors.kPrimary, FontWeight.normal),
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        hintStyle: appStyle(14, Colors.grey, FontWeight.normal),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Container(
                  height: 40.h,
                  width: 40.h,
                  margin: EdgeInsets.only(bottom: 2.h),
                  decoration: const BoxDecoration(
                    color: Kolors.kPrimaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.send, color: Colors.white, size: 25.h),
                    onPressed: sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _parseMessageContent(String content) {
    final List<TextSpan> spans = [];
    final urlRegex = RegExp(r'(https?://[^\s]+)');
    final matches = urlRegex.allMatches(content);

    if (matches.isEmpty) {
      spans.add(TextSpan(text: content));
      return spans;
    }

    int lastIndex = 0;
    for (final match in matches) {
      // Add text before the URL
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: content.substring(lastIndex, match.start)));
      }

      // Add the URL as a clickable span
      final url = match.group(0)!;
      spans.add(
        TextSpan(
          text: url,
          style: appStyle(14, Colors.lightBlue, FontWeight.normal),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
        ),
      );

      lastIndex = match.end;
    }

    // Add any remaining text after the last URL
    if (lastIndex < content.length) {
      spans.add(TextSpan(text: content.substring(lastIndex)));
    }

    return spans;
  }

  Future<void> _scheduleTour() async {
    try {
      // Generate a unique room name for the Jitsi meeting
      final roomName = 'tour_${DateTime.now().millisecondsSinceEpoch}';
      final jitsiUrl = 'https://meet.jit.si/$roomName';
      
      // Send the Jitsi link as a message
      final String? token = Storage().getString('accessToken');
      if (token == null) return;

      final messageJson = jsonEncode({
        "message": 'Tour scheduled! Join the virtual tour here: $jitsiUrl',
        "message_type": "tour",
        "tour_link": jitsiUrl,
      });
      
      channel.sink.add(messageJson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tour scheduled successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling tour: $e')),
        );
      }
    }
  }
}