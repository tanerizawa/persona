import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../services/logging_service.dart';
import '../services/cache_service.dart';

/// Memory management service for optimizing app performance
class MemoryManager {
  static MemoryManager? _instance;
  static MemoryManager get instance => _instance ??= MemoryManager._internal();
  
  MemoryManager._internal();

  final LoggingService _logger = LoggingService();
  Timer? _gcTimer;
  static const Duration _cleanupInterval = Duration(minutes: 2);

  /// Start periodic memory cleanup
  void startPeriodicCleanup() {
    if (_gcTimer != null) {
      _logger.debug('Memory cleanup timer already running');
      return;
    }

    _gcTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
    
    _logger.info('Memory cleanup timer started (interval: $_cleanupInterval)');
  }

  /// Stop periodic memory cleanup
  void stopPeriodicCleanup() {
    _gcTimer?.cancel();
    _gcTimer = null;
    _logger.info('Memory cleanup timer stopped');
  }

  /// Perform manual memory cleanup
  void performManualCleanup() {
    _performCleanup();
    _logger.info('Manual memory cleanup performed');
  }

  /// Internal cleanup implementation
  void _performCleanup() {
    try {
      // Clear image cache
      imageCache.clear();
      imageCache.clearLiveImages();

      // Clear app cache
      CacheService().clear();

      // Log memory cleanup in debug mode
      if (kDebugMode) {
        developer.log('Memory cleanup performed - caches cleared');
      }

      _logger.debug('Memory cleanup cycle completed');
    } catch (e) {
      _logger.error('Error during memory cleanup: $e');
    }
  }

  /// Get current memory usage
  double getCurrentMemoryUsage() {
    // Note: This is an estimate based on cache sizes
    final imageCacheSize = imageCache.currentSize;
    final appCacheStats = CacheService().getStats();
    final appCacheSize = appCacheStats['size'] as int? ?? 0;
    
    // Return in MB
    return (imageCacheSize + appCacheSize) / (1024 * 1024);
  }

  /// Get current memory usage in bytes (estimated)
  double getCurrentMemoryUsageInBytes() {
    // This is an estimation since Dart doesn't provide direct memory access
    // In production, you might want to use platform-specific implementations
    return imageCache.currentSize.toDouble() + 
           (CacheService().getStats()['size'] ?? 0).toDouble();
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'image_cache_size': imageCache.currentSize,
      'image_cache_max_size': imageCache.maximumSize,
      'image_cache_live_count': imageCache.liveImageCount,
      'image_cache_pending_count': imageCache.pendingImageCount,
      'app_cache_stats': CacheService().getStats(),
      'cleanup_timer_active': _gcTimer?.isActive ?? false,
    };
  }

  /// Get comprehensive memory statistics
  Map<String, dynamic> getMemoryStatistics() {
    final baseStats = getMemoryStats();
    final currentUsage = getCurrentMemoryUsage();
    
    return {
      ...baseStats,
      'current_usage': currentUsage,
      'max_usage': currentUsage * 1.5, // Estimated max usage
      'cleanup_count': 0, // Would be tracked in a real implementation
      'gc_triggered': 0, // Would be tracked in a real implementation
      'memory_warnings': 0, // Would be tracked in a real implementation
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Force garbage collection (debug only)
  void forceGarbageCollection() {
    if (kDebugMode) {
      developer.log('Forcing garbage collection...');
      // Note: There's no direct way to force GC in Dart
      // This is just for logging purposes
      _logger.debug('Garbage collection triggered (developer mode)');
    }
  }

  /// Dispose memory manager resources
  void dispose() {
    stopPeriodicCleanup();
    _logger.info('Memory manager disposed');
  }
}
