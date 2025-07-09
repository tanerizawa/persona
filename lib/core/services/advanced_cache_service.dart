import 'dart:async';
import 'dart:collection';

import 'logging_service.dart';
import 'cache_service.dart';
import 'database_optimization_service.dart';
import 'performance_service.dart';

/// Advanced multi-level caching with intelligent strategies
class AdvancedCacheService {
  static final AdvancedCacheService _instance = AdvancedCacheService._internal();
  factory AdvancedCacheService() => _instance;
  AdvancedCacheService._internal();

  final LoggingService _logger = LoggingService();
  final CacheService _memoryCache = CacheService();
  final DatabaseOptimizationService _diskCache = DatabaseOptimizationService();
  final PerformanceService _performance = PerformanceService();

  // Cache statistics and monitoring
  final Map<String, CacheStats> _cacheStats = {};
  final Map<String, CacheStrategy> _cacheStrategies = {};
  
  // Cache warming and preloading
  final Set<String> _preloadKeys = {};
  final Queue<PreloadTask> _preloadQueue = Queue<PreloadTask>();
  Timer? _preloadTimer;
  
  // Cache invalidation tracking
  final Map<String, List<String>> _dependencyMap = {};
  final Map<String, DateTime> _lastAccess = {};
  
  static const Duration _statsReportInterval = Duration(minutes: 5);
  static const int _maxPreloadQueue = 20;

  /// Initialize advanced caching
  Future<void> initialize() async {
    await _performance.executeWithTracking(
      'advanced_cache_init',
      () async {
        await _diskCache.initialize();
        _startPreloadProcessor();
        _startStatsReporting();
        _logger.info('Advanced cache service initialized');
      },
    );
  }

  /// Set cache with advanced strategy
  Future<void> set<T>(
    String key,
    T value, {
    Duration? ttl,
    CacheStrategy strategy = CacheStrategy.memoryFirst,
    List<String>? dependencies,
    bool preload = false,
  }) async {
    return await _performance.executeWithTracking(
      'advanced_cache_set_$key',
      () async {
        // Update strategy
        _cacheStrategies[key] = strategy;
        
        // Handle dependencies
        if (dependencies != null) {
          _dependencyMap[key] = dependencies;
        }
        
        // Update access time
        _lastAccess[key] = DateTime.now();
        
        // Store based on strategy
        switch (strategy) {
          case CacheStrategy.memoryOnly:
            await _setMemoryOnly(key, value, ttl);
            break;
          case CacheStrategy.diskOnly:
            await _setDiskOnly(key, value, ttl);
            break;
          case CacheStrategy.memoryFirst:
            await _setMemoryFirst(key, value, ttl);
            break;
          case CacheStrategy.diskFirst:
            await _setDiskFirst(key, value, ttl);
            break;
          case CacheStrategy.writeThrough:
            await _setWriteThrough(key, value, ttl);
            break;
          case CacheStrategy.writeBack:
            await _setWriteBack(key, value, ttl);
            break;
        }
        
        // Add to preload if specified
        if (preload) {
          _preloadKeys.add(key);
        }
        
        // Update stats
        _updateStats(key, CacheOperation.set);
        
        _logger.debug('Advanced cache set: $key with strategy: $strategy');
      },
    );
  }

  /// Get cache with advanced strategy
  Future<T?> get<T>(String key) async {
    return await _performance.executeWithTracking(
      'advanced_cache_get_$key',
      () async {
        // Update access time
        _lastAccess[key] = DateTime.now();
        
        final strategy = _cacheStrategies[key] ?? CacheStrategy.memoryFirst;
        T? result;
        
        switch (strategy) {
          case CacheStrategy.memoryOnly:
            result = await _getMemoryOnly<T>(key);
            break;
          case CacheStrategy.diskOnly:
            result = await _getDiskOnly<T>(key);
            break;
          case CacheStrategy.memoryFirst:
            result = await _getMemoryFirst<T>(key);
            break;
          case CacheStrategy.diskFirst:
            result = await _getDiskFirst<T>(key);
            break;
          case CacheStrategy.writeThrough:
          case CacheStrategy.writeBack:
            result = await _getMemoryFirst<T>(key);
            break;
        }
        
        // Update stats
        _updateStats(key, result != null ? CacheOperation.hit : CacheOperation.miss);
        
        if (result != null) {
          _logger.debug('Advanced cache hit: $key');
        } else {
          _logger.debug('Advanced cache miss: $key');
        }
        
        return result;
      },
    );
  }

