import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'package:http/http.dart' as http;
import 'package:marketplace_app/common/utils/environment.dart';
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _uuid = const Uuid();
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Singleton pattern
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  // TODO: Set this to true when you have a paid Apple Developer account and APNS setup
  static const bool _enableIOSPushNotifications = false;

  /// Call this in home_screen.dart to only request permission (and only once)
  Future<void> requestPermissionIfNeeded() async {
    // Skip iOS push notifications if not enabled
    if (Platform.isIOS && !_enableIOSPushNotifications) {
      debugPrint('iOS push notifications disabled - requires paid Apple Developer account');
      return;
    }

    final box = GetStorage();
    final hasAsked = box.read('notification_permission_asked') ?? false;
    if (!hasAsked) {
      await _requestPermission();
      box.write('notification_permission_asked', true);
    }
  }

  /// Call this in main.dart to set up handlers and token logic (does NOT request permission)
  Future<void> initializeHandlersAndToken() async {
    await _initializeLocalNotifications();
    
    // Skip Firebase messaging setup on iOS if not enabled
    if (Platform.isIOS && !_enableIOSPushNotifications) {
      debugPrint('Skipping Firebase messaging setup on iOS - APNS not configured');
      return;
    }
    
    await _configureNotificationHandlers();
    await _getAndSaveToken();
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(payload);
        _handleNotificationData(data);
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  // Request permission for push notifications
  Future<void> _requestPermission() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    debugPrint('User notification permission status: \\${settings.authorizationStatus}');
    // Configure foreground notification presentation options (iOS)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Configure notification handlers
  Future<void> _configureNotificationHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: \\${message.data}');
      if (message.notification != null) {
        debugPrint('Message notification: \\${message.notification!.title}');
        debugPrint('Message notification body: \\${message.notification!.body}');
        
        // Show local notification when app is in foreground
        _showLocalNotification(message);
      }
    });
    // Handle notifications when app is opened from terminated state
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('Initial message: \\${message.notification?.title}');
        _handleNotificationClick(message);
      }
    });
    // Handle notification when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message clicked: \\${message.notification?.title}');
      _handleNotificationClick(message);
    });
  }

  // Show local notification
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel', // channel id
      'High Importance Notifications', // channel name
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: false,
    );
    
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  // Get and save FCM token
  Future<void> _getAndSaveToken() async {
    try {
      if (Platform.isIOS) {
        // Skip iOS token logic if push notifications are disabled
        if (!_enableIOSPushNotifications) {
          debugPrint('iOS FCM token generation skipped - APNS not configured');
          return;
        }
        
        // Request APNS token first for iOS
        String? apnsToken = await _fcm.getAPNSToken();
        debugPrint('APNS Token: $apnsToken');
        
        // Wait a bit for APNS token to be set
        if (apnsToken == null) {
          debugPrint('APNS token not available - this requires a paid Apple Developer account');
          return;
        }
      }
      
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        // Save token to storage
        Storage().setString('fcmToken', token);
        await _saveTokenToBackend(token);
        // Listen for token refresh
        _fcm.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token refreshed: $newToken');
          Storage().setString('fcmToken', newToken);
          _saveTokenToBackend(newToken);
        });
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      if (e.toString().contains('apns-token-not-set') || 
          e.toString().contains('APNS')) {
        debugPrint('APNS token error - requires paid Apple Developer account for iOS push notifications');
        return;
      }
      
      // Retry logic for other errors
      if (e.toString().contains('apns-token-not-set')) {
        await Future.delayed(const Duration(seconds: 2));
        _getAndSaveToken();
      }
    }
  }

  // Save token to backend
  Future<void> _saveTokenToBackend(String token) async {
    try {
      // Get device ID or generate a new UUID if not exists
      String deviceId = Storage().getString('device_id') ?? 
          '${Platform.operatingSystem}_${_uuid.v4()}';

      debugPrint('Device ID: $deviceId');
      
      // Save device ID if it's new
      if (Storage().getString('device_id') == null) {
        debugPrint('Saving device ID');
        Storage().setString('device_id', deviceId);
      }

      debugPrint('Done Saving device ID');

      String url = '${Environment.baseUrl}/api/notifications/devices/';
      debugPrint('URL: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'registration_id': token,
          'device_id': deviceId,
          'active': true,
          'user_id': Storage().getString('accessToken') != null ? 
              jsonDecode(Storage().getString('user')!)['id'] : null,
        }),
      );

      debugPrint('Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('FCM token saved to backend successfully');
      } else {
        debugPrint('Failed to save FCM token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token to backend: $e');
    }
  }

  // Method to update user association when user logs in
  Future<void> updateUserAssociation() async {
    // Skip iOS push notifications if not enabled
    if (Platform.isIOS && !_enableIOSPushNotifications) {
      debugPrint('Skipping user association update on iOS - push notifications disabled');
      return;
    }

    try {
      String? token = Storage().getString('fcmToken');
      String? deviceId = Storage().getString('device_id');
      String? accessToken = Storage().getString('accessToken');
      
      if (token != null && deviceId != null && accessToken != null) {
        final response = await http.patch(
          Uri.parse('${Environment.iosAppBaseUrl}/api/notifications/devices/$deviceId/link_user/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $accessToken',
          },
          body: jsonEncode({
            'user_id': jsonDecode(Storage().getString('user')!)['id'],
          }),
        );

        if (response.statusCode == 200) {
          debugPrint('User association updated successfully');
        } else {
          debugPrint('Failed to update user association: ${response.statusCode} - ${response.body}');
        }
      }
    } catch (e) {
      debugPrint('Error updating user association: $e');
    }
  }

  // Handle notification click from FCM
  void _handleNotificationClick(RemoteMessage message) {
    if (message.data.isNotEmpty) {
      _handleNotificationData(message.data);
    }
  }

  // Process notification data
  void _handleNotificationData(Map<String, dynamic> data) {
    // Navigation logic based on notification type
    try {
      String? type = data['type'];
      switch (type) {
        case 'new_property':
          String? propertyId = data['property_id'];
          if (propertyId != null) {
            debugPrint('Navigate to property: $propertyId');
            // TODO: Implement navigation to property detail
          }
          break;
        case 'new_marketplace_item':
          String? itemId = data['item_id'];
          if (itemId != null) {
            debugPrint('Navigate to marketplace item: $itemId');
            // TODO: Implement navigation to marketplace item detail
          }
          break;
        case 'new_message':
          String? conversationId = data['conversation_id'];
          if (conversationId != null) {
            debugPrint('Navigate to conversation: $conversationId');
            // TODO: Implement navigation to conversation
          }
          break;
        default:
          debugPrint('Unknown notification type: $type');
      }
    } catch (e) {
      debugPrint('Error handling notification data: $e');
    }
  }
} 