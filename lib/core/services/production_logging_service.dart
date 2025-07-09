import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'logging_service.dart';
import 'error_tracking_service.dart';

/// Production-grade logging service (simplified version)
class ProductionLoggingService {
  static final ProductionLoggingService _instance = ProductionLoggingService._internal();
  factory ProductionLoggingService() => _instance;
  ProductionLoggingService._internal();

  final LoggingService _logger = LoggingService();
  final ErrorTrackingService _errorTracker = ErrorTrackingService();

  /// Initialize production logging
  Future<void> initialize() async {
    _logger.info('Production logging initialized (console only)');
  }

  /// Log debug message
  void debug(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  /// Log info message  
  void info(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  /// Log warning message
  void warning(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace, metadata: metadata);
  }

  /// Log error message
  void error(String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace, metadata: metadata);
    
    // Track error for analytics
    if (error != null) {
      _errorTracker.trackError(
        message,
        context: 'production_logging',
        metadata: metadata,
        severity: ErrorSeverity.high,
      );
    }
  }

  /// Internal logging method
  void _log(LogLevel level, String message, {Object? error, StackTrace? stackTrace, Map<String, dynamic>? metadata}) {
    // Log to developer console
    _logToDeveloperConsole(level, message, error: error, stackTrace: stackTrace);
  }

  /// Log to developer console
  void _logToDeveloperConsole(LogLevel level, String message, {Object? error, StackTrace? stackTrace}) {
    final logMessage = error != null ? '$message: $error' : message;
    
    switch (level) {
      case LogLevel.info:
        developer.log(logMessage, name: 'INFO');
        break;
      case LogLevel.warning:
        developer.log(logMessage, name: 'WARNING');
        break;
      case LogLevel.error:
        developer.log(logMessage, name: 'ERROR', error: error, stackTrace: stackTrace);
        break;
      case LogLevel.debug:
        if (kDebugMode) {
          developer.log(logMessage, name: 'DEBUG');
        }
        break;
    }
  }

  /// Cleanup and dispose resources
  Future<void> dispose() async {
    _logger.info('Production logging service disposed');
  }
}

/// Log levels for production logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
}