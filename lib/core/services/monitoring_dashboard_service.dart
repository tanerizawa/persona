import 'dart:async';

import 'logging_service.dart';
import 'performance_monitor.dart';
import 'error_tracking_service.dart';
import '../utils/memory_manager.dart';
import 'cache_service.dart';
import 'database_optimization_service.dart';
import 'session_manager_service.dart';
import 'advanced_cache_service.dart';

/// Real-time performance monitoring dashboard
class MonitoringDashboardService {
  static final MonitoringDashboardService _instance = MonitoringDashboardService._internal();
  factory MonitoringDashboardService() => _instance;
  MonitoringDashboardService._internal();

  final LoggingService _logger = LoggingService();
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final ErrorTrackingService _errorTracking = ErrorTrackingService();
  final MemoryManager _memoryManager = MemoryManager.instance;
  final CacheService _cache = CacheService();
  final DatabaseOptimizationService _database = DatabaseOptimizationService();
  final SessionManagerService _sessionManager = SessionManagerService();
  final AdvancedCacheService _advancedCache = AdvancedCacheService();

  // Dashboard data
  Timer? _updateTimer;
  final List<DashboardSnapshot> _snapshots = [];
  static const Duration _updateInterval = Duration(seconds: 30);
  static const int _maxSnapshots = 100;

  /// Initialize monitoring dashboard
  Future<void> initialize() async {
    _logger.info('Initializing monitoring dashboard');
    _startPeriodicUpdates();
  }

  /// Get current performance dashboard
  Future<PerformanceDashboard> getCurrentDashboard() async {
    final snapshot = await _captureSnapshot();
    
    return PerformanceDashboard(
      timestamp: DateTime.now(),
      performance: await _getPerformanceMetrics(),
      memory: await _getMemoryMetrics(),
      cache: await _getCacheMetrics(),
      database: await _getDatabaseMetrics(),
      session: await _getSessionMetrics(),
      errors: await _getErrorMetrics(),
      system: await _getSystemMetrics(),
      snapshot: snapshot,
    );
  }

  /// Get performance metrics
  Future<PerformanceMetrics> _getPerformanceMetrics() async {
    final summary = _performanceMonitor.getPerformanceSummary();
    
    return PerformanceMetrics(
      averageFrameTime: summary['average_frame_time'] ?? 0.0,
      frameDropCount: summary['frame_drops'] ?? 0,
      slowOperations: summary['slow_operations'] ?? 0,
      totalOperations: summary['total_operations'] ?? 0,
      averageOperationTime: summary['average_operation_time'] ?? 0.0,
    );
  }

  /// Get memory metrics
  Future<MemoryMetrics> _getMemoryMetrics() async {
    final currentUsage = _memoryManager.getCurrentMemoryUsage();
    final stats = _memoryManager.getMemoryStatistics();
    
    return MemoryMetrics(
      currentUsage: currentUsage.round(),
      maxUsage: stats['max_usage'] ?? 0,
      cleanupCount: stats['cleanup_count'] ?? 0,
      gcCount: stats['gc_triggered'] ?? 0,
      memoryWarnings: stats['memory_warnings'] ?? 0,
    );
  }

  /// Get cache metrics
  Future<CacheMetrics> _getCacheMetrics() async {
    final basicStats = _cache.getStats();
    final advancedStats = _advancedCache.getStatistics();
    
    return CacheMetrics(
      basicCacheItems: basicStats['total_items'] ?? 0,
      basicCacheHitRate: 0.0, // Basic cache doesn't track hit rate
      advancedCacheItems: advancedStats['total_keys'] ?? 0,
      advancedCacheHitRate: advancedStats['hit_rate'] ?? 0.0,
      preloadQueueSize: advancedStats['preload_queue_size'] ?? 0,
      totalHits: advancedStats['total_hits'] ?? 0,
      totalMisses: advancedStats['total_misses'] ?? 0,
    );
  }

  /// Get database metrics
  Future<DatabaseMetrics> _getDatabaseMetrics() async {
    final stats = await _database.getDatabaseStats();
    
    return DatabaseMetrics(
      openBoxes: stats['open_boxes'] ?? 0,
      pendingOperations: stats['pending_operations'] ?? 0,
      isProcessingBatch: stats['is_processing_batch'] ?? false,
      totalQueries: 0, // Would need to track this
      averageQueryTime: 0.0, // Would need to track this
    );
  }

  /// Get session metrics
  Future<SessionMetrics> _getSessionMetrics() async {
    final stats = _sessionManager.getSessionStats();
    
    return SessionMetrics(
      activeSessions: stats['active_sessions'] ?? 0,
      pendingBatches: stats['pending_batches'] ?? 0,
      totalPendingRequests: stats['total_pending_requests'] ?? 0,
      sessionTimeouts: 0, // Would need to track this
      requestThroughput: 0.0, // Would need to track this
    );
  }

