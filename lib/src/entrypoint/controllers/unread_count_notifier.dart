import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class UnreadCountNotifier with ChangeNotifier {
  int _globalUnreadCount = 0;
  int get globalUnreadCount => _globalUnreadCount;
  late WebSocketChannel _channel;
  String? _token;

  UnreadCountNotifier() {
    _token = Storage().getString('accessToken');
    final wsUrl = "${Environment.iosWsBaseUrl}/ws/unread/?token=$_token";
    _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    _channel.stream.listen((data) {
      final decoded = jsonDecode(data);
      if (decoded.containsKey("global_unread_count")) {
        _globalUnreadCount = decoded["global_unread_count"];
        notifyListeners();
      }
    });
  }

  void disposeChannel() {
    _channel.sink.close();
  }

  void refreshUnreadCount() {
    _channel.sink.add(jsonEncode({"refresh": true}));
  }

  void setGlobalUnreadCount(int count) {
    _globalUnreadCount = count;
    notifyListeners();
  }
}