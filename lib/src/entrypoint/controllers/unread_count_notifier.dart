import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class UnreadCountNotifier with ChangeNotifier {
  int _globalUnreadCount = 0;
  int get globalUnreadCount => _globalUnreadCount;
  late WebSocketChannel _channel;
  String? _token;

  UnreadCountNotifier() {
    _token = Storage().getString('accessToken');
    final wsUrl = "ws://127.0.0.1:8000/ws/unread/?token=$_token";
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
}