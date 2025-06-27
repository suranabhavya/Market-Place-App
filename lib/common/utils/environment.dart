import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

class Environment {
  static String get fileName {
    if (kReleaseMode) {
      return '.env.production';
    }

    return '.env.development';
  }

  static String get apiKey {
    return dotenv.env['API_KEY'] ?? 'API_KEY not found';
  }
  
  static String get iosAppBaseUrl {
    return dotenv.env['IOS_API_BASE_URL'] ?? 'IOS_API_BASE_URL not found';
  }

  static String get androidAppBaseUrl {
    return dotenv.env['ANDROID_API_BASE_URL'] ?? 'ANDROID_API_BASE_URL not found';
  }

  // Platform-aware base URL getter
  static String get baseUrl {
    if (kIsWeb) {
      return iosAppBaseUrl; // Use iOS URL for web
    } else if (Platform.isIOS) {
      return iosAppBaseUrl;
    } else {
      return androidAppBaseUrl; // Use Android URL for Android
    }
  }

  static String get iosWsBaseUrl {
    return dotenv.env['IOS_WS_BASE_URL'] ?? 'IOS_WS_BASE_URL not found';
  }

  static String get androidWsBaseUrl {
    return dotenv.env['ANDROID_WS_BASE_URL'] ?? 'ANDROID_WS_BASE_URL not found';
  }

  // Platform-aware WebSocket URL getter
  static String get wsBaseUrl {
    if (kIsWeb) {
      return iosWsBaseUrl; // Use iOS WS URL for web
    } else if (Platform.isIOS) {
      return iosWsBaseUrl;
    } else {
      return androidWsBaseUrl; // Use Android WS URL for Android
    }
  }

  static String get googleApiKey {
    return dotenv.env['MAPS_API_KEY'] ?? 'MAPS_API_KEY not found';
  }

}
