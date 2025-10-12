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
        final wsUrl = "${Environment.wsBaseUrl}/ws/unread/?token=$_token";
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        _channel!.stream.listen(
          (data) {
            try {
              final decoded = jsonDecode(data);
              if (decoded.containsKey("global_unread_count")) {
                _globalUnreadCount = decoded["global_unread_count"];
                notifyListeners();
              }
            } catch (e) {
              debugPrint('Error decoding unread count data: $e');
            }
          },
          onError: (error) {
            debugPrint('Unread count WebSocket error: $error');
            _isConnected = false;
            // Auto-reconnect after a delay
            Future.delayed(const Duration(seconds: 5), () {
              if (_token != null && _token!.isNotEmpty && _token != 'null') {
                _initializeConnection();
              }
            });
          },
          onDone: () {
            _isConnected = false;
            // Auto-reconnect after a delay if we still have a token
            Future.delayed(const Duration(seconds: 3), () {
              if (_token != null && _token!.isNotEmpty && _token != 'null') {
                _initializeConnection();
              }
            });
          },
        );
        _isConnected = true;
      } catch (e) {
        _isConnected = false;
        // Retry after a delay
        Future.delayed(const Duration(seconds: 5), () {
          if (_token != null && _token!.isNotEmpty && _token != 'null') {
            _initializeConnection();
          }
        });
      }
    } else {
      debugPrint('No valid access token found, skipping unread count WebSocket connection');
    }
  }

  void reconnectIfNeeded() {
    final currentToken = Storage().getString('accessToken');
    
    // If we now have a token and weren't connected before, or if the token changed
    if (currentToken != null && currentToken.isNotEmpty && currentToken != 'null' && 
        (!_isConnected || currentToken != _token)) {
      disposeChannel();
      _initializeConnection();
    } else if (currentToken == null || currentToken.isEmpty || currentToken == 'null') {
      // If token is null/empty, reset count and disconnect
      resetUnreadCount();
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
      try {
        _channel!.sink.add(jsonEncode({"refresh": true}));
      } catch (e) {
        // Try to reconnect if there's an error
        _isConnected = false;
        reconnectIfNeeded();
      }
    } else {
      debugPrint('WebSocket not connected, attempting to reconnect for refresh');
      reconnectIfNeeded();
    }
  }

  void setGlobalUnreadCount(int count) {
    _globalUnreadCount = count;
    notifyListeners();
  }
  
  void resetUnreadCount() {
    _globalUnreadCount = 0;
    disposeChannel();
    notifyListeners();
  }
  
  @override
  void dispose() {
    disposeChannel();
    super.dispose();
  }
}