  /// Preload cache data
  Future<void> preload<T>(
    String key,
    Future<T> Function() dataLoader, {
    Duration? ttl,
    CacheStrategy strategy = CacheStrategy.memoryFirst,
  }) async {
    if (_preloadQueue.length >= _maxPreloadQueue) {
      _logger.warning('Preload queue full, skipping: $key');
      return;
    }
    
    final task = PreloadTask(
      key: key,
      dataLoader: dataLoader,
      ttl: ttl,
      strategy: strategy,
      priority: _preloadKeys.contains(key) ? 1 : 0,
    );
    
    _preloadQueue.add(task);
    _logger.debug('Added to preload queue: $key');
  }

  /// Warm cache with multiple keys
  Future<void> warmCache(List<String> keys) async {
    await _performance.executeWithTracking(
      'cache_warm_multiple',
      () async {
        final futures = <Future>[];
        
        for (final key in keys) {
          // Check if key exists and is not expired
          final memoryResult = _memoryCache.get(key);
          if (memoryResult == null) {
            // Add to preload for warming
            _preloadKeys.add(key);
          }
        }
        
        await Future.wait(futures);
        _logger.info('Cache warmed for ${keys.length} keys');
      },
    );
  }

  /// Invalidate cache by key
  Future<void> invalidate(String key) async {
    await _performance.executeWithTracking(
      'cache_invalidate_$key',
      () async {
        // Remove from all cache levels
        _memoryCache.remove(key);
        await _diskCache.batchDelete('cache', [key]);
        
        // Remove from strategies and dependencies
        _cacheStrategies.remove(key);
        _dependencyMap.remove(key);
        _lastAccess.remove(key);
        _preloadKeys.remove(key);
        
        // Update stats
        _updateStats(key, CacheOperation.invalidate);
        
        _logger.debug('Cache invalidated: $key');
      },
    );
  }

  /// Invalidate by dependency
  Future<void> invalidateByDependency(String dependency) async {
    await _performance.executeWithTracking(
      'cache_invalidate_dependency_$dependency',
      () async {
        final keysToInvalidate = <String>[];
        
        // Find all keys that depend on this dependency
        for (final entry in _dependencyMap.entries) {
          if (entry.value.contains(dependency)) {
            keysToInvalidate.add(entry.key);
          }
        }
        
        // Invalidate all dependent keys
        for (final key in keysToInvalidate) {
          await invalidate(key);
        }
        
        _logger.info('Invalidated ${keysToInvalidate.length} keys by dependency: $dependency');
      },
    );
  }

  /// Get cache statistics
  Map<String, dynamic> getStatistics() {
    final totalHits = _cacheStats.values.fold(0, (sum, stats) => sum + stats.hits);
    final totalMisses = _cacheStats.values.fold(0, (sum, stats) => sum + stats.misses);
    final totalSets = _cacheStats.values.fold(0, (sum, stats) => sum + stats.sets);
    final hitRate = totalHits + totalMisses > 0 ? totalHits / (totalHits + totalMisses) : 0.0;
    
    return {
      'total_keys': _cacheStats.length,
      'total_hits': totalHits,
      'total_misses': totalMisses,
      'total_sets': totalSets,
      'hit_rate': hitRate,
      'preload_queue_size': _preloadQueue.length,
      'preload_keys': _preloadKeys.length,
      'memory_cache_stats': _memoryCache.getStats(),
      'strategies': _cacheStrategies.map((k, v) => MapEntry(k, v.toString())),
      'dependencies_count': _dependencyMap.length,
    };
  }

  /// Clear all caches
  Future<void> clearAll() async {
    await _performance.executeWithTracking(
      'cache_clear_all',
      () async {
        _memoryCache.clear();
        // Note: We don't clear disk cache entirely as it might contain important data
        
        _cacheStats.clear();
        _cacheStrategies.clear();
        _dependencyMap.clear();
        _lastAccess.clear();
        _preloadKeys.clear();
        _preloadQueue.clear();
        
        _logger.info('All caches cleared');
      },
    );
  }

  /// Memory-only cache operations
  Future<void> _setMemoryOnly<T>(String key, T value, Duration? ttl) async {
    _memoryCache.set(key, value, ttl: ttl);
  }

  Future<T?> _getMemoryOnly<T>(String key) async {
    return _memoryCache.get<T>(key);
  }

  /// Disk-only cache operations
  Future<void> _setDiskOnly<T>(String key, T value, Duration? ttl) async {
    await _diskCache.batchWrite<T>('cache', {key: value}, immediate: true);
  }

