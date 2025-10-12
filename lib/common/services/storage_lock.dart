import 'dart:async';

/// Global lock to prevent concurrent GetStorage operations
/// This prevents FileSystemException when multiple operations try to access GetStorage simultaneously
class StorageLock {
  static Completer<void>? _lock;

  /// Acquire the storage lock - waits if another operation is in progress
  static Future<void> acquire() async {
    while (_lock != null && !_lock!.isCompleted) {
      await _lock!.future;
    }
    _lock = Completer<void>();
  }

  /// Release the storage lock
  static void release() {
    if (_lock != null && !_lock!.isCompleted) {
      _lock!.complete();
    }
  }
}
