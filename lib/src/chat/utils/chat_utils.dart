import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';

Future<int?> checkExistingChat(int userId) async {
  final String? token = Storage().getString('accessToken');
  if (token == null) {
    debugPrint('checkExistingChat: No access token found');
    return null;
  }

  try {
    debugPrint('checkExistingChat: Checking for existing chat with userId: $userId');
    
    final response = await http.get(
      Uri.parse('${Environment.iosAppBaseUrl}/api/messaging/chats/check/$userId/'),
      headers: {'Authorization': 'Token $token'},
    );

    debugPrint('checkExistingChat: Response status: ${response.statusCode}');
    debugPrint('checkExistingChat: Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final chatId = data['chat_id'];
      debugPrint('checkExistingChat: Found existing chat with ID: $chatId');
      return chatId;
    } else {
      debugPrint('checkExistingChat: No existing chat found or error occurred');
      return null;
    }
  } catch (e) {
    debugPrint('checkExistingChat: Error occurred: $e');
    return null;
  }
}

// void showMessageModal(BuildContext context, TextEditingController messageController, Function sendMessage) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     backgroundColor: Colors.black.withOpacity(0.5),
//     builder: (BuildContext context) {
//       return Padding(
//         padding: EdgeInsets.only(
//           bottom: MediaQuery.of(context).viewInsets.bottom,
//         ),
//         child: Container(
//           padding: const EdgeInsets.all(24.0),
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 controller: messageController,
//                 maxLines: 6,
//                 decoration: InputDecoration(
//                   hintText: 'Type your message...',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               CustomButton(
//                 text: 'Send Message',
//                 onTap: () => sendMessage(),
//                 btnWidth: 150.w,
//                 btnHeight: 40.h,
//                 textSize: 16,
//                 radius: 24,
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }

// Future<void> sendMessage(BuildContext context, int userId, String messageText, TextEditingController messageController) async {
//   final trimmedMessage = messageText.trim();
//   if (trimmedMessage.isEmpty) return;

//   final String? token = Storage().getString('accessToken');
//   if (token == null) return;

//   final response = await http.post(
//     Uri.parse('${Environment.iosAppBaseUrl}/api/messaging/chats/create/'),
//     headers: {'Authorization': 'Token $token'},
//     body: jsonEncode({'user_id': userId, 'message': trimmedMessage}),
//   );

//   if (response.statusCode == 201) {
//     final data = jsonDecode(response.body);
//     final chatId = data['chat_id'];
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => MessagePage(
//           chatId: chatId,
//           participants: data['participants'],
//           otherParticipantProfilePhoto: data['profile_photo'],
//           otherParticipantId: userId,
//         ),
//       ),
//     );
//   } else {
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Failed to send message'), backgroundColor: Colors.red),
//     );
//   }
// } 