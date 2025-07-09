import 'dart:async';

import 'logging_service.dart';

/// Cache item with TTL support
class CacheItem<T> {
  final T data;
  final DateTime expiresAt;

  CacheItem(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// In-memory cache service with TTL support
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal() {
    _startCleanupTimer();
  }

  final Map<String, CacheItem> _cache = {};
  final LoggingService _logger = LoggingService();
  static const Duration _defaultTTL = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(minutes: 1);
  Timer? _cleanupTimer;

  /// Get cached value by key
  T? get<T>(String key) {
    final item = _cache[key];
    if (item != null) {
      if (item.isExpired) {
        _cache.remove(key);
        _logger.debug('Cache item expired and removed: $key');
        return null;
      }
      _logger.debug('Cache hit: $key');
      return item.data as T?;
    }
    _logger.debug('Cache miss: $key');
    return null;
  }

  /// Set value in cache with optional TTL
  void set<T>(String key, T data, {Duration? ttl}) {
    final expiresAt = DateTime.now().add(ttl ?? _defaultTTL);
    _cache[key] = CacheItem(data, expiresAt);
    _logger.debug('Cache set: $key (expires: $expiresAt)');
  }

  /// Remove specific key from cache
  void remove(String key) {
    _cache.remove(key);
    _logger.debug('Cache removed: $key');
  }

  /// Clear all cache
  void clear() {
    final count = _cache.length;
    _cache.clear();
    _logger.info('Cache cleared: $count items removed');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final expired = _cache.values.where((item) => item.isExpired).length;
    
    return {
      'total_items': _cache.length,
      'expired_items': expired,
      'valid_items': _cache.length - expired,
      'memory_usage_estimate': _cache.length * 1024, // Rough estimate
    };
  }

  /// Start periodic cleanup of expired items
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _cleanupExpiredItems();
    });
  }

  /// Remove expired items from cache
  void _cleanupExpiredItems() {
    final expiredKeys = <String>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      _logger.debug('Cache cleanup: ${expiredKeys.length} expired items removed');
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}
