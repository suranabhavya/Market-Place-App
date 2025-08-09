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

  // Set to true since APNS is now configured
  static const bool _enableIOSPushNotifications = true;

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

  /// Call this in main.dart to set up handlers only (does NOT request permission or get token)
  Future<void> initializeHandlersOnly() async {
    await _initializeLocalNotifications();
    
    // Skip Firebase messaging setup on iOS if not enabled
    if (Platform.isIOS && !_enableIOSPushNotifications) {
      debugPrint('Skipping Firebase messaging setup on iOS - APNS not configured');
      return;
    }
    
    await _configureNotificationHandlers();
    // Don't get token here - wait for user authentication
    debugPrint('Push notification handlers initialized - token will be generated after authentication');
  }

  /// Call this after user authentication to get and save FCM token
  Future<void> initializeTokenAfterAuth() async {
    // Skip iOS push notifications if not enabled
    if (Platform.isIOS && !_enableIOSPushNotifications) {
      debugPrint('Skipping FCM token generation on iOS - push notifications disabled');
      return;
    }
    
    debugPrint('Initializing FCM token after authentication...');
    await _getAndSaveToken();
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
    
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
      icon: '@drawable/ic_notification', // Use custom home icon
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
        
        debugPrint('Getting APNS token for iOS...');
        // Request APNS token first for iOS
        String? apnsToken = await _fcm.getAPNSToken();
        debugPrint('APNS Token: $apnsToken');
        
        // If APNS token is not available, wait and retry
        if (apnsToken == null) {
          debugPrint('APNS token not available immediately, waiting...');
          await Future.delayed(const Duration(seconds: 3));
          apnsToken = await _fcm.getAPNSToken();
          debugPrint('APNS Token after wait: $apnsToken');
        }
        
        if (apnsToken == null) {
          debugPrint('APNS token still not available - checking APNS configuration');
          // Continue anyway as FCM token might still work
        }
      }
      
      debugPrint('Getting FCM token...');
      String? token = await _fcm.getToken();
      if (token != null) {
        debugPrint('FCM Token obtained: ${token.substring(0, 20)}...');
        // Save token to storage
        Storage().setString('fcmToken', token);
        await _saveTokenToBackend(token);
        
        // Listen for token refresh
        _fcm.onTokenRefresh.listen((newToken) {
          debugPrint('FCM Token refreshed: ${newToken.substring(0, 20)}...');
          Storage().setString('fcmToken', newToken);
          _saveTokenToBackend(newToken);
        });
      } else {
        debugPrint('Failed to get FCM token');
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      
      // Handle specific iOS APNS errors
      if (Platform.isIOS && (e.toString().contains('apns-token-not-set') || 
          e.toString().contains('APNS'))) {
        debugPrint('APNS configuration issue - please verify:');
        debugPrint('1. Push Notifications capability is enabled in Xcode');
        debugPrint('2. APNS key is uploaded to Firebase Console');
        debugPrint('3. App is signed with valid provisioning profile');
        return;
      }
      
      // Retry logic for network errors
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        debugPrint('Network error, retrying in 5 seconds...');
        await Future.delayed(const Duration(seconds: 5));
        return _getAndSaveToken();
      }
    }
  }

  // Save token to backend (only call this after authentication)
  Future<void> _saveTokenToBackend(String token) async {
    try {
      // Check if user is authenticated
      String? accessToken = Storage().getString('accessToken');
      if (accessToken == null || accessToken.isEmpty || accessToken == 'null') {
        debugPrint('No access token available - skipping FCM device registration');
        return;
      }

      // Get user data
      String? userJson = Storage().getString('user');
      if (userJson == null || userJson.isEmpty) {
        debugPrint('No user data available - skipping FCM device registration');
        return;
      }

      // Get device ID or generate a new UUID if not exists
      String deviceId = Storage().getString('device_id') ?? 
          '${Platform.operatingSystem}_${_uuid.v4()}';

      debugPrint('Device ID: $deviceId');
      
      // Save device ID if it's new
      if (Storage().getString('device_id') == null) {
        debugPrint('Saving device ID');
        Storage().setString('device_id', deviceId);
      }

      debugPrint('Registering FCM device with authentication...');

      String url = '${Environment.baseUrl}/api/notifications/devices/';
      debugPrint('URL: $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $accessToken',
        },
        body: jsonEncode({
          'registration_id': token,
          'device_id': deviceId,
          'active': true,
        }),
      );

      debugPrint('FCM device registration response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('FCM token saved to backend successfully');
      } else {
        debugPrint('Failed to save FCM token: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token to backend: $e');
    }
  }

  // Method to register FCM device after user authentication
  Future<void> registerDeviceAfterAuth() async {
    // Skip iOS push notifications if not enabled
    if (Platform.isIOS && !_enableIOSPushNotifications) {
      debugPrint('Skipping FCM device registration on iOS - push notifications disabled');
      return;
    }

    try {
      debugPrint('Starting FCM device registration after authentication...');
      
      // Initialize token generation and registration
      await initializeTokenAfterAuth();
      
      // If we already have a token, make sure it's registered with the current user
      String? existingToken = Storage().getString('fcmToken');
      if (existingToken != null) {
        debugPrint('Re-registering existing FCM token with current user...');
        await _saveTokenToBackend(existingToken);
      }
      
    } catch (e) {
      debugPrint('Error in FCM device registration after auth: $e');
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