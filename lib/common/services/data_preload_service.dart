import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:marketplace_app/src/filter/controllers/filter_notifier.dart';
import 'package:marketplace_app/src/marketplace/controllers/marketplace_notifier.dart';

/// Service to handle background data preloading during splash screen
/// Prevents race conditions and duplicate API calls through idempotent design
class DataPreloadService {
  static final DataPreloadService _instance = DataPreloadService._internal();
  factory DataPreloadService() => _instance;
  DataPreloadService._internal();

  // State tracking to prevent race conditions
  bool _isPropertiesLoading = false;
  bool _isPropertiesLoaded = false;
  bool _isMarketplaceLoading = false;
  bool _isMarketplaceLoaded = false;

  // Completion futures for synchronization
  Completer<void>? _propertiesCompleter;
  Completer<void>? _marketplaceCompleter;

  // Public getters for state checking
  bool get isPropertiesLoaded => _isPropertiesLoaded;
  bool get isPropertiesLoading => _isPropertiesLoading;
  bool get isMarketplaceLoaded => _isMarketplaceLoaded;
  bool get isMarketplaceLoading => _isMarketplaceLoading;

  /// Reset state (useful for logout/login scenarios)
  void reset() {
    _isPropertiesLoading = false;
    _isPropertiesLoaded = false;
    _isMarketplaceLoading = false;
    _isMarketplaceLoaded = false;
    _propertiesCompleter = null;
    _marketplaceCompleter = null;
  }

  /// Preload properties (idempotent - can be called multiple times safely)
  ///
  /// Returns immediately if:
  /// - Already loaded: Returns completed Future
  /// - Currently loading: Returns existing Future (waits for completion)
  ///
  /// Only starts new load if neither loaded nor loading
  Future<void> preloadProperties(FilterNotifier filterNotifier) async {
    // Already loaded? Return immediately
    if (_isPropertiesLoaded) {
      return Future.value();
    }

    // Currently loading? Return existing Future to wait
    if (_isPropertiesLoading) {
      return _propertiesCompleter?.future ?? Future.value();
    }

    // Start new load operation
    _isPropertiesLoading = true;
    _propertiesCompleter = Completer<void>();

    try {
      // CRITICAL: Restore filter state FIRST (search key, location from previous session)
      await filterNotifier.restoreFilterState();

      // Initialize cache and location
      await filterNotifier.initializeCache();
      filterNotifier.initializeLocation();

      // Load properties using optimized quick load (will use restored search key/location)
      await filterNotifier.quickLoad();

      _isPropertiesLoaded = true;
      _propertiesCompleter?.complete();
    } catch (e) {
      _propertiesCompleter?.completeError(e);
      rethrow;
    } finally {
      _isPropertiesLoading = false;
    }
  }

  /// Preload marketplace AFTER properties complete (idempotent)
  ///
  /// Ensures proper sequencing: marketplace loads only after properties
  Future<void> preloadMarketplace(
    FilterNotifier filterNotifier,
    MarketplaceNotifier marketplaceNotifier,
  ) async {
    // Already loaded? Return immediately
    if (_isMarketplaceLoaded) {
      return Future.value();
    }

    // Currently loading? Return existing Future to wait
    if (_isMarketplaceLoading) {
      return _marketplaceCompleter?.future ?? Future.value();
    }

    // Start new load operation
    _isMarketplaceLoading = true;
    _marketplaceCompleter = Completer<void>();

    try {
      // Wait for properties to complete first (ensures proper sequencing)
      await preloadProperties(filterNotifier);

      // Now load marketplace
      await marketplaceNotifier.refreshMarketplaceItems();

      _isMarketplaceLoaded = true;
      _marketplaceCompleter?.complete();
    } catch (e) {
      _marketplaceCompleter?.completeError(e);
      rethrow;
    } finally {
      _isMarketplaceLoading = false;
    }
  }

  /// Preload everything in proper sequence (properties first, then marketplace)
  ///
  /// This method runs operations SEQUENTIALLY to avoid GetStorage concurrent access issues
  Future<void> preloadAll(
    FilterNotifier filterNotifier,
    MarketplaceNotifier marketplaceNotifier,
  ) async {
    try {
      // Load properties first (SEQUENTIAL, not parallel)
      await preloadProperties(filterNotifier);
      // Then load marketplace (SEQUENTIAL)
      await preloadMarketplace(filterNotifier, marketplaceNotifier);
    } catch (e) {
      debugPrint('DataPreloadService: Preload sequence failed: $e');
      // Don't rethrow - we want the app to continue even if preload fails
    }
  }
}
