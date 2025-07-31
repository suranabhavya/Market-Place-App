import 'package:flutter/foundation.dart';
import 'package:marketplace_app/common/services/storage.dart';
import 'dart:io';

class DebugUtils {
  static void logStorageState() {
    debugPrint('=== STORAGE DEBUG INFO ===');
    debugPrint('Platform: ${Platform.operatingSystem}');
    debugPrint('Platform version: ${Platform.operatingSystemVersion}');
    
    final storageInfo = Storage().getStorageInfo();
    debugPrint('Storage working: ${storageInfo['working']}');
    debugPrint('Total keys: ${storageInfo['total_keys']}');
    debugPrint('Keys: ${storageInfo['keys']}');
    
    // Check specific auth keys
    final accessToken = Storage().getString('accessToken');
    final user = Storage().getString('user');
    final firstOpen = Storage().getBool('firstOpen');
    final tokenTimestamp = Storage().getInt('tokenTimestamp');
    
    debugPrint('accessToken: ${accessToken != null ? 'present' : 'null'}');
    debugPrint('user: ${user != null ? 'present' : 'null'}');
    debugPrint('firstOpen: $firstOpen');
    debugPrint('tokenTimestamp: $tokenTimestamp');
    
    if (tokenTimestamp != null) {
      final tokenDate = DateTime.fromMillisecondsSinceEpoch(tokenTimestamp);
      final now = DateTime.now();
      final daysDifference = now.difference(tokenDate).inDays;
      debugPrint('Token age: $daysDifference days');
    }
    
    debugPrint('=== END STORAGE DEBUG ===');
  }
  
  static void logAppLifecycle(String event) {
    debugPrint('=== APP LIFECYCLE: $event ===');
    logStorageState();
  }
  
  static void logAuthenticationState() {
    debugPrint('=== AUTHENTICATION STATE ===');
    final accessToken = Storage().getString('accessToken');
    final isExpired = Storage().isTokenExpiredLocally();
    
    debugPrint('Has access token: ${accessToken != null}');
    debugPrint('Token expired locally: $isExpired');
    
    if (accessToken != null) {
      debugPrint('Token length: ${accessToken.length}');
      debugPrint('Token preview: ${accessToken.substring(0, 10)}...');
    }
    
    debugPrint('=== END AUTHENTICATION STATE ===');
  }
} 