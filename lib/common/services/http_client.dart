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
  // Removed ultra-fast 800ms timeout to avoid premature failures on cold start
  
  // Retry configurations
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 1);
  
  // Shared HTTP client for connection reuse (keep-alive)
  static final http.Client _client = http.Client();

  // Request deduplication
  static final Map<String, Future<http.Response>> _pendingRequests = {};

  /// GET request with timeout and retry logic
  static Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    Duration? timeout,
    int? maxRetries,
  }) async {
    return _makeRequest(
      () => _client.get(url, headers: headers),
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries ?? AppHttpClient.maxRetries,
      url: url.toString(),
    );
  }

  /// Ultra-fast GET request for property loading with deduplication
  static Future<http.Response> getFast(
    Uri url, {
    Map<String, String>? headers,
    bool enableDeduplication = true,
  }) async {
    final urlString = url.toString();
    
    // Check for pending request deduplication
    if (enableDeduplication && _pendingRequests.containsKey(urlString)) {
      return _pendingRequests[urlString]!;
    }
    
    // Create new request without an ultra-fast timeout. We still log duration.
    final requestFuture = _makeRequest(
      () => _client.get(url, headers: headers),
      timeout: defaultTimeout, // rely on sane default; no aggressive cutoffs
      maxRetries: AppHttpClient.maxRetries,
      url: urlString,
    );
    
    // Store pending request for deduplication
    if (enableDeduplication) {
      _pendingRequests[urlString] = requestFuture;
    }
    
    try {
      final response = await requestFuture;
      return response;
    } finally {
      // Remove from pending requests
      if (enableDeduplication) {
        _pendingRequests.remove(urlString);
      }
    }
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
      () => _client.post(url, headers: headers, body: body),
      timeout: timeout ?? defaultTimeout,
      maxRetries: maxRetries ?? AppHttpClient.maxRetries,
      url: url.toString(),
    );
  }

  // Removed _makeFastRequest; getFast now uses the normal request path with connection reuse

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
        final response = await requestFunction().timeout(timeout);
        // Success case
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response;
        }
        
        // Server error - retry on 5xx errors
        if (response.statusCode >= 500 && retryCount < maxRetries) {
          retryCount++;
          await Future.delayed(retryDelay * retryCount); // Exponential backoff
          continue;
        }
        return response;
        
      } on SocketException catch (e) {
        if (retryCount < maxRetries) {
          retryCount++;
          await Future.delayed(retryDelay * retryCount);
          continue;
        }
        rethrow;
        
      } on Exception catch (e) {
        if (retryCount < maxRetries && _isRetryableError(e)) {
          retryCount++;
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
  
  /// Property timeout uses the default request timeout
  static Duration get propertyTimeout => defaultTimeout;
  
  /// Timeout for wishlist operations (longer due to Cloud Run cold starts)
  static Duration get wishlistTimeout => longTimeout;
}
