import 'dart:collection';

import 'logging_service.dart';

/// Error tracking and analytics service
class ErrorTrackingService {
  static final ErrorTrackingService _instance = ErrorTrackingService._internal();
  factory ErrorTrackingService() => _instance;
  ErrorTrackingService._internal();

  final LoggingService _logger = LoggingService();
  
  // Error counters and tracking
  final Map<String, int> _errorCounts = {};
  final Map<String, DateTime> _lastErrorTime = {};
  final Queue<ErrorEvent> _recentErrors = Queue<ErrorEvent>();
  
  static const int _maxRecentErrors = 50;

  /// Track an error with context
  void trackError(
    String error, {
    String? context,
    String? userId,
    Map<String, dynamic>? metadata,
    ErrorSeverity severity = ErrorSeverity.medium,
  }) {
    final errorKey = _generateErrorKey(error, context);
    final now = DateTime.now();
    
    // Update error count
    _errorCounts[errorKey] = (_errorCounts[errorKey] ?? 0) + 1;
    _lastErrorTime[errorKey] = now;
    
    // Create error event
    final errorEvent = ErrorEvent(
      error: error,
      context: context,
      userId: userId,
      metadata: metadata,
      severity: severity,
      timestamp: now,
      count: _errorCounts[errorKey]!,
    );
    
    // Add to recent errors queue
    _recentErrors.add(errorEvent);
    if (_recentErrors.length > _maxRecentErrors) {
      _recentErrors.removeFirst();
    }
    
    // Log based on severity and frequency
    _logError(errorEvent);
    
    // Check if this is a critical pattern
    _analyzeErrorPattern(errorKey, errorEvent);
  }

  /// Track database operation errors specifically
  void trackDatabaseError(
    String operation,
    String error, {
    String? query,
    int? duration,
    Map<String, dynamic>? params,
  }) {
    trackError(
      error,
      context: 'database_$operation',
      metadata: {
        'operation': operation,
        'query': query,
        'duration_ms': duration,
        'params': params,
      },
      severity: ErrorSeverity.high,
    );
  }

  /// Track API call errors
  void trackApiError(
    String endpoint,
    int statusCode,
    String error, {
    int? duration,
    Map<String, dynamic>? requestData,
  }) {
    trackError(
      error,
      context: 'api_$endpoint',
      metadata: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'duration_ms': duration,
        'request_data': requestData,
      },
      severity: _getApiErrorSeverity(statusCode),
    );
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStats() {
    final now = DateTime.now();
    final recentErrors = _recentErrors.where(
      (e) => now.difference(e.timestamp).inHours < 24,
    ).toList();
    
    return {
      'total_unique_errors': _errorCounts.length,
      'total_error_count': _errorCounts.values.fold(0, (sum, count) => sum + count),
      'errors_last_24h': recentErrors.length,
      'most_frequent_errors': _getMostFrequentErrors(limit: 5),
      'error_rate_trend': _calculateErrorRateTrend(),
      'critical_errors': recentErrors.where((e) => e.severity == ErrorSeverity.critical).length,
    };
  }

  /// Get recent errors for debugging
  List<ErrorEvent> getRecentErrors({int limit = 20}) {
    return _recentErrors.toList().reversed.take(limit).toList();
  }

  /// Clear error tracking data
  void clearErrorData() {
    _errorCounts.clear();
    _lastErrorTime.clear();
    _recentErrors.clear();
    _logger.info('Error tracking data cleared');
  }

  /// Generate unique error key
  String _generateErrorKey(String error, String? context) {
    return context != null ? '$context:$error' : error;
  }

  /// Log error based on severity and frequency
  void _logError(ErrorEvent errorEvent) {
    final message = 'Error tracked: ${errorEvent.error}';
    final details = 'Context: ${errorEvent.context}, Count: ${errorEvent.count}, Severity: ${errorEvent.severity}';
    
    switch (errorEvent.severity) {
      case ErrorSeverity.critical:
        _logger.fatal('$message - $details', errorEvent.error);
        break;
      case ErrorSeverity.high:
        _logger.error('$message - $details', errorEvent.error);
        break;
      case ErrorSeverity.medium:
        _logger.warning('$message - $details');
        break;
      case ErrorSeverity.low:
        _logger.info('$message - $details');
        break;
    }
  }

  /// Analyze error patterns for potential issues
  void _analyzeErrorPattern(String errorKey, ErrorEvent errorEvent) {
    final count = _errorCounts[errorKey]!;
    
    // Check for error spikes
    if (count >= 5 && count % 5 == 0) {
      _logger.warning('Error spike detected: $errorKey occurred $count times');
    }
    
    // Check for critical error frequency
    if (errorEvent.severity == ErrorSeverity.critical && count >= 3) {
      _logger.fatal('Critical error pattern: $errorKey occurred $count times');
    }
  }

  /// Get API error severity based on status code
  ErrorSeverity _getApiErrorSeverity(int statusCode) {
    if (statusCode >= 500) return ErrorSeverity.critical;
    if (statusCode >= 400) return ErrorSeverity.high;
    if (statusCode >= 300) return ErrorSeverity.medium;
    return ErrorSeverity.low;
  }

  /// Get comprehensive error statistics
  Map<String, dynamic> getErrorStatistics() {
    return {
      'total_unique_errors': _errorCounts.length,
      'total_error_count': _errorCounts.values.fold(0, (sum, count) => sum + count),
      'recent_errors_count': _recentErrors.length,
      'most_frequent_errors': _getMostFrequentErrors(),
      'error_rate_trend': _calculateErrorRateTrend(),
      'errors_by_severity': _getErrorsBySeverity(),
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get errors grouped by severity
  Map<String, int> _getErrorsBySeverity() {
    final severityCounts = <String, int>{};
    
    for (final error in _recentErrors) {
      final severity = error.severity.toString().split('.').last;
      severityCounts[severity] = (severityCounts[severity] ?? 0) + 1;
    }
    
    return severityCounts;
  }

  /// Get most frequent errors
  List<Map<String, dynamic>> _getMostFrequentErrors({int limit = 5}) {
    final sortedErrors = _errorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedErrors.take(limit).map((entry) => {
      'error': entry.key,
      'count': entry.value,
      'last_seen': _lastErrorTime[entry.key]?.toIso8601String(),
    }).toList();
  }

  /// Calculate error rate trend
  Map<String, double> _calculateErrorRateTrend() {
    final now = DateTime.now();
    final last24h = _recentErrors.where(
      (e) => now.difference(e.timestamp).inHours < 24,
    ).length;
    final last1h = _recentErrors.where(
      (e) => now.difference(e.timestamp).inHours < 1,
    ).length;
    
    return {
      'errors_per_hour_24h': last24h / 24.0,
      'errors_last_hour': last1h.toDouble(),
    };
  }
}

/// Error event data class
class ErrorEvent {
  final String error;
  final String? context;
  final String? userId;
  final Map<String, dynamic>? metadata;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final int count;

  ErrorEvent({
    required this.error,
    this.context,
    this.userId,
    this.metadata,
    required this.severity,
    required this.timestamp,
    required this.count,
  });
}

/// Error severity levels
enum ErrorSeverity {
  low,
  medium,
  high,
  critical,
}
