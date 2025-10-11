import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:async';

class Storage {
  static const String _boxName = 'homiswap_storage';
  static GetStorage? _box;

  // Initialize storage with better error handling
  static Future<void> initialize() async {
    try {
      await GetStorage.init(_boxName);
      _box = GetStorage(_boxName);
      // Test storage immediately after initialization
      await _testStorage();
    } catch (e) {
      // Fallback to default initialization
      _box = GetStorage();
    }
  }
  
  // Test storage functionality
  static Future<void> _testStorage() async {
    try {
      final testKey = '_storage_test_${DateTime.now().millisecondsSinceEpoch}';
      const testValue = 'test_value';
      
      _box!.write(testKey, testValue);
      await _box!.remove(testKey);
    } catch (e) {
      debugPrint('Storage test error: $e');
    }
  }
  
  static GetStorage get _instance {
    _box ??= GetStorage();
    return _box!;
  }

  void clear() {
    try {
      _instance.erase();
    } catch (e) {
      debugPrint('Error clearing storage: $e');
    }
  }

  void setString(String key, String value) {
    try {
      _instance.write(key, value);
    } catch (e) {
      debugPrint('Error saving $key to storage: $e');
    }
  }

  String? getString(String key) {
    try {
      final value = _instance.read(key);
      return value;
    } catch (e) {
      return null;
    }
  }

  void setBool(String key, bool value) {
    try {
      _instance.write(key, value);
    } catch (e) {
      debugPrint('Error saving bool $key to storage: $e');
    }
  }

  bool? getBool(String key) {
    try {
      final value = _instance.read(key);
      return value;
    } catch (e) {
      return null;
    }
  }

  void setInt(String key, int value) {
    try {
      _instance.write(key, value);
    } catch (e) {
      debugPrint('Error saving int $key to storage: $e');
    }
  }

  int? getInt(String key) {
    try {
      final value = _instance.read(key);
      return value;
    } catch (e) {
      return null;
    }
  }

  Future<void> removeKey(String key) async {
    try {
      await _instance.remove(key);
    } catch (e) {
      debugPrint('Error removing $key from storage: $e');
    }
  }

  // Store token with timestamp
  void setTokenWithTimestamp(String token) {
    try {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      setString('accessToken', token);
      setInt('tokenTimestamp', currentTime);
    } catch (e) {
      debugPrint('Error saving token with timestamp: $e');
    }
  }

  // Check if token is expired locally (client-side check)
  bool isTokenExpiredLocally() {
    try {
      final tokenTimestamp = getInt('tokenTimestamp');
      if (tokenTimestamp == null) {
        return true;
      }
      
      final tokenDate = DateTime.fromMillisecondsSinceEpoch(tokenTimestamp);
      final now = DateTime.now();
      final daysDifference = now.difference(tokenDate).inDays;
      
      return daysDifference >= 30;
    } catch (e) {
      return true; // Consider expired if there's an error
    }
  }

  // Clear authentication data
  Future<void> clearAuthData() async {
    try {
      await removeKey('accessToken');
      await removeKey('user');
      await removeKey('tokenTimestamp');
    } catch (e) {
      debugPrint('Error clearing auth data: $e');
    }
  }

  // Check if storage is working properly
  bool isStorageWorking() {
    try {
      const testKey = '_storage_test';
      const testValue = 'test_value';
      
      setString(testKey, testValue);
      final retrieved = getString(testKey);
      removeKey(testKey);
      
      return retrieved == testValue;
    } catch (e) {
      return false;
    }
  }

  // Get storage info for debugging
  Map<String, dynamic> getStorageInfo() {
    try {
      final keys = _instance.getKeys();
      final info = <String, dynamic>{
        'total_keys': keys.length,
        'keys': keys.toList(),
        'working': isStorageWorking(),
      };
      
      // Add some key values for debugging (without sensitive data)
      for (final key in keys) {
        if (!key.contains('token') && !key.contains('user') && !key.contains('password')) {
          final value = _instance.read(key);
          info[key] = value != null ? 'present' : 'null';
        }
      }
      
      return info;
    } catch (e) {
      return {'error': e.toString()};
    }
  }
  
  // Force storage persistence (Android-specific)
  Future<void> forcePersist() async {
    if (Platform.isAndroid) {
      try {
        // Write a dummy value to force persistence
        const persistKey = '_force_persist';
        final persistValue = DateTime.now().millisecondsSinceEpoch.toString();
        
        _instance.write(persistKey, persistValue);
        await Future.delayed(const Duration(milliseconds: 100));
        await _instance.remove(persistKey);
      } catch (e) {
        debugPrint('Error forcing storage persistence: $e');
      }
    }
  }
}
