import 'dart:async';
import 'dart:collection';

import 'logging_service.dart';

/// Performance monitoring service for tracking app performance metrics
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final LoggingService _logger = LoggingService();
  final Queue<double> _frameTimes = Queue<double>();
  final Map<String, List<int>> _operationTimes = {};
  
  static const int _maxFrameTimeEntries = 100;
  static const double _targetFrameTime = 16.67; // 60fps
  static const int _maxOperationEntries = 50;

  /// Track frame rendering time
  void trackFrameTime(double frameTime) {
    _frameTimes.add(frameTime);
    
    // Keep only recent frame times
    if (_frameTimes.length > _maxFrameTimeEntries) {
      _frameTimes.removeFirst();
    }
    
    // Log if frame time exceeds target (frame drop)
    if (frameTime > _targetFrameTime) {
      _logger.warning('Frame drop detected: ${frameTime.toStringAsFixed(2)}ms (target: ${_targetFrameTime}ms)');
    }
  }

  /// Track operation execution time
  void trackOperation(String operationName, int durationMs) {
    _operationTimes.putIfAbsent(operationName, () => <int>[]);
    final times = _operationTimes[operationName]!;
    
    times.add(durationMs);
    
    // Keep only recent operation times
    if (times.length > _maxOperationEntries) {
      times.removeAt(0);
    }
    
    // Log slow operations
    if (durationMs > 1000) { // > 1 second
      _logger.warning('Slow operation detected: $operationName took ${durationMs}ms');
    }
  }

  /// Get average frame time
  double get averageFrameTime {
    if (_frameTimes.isEmpty) return 0.0;
    return _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
  }

  /// Get frame drop percentage
  double get frameDropPercentage {
    if (_frameTimes.isEmpty) return 0.0;
    final droppedFrames = _frameTimes.where((time) => time > _targetFrameTime).length;
    return (droppedFrames / _frameTimes.length) * 100;
  }

  /// Get average operation time for specific operation
  double getAverageOperationTime(String operationName) {
    final times = _operationTimes[operationName];
    if (times == null || times.isEmpty) return 0.0;
    return times.reduce((a, b) => a + b) / times.length;
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final summary = <String, dynamic>{
      'average_frame_time': averageFrameTime.toStringAsFixed(2),
      'frame_drop_percentage': frameDropPercentage.toStringAsFixed(2),
      'total_frame_samples': _frameTimes.length,
      'operations': <String, dynamic>{},
    };

    // Add operation statistics
    for (final entry in _operationTimes.entries) {
      if (entry.value.isNotEmpty) {
        final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
        final max = entry.value.reduce((a, b) => a > b ? a : b);
        final min = entry.value.reduce((a, b) => a < b ? a : b);
        
        summary['operations'][entry.key] = {
          'average_ms': avg.toStringAsFixed(2),
          'max_ms': max,
          'min_ms': min,
          'sample_count': entry.value.length,
        };
      }
    }

    return summary;
  }

  /// Reset all performance metrics
  void reset() {
    _frameTimes.clear();
    _operationTimes.clear();
    _logger.info('Performance metrics reset');
  }

  /// Start automatic performance logging
  Timer? _performanceTimer;
  
  void startPerformanceLogging({Duration interval = const Duration(minutes: 5)}) {
    _performanceTimer?.cancel();
    _performanceTimer = Timer.periodic(interval, (_) {
      final summary = getPerformanceSummary();
      _logger.info('Performance Summary: $summary');
    });
    _logger.info('Performance logging started (interval: $interval)');
  }

  /// Stop automatic performance logging
  void stopPerformanceLogging() {
    _performanceTimer?.cancel();
    _performanceTimer = null;
    _logger.info('Performance logging stopped');
  }

  /// Dispose resources
  void dispose() {
    stopPerformanceLogging();
    reset();
  }
}
