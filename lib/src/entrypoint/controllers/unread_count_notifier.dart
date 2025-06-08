import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:marketplace_app/common/utils/environment.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class UnreadCountNotifier with ChangeNotifier {
  int _globalUnreadCount = 0;
  int get globalUnreadCount => _globalUnreadCount;
  WebSocketChannel? _channel;
  String? _token;
  bool _isConnected = false;

  UnreadCountNotifier() {
    _initializeConnection();
  }

  void _initializeConnection() {
    _token = Storage().getString('accessToken');
    
    // Only attempt to connect if we have a valid token
    if (_token != null && _token!.isNotEmpty && _token != 'null') {
      try {
        final wsUrl = "${Environment.iosWsBaseUrl}/ws/unread/?token=$_token";
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        _channel!.stream.listen(
          (data) {
            final decoded = jsonDecode(data);
            if (decoded.containsKey("global_unread_count")) {
              _globalUnreadCount = decoded["global_unread_count"];
              notifyListeners();
            }
          },
          onError: (error) {
            debugPrint('WebSocket error: $error');
            _isConnected = false;
          },
          onDone: () {
            debugPrint('WebSocket connection closed');
            _isConnected = false;
          },
        );
        _isConnected = true;
      } catch (e) {
        debugPrint('Failed to connect to WebSocket: $e');
        _isConnected = false;
      }
    } else {
      debugPrint('No valid access token found, skipping WebSocket connection');
    }
  }

  void reconnectIfNeeded() {
    final currentToken = Storage().getString('accessToken');
    
    // If we now have a token and weren't connected before, or if the token changed
    if (currentToken != null && currentToken.isNotEmpty && currentToken != 'null' && 
        (!_isConnected || currentToken != _token)) {
      disposeChannel();
      _initializeConnection();
    }
  }

  void disposeChannel() {
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
      _isConnected = false;
    }
  }

  void refreshUnreadCount() {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode({"refresh": true}));
    }
  }

  void setGlobalUnreadCount(int count) {
    _globalUnreadCount = count;
    notifyListeners();
  }
  
  @override
  void dispose() {
    disposeChannel();
    super.dispose();
  }
}