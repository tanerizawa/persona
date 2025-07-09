import 'package:flutter/foundation.dart';

import 'logging_service.dart';

/// Service for performance optimization and background processing
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  final LoggingService _logger = LoggingService();

  /// Offload heavy computation to background isolate
  static Future<T> offloadToBackground<T>(T Function() computation) async {
    try {
      return await compute(_computeWrapper, computation);
    } catch (e) {
      // Fallback to main thread if isolate fails
      return computation();
    }
  }

  /// Wrapper function for compute
  static T _computeWrapper<T>(T Function() computation) {
    return computation();
  }

  /// Execute computation with performance tracking
  Future<T> executeWithTracking<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      final duration = stopwatch.elapsedMilliseconds;
      if (duration > 100) {
        _logger.warning('Slow operation detected: $operationName took ${duration}ms');
      } else {
        _logger.debug('Operation completed: $operationName took ${duration}ms');
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _logger.error('Operation failed: $operationName after ${stopwatch.elapsedMilliseconds}ms', e);
      rethrow;
    }
  }

  /// Batch operations to reduce main thread blocking
  static Future<List<T>> batchOperations<T>(
    List<Future<T> Function()> operations, {
    int batchSize = 5,
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = operations.skip(i).take(batchSize);
      final batchResults = await Future.wait(
        batch.map((operation) => operation()),
      );
      results.addAll(batchResults);
      
      // Small delay between batches to prevent UI blocking
      if (i + batchSize < operations.length) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }
    
    return results;
  }
}
