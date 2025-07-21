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

  // Firebase Configuration
  static String get firebaseWebApiKey {
    return dotenv.env['FIREBASE_WEB_API_KEY'] ?? 'FIREBASE_WEB_API_KEY not found';
  }

  static String get firebaseWebAppId {
    return dotenv.env['FIREBASE_WEB_APP_ID'] ?? 'FIREBASE_WEB_APP_ID not found';
  }

  static String get firebaseMessagingSenderId {
    return dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? 'FIREBASE_MESSAGING_SENDER_ID not found';
  }

  static String get firebaseProjectId {
    return dotenv.env['FIREBASE_PROJECT_ID'] ?? 'FIREBASE_PROJECT_ID not found';
  }

  // Google OAuth Configuration
  static String get googleOAuthServerClientId {
    return dotenv.env['GOOGLE_OAUTH_SERVER_CLIENT_ID'] ?? 'GOOGLE_OAUTH_SERVER_CLIENT_ID not found';
  }

  static String get googleOAuthRedirectScheme {
    return dotenv.env['GOOGLE_OAUTH_REDIRECT_SCHEME'] ?? 'GOOGLE_OAUTH_REDIRECT_SCHEME not found';
  }

  // Android Keystore Configuration (for CI/CD)
  static String get androidKeystorePassword {
    return dotenv.env['ANDROID_KEYSTORE_PASSWORD'] ?? 'ANDROID_KEYSTORE_PASSWORD not found';
  }

  static String get androidKeyPassword {
    return dotenv.env['ANDROID_KEY_PASSWORD'] ?? 'ANDROID_KEY_PASSWORD not found';
  }

  static String get androidKeyAlias {
    return dotenv.env['ANDROID_KEY_ALIAS'] ?? 'ANDROID_KEY_ALIAS not found';
  }

  static String get androidKeystorePath {
    return dotenv.env['ANDROID_KEYSTORE_PATH'] ?? 'ANDROID_KEYSTORE_PATH not found';
  }
}
