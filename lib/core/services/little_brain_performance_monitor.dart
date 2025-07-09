import 'dart:developer' as developer;
import 'dart:async';
import 'package:flutter/foundation.dart';

import 'production_logging_service.dart';

/// Enhanced Little Brain Performance Monitor
class LittleBrainPerformanceMonitor {
  static final LittleBrainPerformanceMonitor _instance = LittleBrainPerformanceMonitor._internal();
  factory LittleBrainPerformanceMonitor() => _instance;
  LittleBrainPerformanceMonitor._internal();

  final ProductionLoggingService _logger = ProductionLoggingService();
  
  // Performance tracking maps
  static final Map<String, Stopwatch> _timers = {};
  static final Map<String, List<int>> _performanceHistory = {};
  static final Map<String, int> _operationCounts = {};
  
  // Performance thresholds (in milliseconds)
  static const Map<String, int> _thresholds = {
    'memory_processing': 100,
    'emotion_detection': 50,
    'context_extraction': 75,
    'personality_analysis': 200,
    'similarity_matching': 150,
    'ai_context_generation': 300,
  };

  /// Start performance timer for operation
  static void startTimer(String operation) {
    _timers[operation] = Stopwatch()..start();
    _operationCounts[operation] = (_operationCounts[operation] ?? 0) + 1;
  }

  /// End performance timer and log results
  static void endTimer(String operation) {
    final timer = _timers[operation];
    if (timer != null) {
      timer.stop();
      final duration = timer.elapsedMilliseconds;
      
      _logPerformance(operation, duration);
      _updateHistory(operation, duration);
      _checkThreshold(operation, duration);
      
      _timers.remove(operation);
    }
  }

  /// Log performance metrics
  static void _logPerformance(String operation, int milliseconds) {
    final instance = LittleBrainPerformanceMonitor();
    
    if (kDebugMode) {
      developer.log(
        'LittleBrain Performance: $operation took ${milliseconds}ms',
        name: 'LITTLE_BRAIN_PERF'
      );
    }
    
    instance._logger.info(
      'LittleBrain Performance: $operation completed',
      metadata: {
        'operation': operation,
        'duration_ms': milliseconds,
        'operation_count': _operationCounts[operation],
        'threshold_ms': _thresholds[operation],
        'within_threshold': milliseconds <= (_thresholds[operation] ?? 1000),
      }
    );
  }

  /// Update performance history
  static void _updateHistory(String operation, int duration) {
    _performanceHistory.putIfAbsent(operation, () => <int>[]);
    _performanceHistory[operation]!.add(duration);
    
    // Keep only last 100 measurements
    if (_performanceHistory[operation]!.length > 100) {
      _performanceHistory[operation]!.removeAt(0);
    }
  }

  /// Check if performance exceeds threshold
  static void _checkThreshold(String operation, int duration) {
    final threshold = _thresholds[operation];
    if (threshold != null && duration > threshold) {
      final instance = LittleBrainPerformanceMonitor();
      
      instance._logger.warning(
        'LittleBrain Performance Warning: $operation exceeded threshold',
        metadata: {
          'operation': operation,
          'duration_ms': duration,
          'threshold_ms': threshold,
          'exceeded_by_ms': duration - threshold,
          'performance_issue': true,
        }
      );
    }
  }

  /// Get performance metrics for dashboard
  static Map<String, dynamic> getMetrics() {
    final metrics = <String, dynamic>{};
    
    for (final operation in _performanceHistory.keys) {
      final history = _performanceHistory[operation]!;
      if (history.isNotEmpty) {
        final avgDuration = history.reduce((a, b) => a + b) / history.length;
        final minDuration = history.reduce((a, b) => a < b ? a : b);
        final maxDuration = history.reduce((a, b) => a > b ? a : b);
        final threshold = _thresholds[operation] ?? 1000;
        
        metrics[operation] = {
          'average_duration_ms': avgDuration.round(),
          'min_duration_ms': minDuration,
          'max_duration_ms': maxDuration,
          'threshold_ms': threshold,
          'within_threshold_ratio': history.where((d) => d <= threshold).length / history.length,
          'operation_count': _operationCounts[operation] ?? 0,
          'last_duration_ms': history.last,
        };
      }
    }
    
    return metrics;
  }

  /// Get overall performance score (0.0 - 1.0)
  static double getOverallPerformanceScore() {
    final metrics = getMetrics();
    if (metrics.isEmpty) return 1.0;
    
    double totalScore = 0.0;
    int operationCount = 0;
    
    for (final operation in metrics.keys) {
      final operationMetrics = metrics[operation] as Map<String, dynamic>;
      final withinThresholdRatio = operationMetrics['within_threshold_ratio'] as double;
      
      totalScore += withinThresholdRatio;
      operationCount++;
    }
    
    return operationCount > 0 ? totalScore / operationCount : 1.0;
  }

  /// Get memory processing efficiency
  static Map<String, dynamic> getMemoryEfficiency() {
    final memoryOps = ['memory_processing', 'emotion_detection', 'context_extraction'];
    final efficiency = <String, dynamic>{};
    
    for (final operation in memoryOps) {
      final history = _performanceHistory[operation];
      if (history != null && history.isNotEmpty) {
        final avgDuration = history.reduce((a, b) => a + b) / history.length;
        final threshold = _thresholds[operation] ?? 1000;
        
        efficiency[operation] = {
          'efficiency_score': (threshold - avgDuration.clamp(0, threshold)) / threshold,
          'average_duration': avgDuration.round(),
          'operations_per_minute': _calculateOpsPerMinute(operation),
        };
      }
    }
    
    return efficiency;
  }

  /// Calculate operations per minute for trending
  static double _calculateOpsPerMinute(String operation) {
    final count = _operationCounts[operation] ?? 0;
    // Assuming we track for last hour, calculate per minute
    return count / 60.0; // Simplified calculation
  }

  /// Clear performance history (for testing/reset)
  static void clearHistory() {
    _performanceHistory.clear();
    _operationCounts.clear();
    _timers.clear();
  }

  /// Initialize monitoring with default settings
  Future<void> initialize() async {
    _logger.info('LittleBrain Performance Monitor initialized');
    
    // Start periodic reporting
    Timer.periodic(Duration(minutes: 5), (timer) {
      _generatePerformanceReport();
    });
  }

  /// Generate periodic performance report
  void _generatePerformanceReport() {
    final metrics = getMetrics();
    final overallScore = getOverallPerformanceScore();
    final efficiency = getMemoryEfficiency();
    
    _logger.info(
      'LittleBrain Performance Report',
      metadata: {
        'overall_performance_score': overallScore,
        'metrics': metrics,
        'memory_efficiency': efficiency,
        'total_operations': _operationCounts.values.fold(0, (sum, count) => sum + count),
      }
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    _logger.info('LittleBrain Performance Monitor disposed');
  }
}

/// Performance tracking wrapper for easy usage
class PerformanceWrapper {
  /// Execute function with performance tracking
  static Future<T> track<T>(String operation, Future<T> Function() function) async {
    LittleBrainPerformanceMonitor.startTimer(operation);
    try {
      final result = await function();
      return result;
    } finally {
      LittleBrainPerformanceMonitor.endTimer(operation);
    }
  }

  /// Execute synchronous function with performance tracking
  static T trackSync<T>(String operation, T Function() function) {
    LittleBrainPerformanceMonitor.startTimer(operation);
    try {
      final result = function();
      return result;
    } finally {
      LittleBrainPerformanceMonitor.endTimer(operation);
    }
  }
}
