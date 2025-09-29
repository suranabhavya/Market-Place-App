import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

/// Centralized HTTP client with timeout configuration and retry logic
class AppHttpClient {
  static final AppHttpClient _instance = AppHttpClient._internal();
  factory AppHttpClient() => _instance;
  AppHttpClient._internal();

  // Timeout configurations
  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(seconds: 30);
  
  // Retry configurations
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 1);

  /// GET request with timeout and retry logic
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _makeRequest(
      () => http.get(url, headers: headers),
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries ?? AppHttpClient.maxRetries,
      url: url.toString(),
    );
  }

  /// POST request with timeout and retry logic
  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _makeRequest(
      () => http.post(url, headers: headers, body: body),
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries ?? AppHttpClient.maxRetries,
      url: url.toString(),
    );
  }

  /// Generic request method with retry logic
  static Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFunction, {
    required Duration timeout,
    required int maxRetries,
    required String url,
  }) async {
    int retryCount = 0;
    
    while (retryCount <= maxRetries) {
      try {
        debugPrint('HTTP Request attempt ${retryCount + 1}/${maxRetries + 1}: $url');
        
        final response = await requestFunction().timeout(timeout);
        
        // Success case
        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('HTTP Request successful: $url (${response.statusCode})');
          return response;
        }
        
        // Server error - retry on 5xx errors
        if (response.statusCode >= 500 && retryCount < maxRetries) {
          debugPrint('Server error ${response.statusCode} for $url, retrying...');
          retryCount++;
          await Future.delayed(retryDelay * retryCount); // Exponential backoff
          continue;
        }
        
        // Client error or max retries reached - return response
        debugPrint('HTTP Request completed with status ${response.statusCode}: $url');
        return response;
        
      } on SocketException catch (e) {
        debugPrint('Network error for $url: $e');
        if (retryCount < maxRetries) {
          retryCount++;
          debugPrint('Retrying network request ${retryCount}/${maxRetries} after ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay * retryCount);
          continue;
        }
        rethrow;
        
      } on Exception catch (e) {
        debugPrint('Request error for $url: $e');
        if (retryCount < maxRetries && _isRetryableError(e)) {
          retryCount++;
          debugPrint('Retrying request ${retryCount}/${maxRetries} after ${retryDelay.inSeconds}s...');
          await Future.delayed(retryDelay * retryCount);
          continue;
        }
        rethrow;
      }
    }
    
    throw Exception('Max retries exceeded for $url');
  }

  /// Check if an error is retryable
  static bool _isRetryableError(Exception error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('timeout') ||
           errorString.contains('connection') ||
           errorString.contains('network') ||
           errorString.contains('socket');
  }

  /// Quick timeout configuration for splash screen background loading
  static Duration get splashTimeout => shortTimeout;
  
  /// Timeout for wishlist operations (longer due to Cloud Run cold starts)
  static Duration get wishlistTimeout => longTimeout;
}