  Future<T?> _getDiskOnly<T>(String key) async {
    final result = await _diskCache.bulkRead<T>('cache', [key]);
    return result[key];
  }

  /// Memory-first cache operations
  Future<void> _setMemoryFirst<T>(String key, T value, Duration? ttl) async {
    _memoryCache.set(key, value, ttl: ttl);
  }

  Future<T?> _getMemoryFirst<T>(String key) async {
    // Try memory first
    final memoryResult = _memoryCache.get<T>(key);
    if (memoryResult != null) {
      return memoryResult;
    }
    
    // Fallback to disk
    final diskResult = await _getDiskOnly<T>(key);
    if (diskResult != null) {
      // Promote to memory
      _memoryCache.set(key, diskResult);
    }
    
    return diskResult;
  }

  /// Disk-first cache operations
  Future<void> _setDiskFirst<T>(String key, T value, Duration? ttl) async {
    await _diskCache.batchWrite<T>('cache', {key: value}, immediate: true);
    _memoryCache.set(key, value, ttl: ttl);
  }

  Future<T?> _getDiskFirst<T>(String key) async {
    // Try disk first
    final diskResult = await _getDiskOnly<T>(key);
    if (diskResult != null) {
      // Promote to memory
      _memoryCache.set(key, diskResult);
      return diskResult;
    }
    
    // Fallback to memory
    return _memoryCache.get<T>(key);
  }

  /// Write-through cache operations
  Future<void> _setWriteThrough<T>(String key, T value, Duration? ttl) async {
    // Write to both memory and disk simultaneously
    await Future.wait([
      Future(() => _memoryCache.set(key, value, ttl: ttl)),
      _diskCache.batchWrite<T>('cache', {key: value}, immediate: true),
    ]);
  }

  /// Write-back cache operations
  Future<void> _setWriteBack<T>(String key, T value, Duration? ttl) async {
    // Write to memory immediately, disk lazily
    _memoryCache.set(key, value, ttl: ttl);
    await _diskCache.batchWrite<T>('cache', {key: value}, immediate: false);
  }

  /// Update cache statistics
  void _updateStats(String key, CacheOperation operation) {
    final stats = _cacheStats.putIfAbsent(key, () => CacheStats());
    
    switch (operation) {
      case CacheOperation.hit:
        stats.hits++;
        break;
      case CacheOperation.miss:
        stats.misses++;
        break;
      case CacheOperation.set:
        stats.sets++;
        break;
      case CacheOperation.invalidate:
        stats.invalidations++;
        break;
    }
    
    stats.lastAccess = DateTime.now();
  }

  /// Start preload processor
  void _startPreloadProcessor() {
    _preloadTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _processPreloadQueue();
    });
  }

  /// Process preload queue
  Future<void> _processPreloadQueue() async {
    if (_preloadQueue.isEmpty) return;
    
    final task = _preloadQueue.removeFirst();
    
    try {
      final data = await task.dataLoader();
      await set(
        task.key,
        data,
        ttl: task.ttl,
        strategy: task.strategy,
      );
      
      _logger.debug('Preloaded cache: ${task.key}');
    } catch (e) {
      _logger.error('Failed to preload cache: ${task.key}', e);
    }
  }

  /// Start statistics reporting
  void _startStatsReporting() {
    Timer.periodic(_statsReportInterval, (_) {
      final stats = getStatistics();
      _logger.info('Cache Statistics: Hit Rate: ${(stats['hit_rate'] * 100).toStringAsFixed(1)}%, Total Keys: ${stats['total_keys']}');
    });
  }

  /// Dispose resources
  void dispose() {
    _preloadTimer?.cancel();
    _preloadTimer = null;
    _preloadQueue.clear();
    _logger.info('Advanced cache service disposed');
  }
}

/// Cache strategy enumeration
enum CacheStrategy {
  memoryOnly,
  diskOnly,
  memoryFirst,
  diskFirst,
  writeThrough,
  writeBack,
}

/// Cache operation enumeration
enum CacheOperation {
  hit,
  miss,
  set,
  invalidate,
}

/// Cache statistics
class CacheStats {
  int hits = 0;
  int misses = 0;
  int sets = 0;
  int invalidations = 0;
  DateTime lastAccess = DateTime.now();
}

/// Preload task
class PreloadTask {
  final String key;
  final Future<dynamic> Function() dataLoader;
  final Duration? ttl;
  final CacheStrategy strategy;
  final int priority;

  PreloadTask({
    required this.key,
    required this.dataLoader,
    this.ttl,
    required this.strategy,
    this.priority = 0,
  });
}