  /// Get error metrics
  Future<ErrorMetrics> _getErrorMetrics() async {
    final stats = _errorTracking.getErrorStatistics();
    
    return ErrorMetrics(
      totalErrors: stats['total_errors'] ?? 0,
      recentErrors: stats['recent_errors'] ?? 0,
      criticalErrors: stats['critical_errors'] ?? 0,
      errorRate: stats['error_rate'] ?? 0.0,
      topErrors: (stats['top_errors'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  /// Get system metrics
  Future<SystemMetrics> _getSystemMetrics() async {
    return SystemMetrics(
      uptime: DateTime.now().difference(_startTime),
      cpuUsage: 0.0, // Would need platform-specific implementation
      batteryLevel: 0.0, // Would need platform-specific implementation
      networkStatus: 'unknown', // Would need connectivity plugin
      diskUsage: 0.0, // Would need platform-specific implementation
    );
  }

  /// Capture performance snapshot
  Future<DashboardSnapshot> _captureSnapshot() async {
    final snapshot = DashboardSnapshot(
      timestamp: DateTime.now(),
      performance: await _getPerformanceMetrics(),
      memory: await _getMemoryMetrics(),
      cache: await _getCacheMetrics(),
      database: await _getDatabaseMetrics(),
      session: await _getSessionMetrics(),
      errors: await _getErrorMetrics(),
    );

    _snapshots.add(snapshot);
    
    // Keep only recent snapshots
    if (_snapshots.length > _maxSnapshots) {
      _snapshots.removeAt(0);
    }

    return snapshot;
  }

  /// Get performance trends
  List<DashboardSnapshot> getPerformanceTrends({
    Duration? duration,
    int? maxSnapshots,
  }) {
    var filtered = _snapshots;
    
    if (duration != null) {
      final cutoff = DateTime.now().subtract(duration);
      filtered = _snapshots.where((s) => s.timestamp.isAfter(cutoff)).toList();
    }
    
    if (maxSnapshots != null && filtered.length > maxSnapshots) {
      filtered = filtered.skip(filtered.length - maxSnapshots).toList();
    }
    
    return filtered;
  }

  /// Generate health score
  double calculateHealthScore() {
    if (_snapshots.isEmpty) return 100.0;
    
    final latest = _snapshots.last;
    double score = 100.0;
    
    // Performance score (30%)
    final frameDrops = latest.performance.frameDropCount;
    if (frameDrops > 10) {
      score -= 15;
    } else if (frameDrops > 5) {
      score -= 10;
    } else if (frameDrops > 0) {
      score -= 5;
    }
    
    // Memory score (25%)
    final memoryUsage = latest.memory.currentUsage;
    if (memoryUsage > 500 * 1024 * 1024) {
      score -= 15; // 500MB
    } else if (memoryUsage > 300 * 1024 * 1024) {
      score -= 10; // 300MB
    } else if (memoryUsage > 200 * 1024 * 1024) {
      score -= 5; // 200MB
    }
    
    // Cache score (20%)
    final cacheHitRate = latest.cache.advancedCacheHitRate;
    if (cacheHitRate < 0.5) {
      score -= 15;
    } else if (cacheHitRate < 0.7) {
      score -= 10;
    } else if (cacheHitRate < 0.9) {
      score -= 5;
    }
    
    // Error score (25%)
    final errorRate = latest.errors.errorRate;
    if (errorRate > 0.1) {
      score -= 20;
    } else if (errorRate > 0.05) {
      score -= 15;
    } else if (errorRate > 0.01) {
      score -= 10;
    } else if (errorRate > 0.005) {
      score -= 5;
    }
    
    return score.clamp(0.0, 100.0);
  }

  /// Get critical alerts
  List<PerformanceAlert> getCriticalAlerts() {
    final alerts = <PerformanceAlert>[];
    
    if (_snapshots.isEmpty) return alerts;
    
    final latest = _snapshots.last;
    
    // Memory alerts
    if (latest.memory.currentUsage > 400 * 1024 * 1024) {
      alerts.add(PerformanceAlert(
        level: AlertLevel.critical,
        type: AlertType.memory,
        message: 'High memory usage: ${(latest.memory.currentUsage / (1024 * 1024)).toStringAsFixed(1)}MB',
        timestamp: DateTime.now(),
      ));
    }
    
    // Performance alerts
    if (latest.performance.frameDropCount > 10) {
      alerts.add(PerformanceAlert(
        level: AlertLevel.warning,
        type: AlertType.performance,
        message: 'High frame drops: ${latest.performance.frameDropCount}',
        timestamp: DateTime.now(),
      ));
    }
    
    // Error alerts
    if (latest.errors.errorRate > 0.1) {
      alerts.add(PerformanceAlert(
        level: AlertLevel.critical,
        type: AlertType.error,
        message: 'High error rate: ${(latest.errors.errorRate * 100).toStringAsFixed(1)}%',
        timestamp: DateTime.now(),
      ));
    }
    
    // Cache alerts
    if (latest.cache.advancedCacheHitRate < 0.5) {
      alerts.add(PerformanceAlert(
        level: AlertLevel.warning,
        type: AlertType.cache,
        message: 'Low cache hit rate: ${(latest.cache.advancedCacheHitRate * 100).toStringAsFixed(1)}%',
        timestamp: DateTime.now(),
      ));
    }
    
    return alerts;
  }

  /// Start periodic dashboard updates
  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(_updateInterval, (_) async {
      try {
        await _captureSnapshot();
        
        // Log health score periodically
        final healthScore = calculateHealthScore();
        _logger.info('System Health Score: ${healthScore.toStringAsFixed(1)}%');
        
        // Log critical alerts
        final alerts = getCriticalAlerts();
        for (final alert in alerts) {
          _logger.warning('Performance Alert: ${alert.message}');
        }
      } catch (e) {
        _logger.error('Failed to update dashboard', e);
      }
    });
  }

  static final DateTime _startTime = DateTime.now();

  /// Dispose resources
  void dispose() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _snapshots.clear();
    _logger.info('Monitoring dashboard disposed');
  }
}

/// Performance dashboard data structure
class PerformanceDashboard {
  final DateTime timestamp;
  final PerformanceMetrics performance;
  final MemoryMetrics memory;
  final CacheMetrics cache;
  final DatabaseMetrics database;
  final SessionMetrics session;
  final ErrorMetrics errors;
  final SystemMetrics system;
  final DashboardSnapshot snapshot;

  PerformanceDashboard({
    required this.timestamp,
    required this.performance,
    required this.memory,
    required this.cache,
    required this.database,
    required this.session,
    required this.errors,
    required this.system,
    required this.snapshot,
  });
}

/// Dashboard snapshot for trends
class DashboardSnapshot {
  final DateTime timestamp;
  final PerformanceMetrics performance;
  final MemoryMetrics memory;
  final CacheMetrics cache;
  final DatabaseMetrics database;
  final SessionMetrics session;
  final ErrorMetrics errors;

  DashboardSnapshot({
    required this.timestamp,
    required this.performance,
    required this.memory,
    required this.cache,
    required this.database,
    required this.session,
    required this.errors,
  });
}

/// Individual metric classes
class PerformanceMetrics {
  final double averageFrameTime;
  final int frameDropCount;
  final int slowOperations;
  final int totalOperations;
  final double averageOperationTime;

  PerformanceMetrics({
    required this.averageFrameTime,
    required this.frameDropCount,
    required this.slowOperations,
    required this.totalOperations,
    required this.averageOperationTime,
  });
}

class MemoryMetrics {
  final int currentUsage;
  final int maxUsage;
  final int cleanupCount;
  final int gcCount;
  final int memoryWarnings;

  MemoryMetrics({
    required this.currentUsage,
    required this.maxUsage,
    required this.cleanupCount,
    required this.gcCount,
    required this.memoryWarnings,
  });
}

class CacheMetrics {
  final int basicCacheItems;
  final double basicCacheHitRate;
  final int advancedCacheItems;
  final double advancedCacheHitRate;
  final int preloadQueueSize;
  final int totalHits;
  final int totalMisses;

  CacheMetrics({
    required this.basicCacheItems,
    required this.basicCacheHitRate,
    required this.advancedCacheItems,
    required this.advancedCacheHitRate,
    required this.preloadQueueSize,
    required this.totalHits,
    required this.totalMisses,
  });
}

class DatabaseMetrics {
  final int openBoxes;
  final int pendingOperations;
  final bool isProcessingBatch;
  final int totalQueries;
  final double averageQueryTime;

  DatabaseMetrics({
    required this.openBoxes,
    required this.pendingOperations,
    required this.isProcessingBatch,
    required this.totalQueries,
    required this.averageQueryTime,
  });
}

class SessionMetrics {
  final int activeSessions;
  final int pendingBatches;
  final int totalPendingRequests;
  final int sessionTimeouts;
  final double requestThroughput;

  SessionMetrics({
    required this.activeSessions,
    required this.pendingBatches,
    required this.totalPendingRequests,
    required this.sessionTimeouts,
    required this.requestThroughput,
  });
}

class ErrorMetrics {
  final int totalErrors;
  final int recentErrors;
  final int criticalErrors;
  final double errorRate;
  final List<String> topErrors;

  ErrorMetrics({
    required this.totalErrors,
    required this.recentErrors,
    required this.criticalErrors,
    required this.errorRate,
    required this.topErrors,
  });
}

class SystemMetrics {
  final Duration uptime;
  final double cpuUsage;
  final double batteryLevel;
  final String networkStatus;
  final double diskUsage;

  SystemMetrics({
    required this.uptime,
    required this.cpuUsage,
    required this.batteryLevel,
    required this.networkStatus,
    required this.diskUsage,
  });
}

/// Performance alert
class PerformanceAlert {
  final AlertLevel level;
  final AlertType type;
  final String message;
  final DateTime timestamp;

  PerformanceAlert({
    required this.level,
    required this.type,
    required this.message,
    required this.timestamp,
  });
}

enum AlertLevel { info, warning, error, critical }
enum AlertType { performance, memory, cache, database, session, error, system }
