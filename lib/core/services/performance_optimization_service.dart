import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service untuk mengoptimalkan performa AI requests
/// Mengatasi frame drops dengan batching dan throttling
class PerformanceOptimizationService {
  static final PerformanceOptimizationService _instance = PerformanceOptimizationService._internal();
  factory PerformanceOptimizationService() => _instance;
  PerformanceOptimizationService._internal();

  // Cache untuk AI responses
  final Map<String, dynamic> _responseCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Request throttling
  final Map<String, Timer> _throttleTimers = {};
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  
  // Configuration
  static const Duration cacheExpiry = Duration(minutes: 10);
  static const Duration throttleDelay = Duration(milliseconds: 500);

  /// Cache AI response untuk mengurangi API calls
  void cacheResponse(String key, dynamic response) {
    _responseCache[key] = response;
    _cacheTimestamps[key] = DateTime.now();
    
    // Cleanup old cache entries
    _cleanupExpiredCache();
  }

  /// Get cached response jika masih valid
  T? getCachedResponse<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;
    
    final isExpired = DateTime.now().difference(timestamp) > cacheExpiry;
    if (isExpired) {
      _responseCache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    
    return _responseCache[key] as T?;
  }

  /// Throttle API requests untuk mengurangi spam
  Future<T> throttleRequest<T>(
    String key,
    Future<T> Function() requestFunction,
  ) async {
    // Check if there's already a pending request for this key
    if (_pendingRequests.containsKey(key)) {
      return await _pendingRequests[key]!.future as T;
    }

    // Create completer for this request
    final completer = Completer<T>();
    _pendingRequests[key] = completer as Completer<dynamic>;

    // Cancel existing timer for this key
    _throttleTimers[key]?.cancel();

    // Create new throttled timer
    _throttleTimers[key] = Timer(throttleDelay, () async {
      try {
        final result = await requestFunction();
        completer.complete(result);
      } catch (error) {
        completer.completeError(error);
      } finally {
        _pendingRequests.remove(key);
        _throttleTimers.remove(key);
      }
    });

    return await completer.future;
  }

  /// Batch multiple requests untuk mengurangi overhead
  Future<List<T>> batchRequests<T>(
    List<Future<T> Function()> requestFunctions,
    {int batchSize = 3}
  ) async {
    final results = <T>[];
    
    for (int i = 0; i < requestFunctions.length; i += batchSize) {
      final batchEnd = (i + batchSize).clamp(0, requestFunctions.length);
      final batch = requestFunctions.sublist(i, batchEnd);
      
      // Execute batch with controlled concurrency
      final batchResults = await Future.wait(
        batch.map((fn) => fn()),
        eagerError: false,
      );
      
      results.addAll(batchResults);
      
      // Add delay between batches to prevent overwhelming the main thread
      if (i + batchSize < requestFunctions.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }
    
    return results;
  }

  /// Execute function on background isolate untuk heavy computations
  static Future<T> executeInBackground<T>(
    T Function() computation,
  ) async {
    return await compute((_) => computation(), null);
  }

  /// Cleanup expired cache entries
  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > cacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _responseCache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Clear all caches
  void clearCache() {
    _responseCache.clear();
    _cacheTimestamps.clear();
  }

  /// Cancel all pending requests
  void cancelAllRequests() {
    for (final timer in _throttleTimers.values) {
      timer.cancel();
    }
    _throttleTimers.clear();
    
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('Request cancelled');
      }
    }
    _pendingRequests.clear();
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    return {
      'cachedResponses': _responseCache.length,
      'pendingRequests': _pendingRequests.length,
      'activeThrottles': _throttleTimers.length,
    };
  }
}
