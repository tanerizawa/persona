import 'dart:async';
import 'dart:collection';

import 'package:hive_flutter/hive_flutter.dart';

import 'logging_service.dart';
import 'error_tracking_service.dart';
import 'performance_service.dart';

/// Database optimization service for Hive operations
class DatabaseOptimizationService {
  static final DatabaseOptimizationService _instance = DatabaseOptimizationService._internal();
  factory DatabaseOptimizationService() => _instance;
  DatabaseOptimizationService._internal();

  final LoggingService _logger = LoggingService();
  final ErrorTrackingService _errorTracking = ErrorTrackingService();
  final PerformanceService _performance = PerformanceService();

  // Batch operation queue for database writes
  final Queue<_BatchOperation> _operationQueue = Queue<_BatchOperation>();
  final Map<String, Box> _openBoxes = {};
  Timer? _batchTimer;
  bool _isProcessingBatch = false;

  static const Duration _batchInterval = Duration(milliseconds: 500);
  static const int _maxBatchSize = 10;

  /// Initialize the database optimization service
  Future<void> initialize() async {
    _logger.info('Initializing database optimization service');
    _startBatchTimer();
  }

  /// Optimized box opening with caching
  Future<Box<T>> getBox<T>(String boxName) async {
    return await _performance.executeWithTracking(
      'db_get_box_$boxName',
      () async {
        try {
          // Return cached box if available
          if (_openBoxes.containsKey(boxName)) {
            return _openBoxes[boxName]! as Box<T>;
          }

          // Open new box and cache it
          final box = await Hive.openBox<T>(boxName);
          _openBoxes[boxName] = box;
          
          _logger.debug('Opened and cached box: $boxName');
          return box;
        } catch (e) {
          _errorTracking.trackDatabaseError(
            'open_box',
            'Failed to open box: $boxName',
            query: 'Hive.openBox($boxName)',
          );
          rethrow;
        }
      },
    );
  }

  /// Batch write operation
  Future<void> batchWrite<T>(
    String boxName,
    Map<String, T> data, {
    bool immediate = false,
  }) async {
    final operation = _BatchOperation(
      boxName: boxName,
      operations: data.entries.map((entry) => 
        _Operation(type: _OperationType.put, key: entry.key, value: entry.value)
      ).toList(),
    );

    if (immediate) {
      await _executeBatchOperation(operation);
    } else {
      _operationQueue.add(operation);
      _processBatchIfNeeded();
    }
  }

  /// Batch delete operation
  Future<void> batchDelete(
    String boxName,
    List<String> keys, {
    bool immediate = false,
  }) async {
    final operation = _BatchOperation(
      boxName: boxName,
      operations: keys.map((key) => 
        _Operation(type: _OperationType.delete, key: key)
      ).toList(),
    );

    if (immediate) {
      await _executeBatchOperation(operation);
    } else {
      _operationQueue.add(operation);
      _processBatchIfNeeded();
    }
  }

  /// Optimized bulk read with performance tracking
  Future<Map<String, T?>> bulkRead<T>(
    String boxName,
    List<String> keys,
  ) async {
    return await _performance.executeWithTracking(
      'db_bulk_read_$boxName',
      () async {
        try {
          final box = await getBox<T>(boxName);
          final result = <String, T?>{};
          
          for (final key in keys) {
            result[key] = box.get(key);
          }
          
          _logger.debug('Bulk read completed: $boxName with ${keys.length} keys');
          return result;
        } catch (e) {
          _errorTracking.trackDatabaseError(
            'bulk_read',
            'Failed bulk read: $boxName',
            query: 'box.get(keys)',
            params: {'key_count': keys.length},
          );
          rethrow;
        }
      },
    );
  }

  /// Query optimization with indexing simulation
  Future<List<T>> queryWithCondition<T>(
    String boxName,
    bool Function(T value) condition, {
    int? limit,
    int? offset,
  }) async {
    return await _performance.executeWithTracking(
      'db_query_$boxName',
      () async {
        try {
          final box = await getBox<T>(boxName);
          final results = <T>[];
          int currentOffset = offset ?? 0;
          int count = 0;
          
          for (final value in box.values) {
            if (condition(value)) {
              if (count >= currentOffset) {
                results.add(value);
                if (limit != null && results.length >= limit) {
                  break;
                }
              }
              count++;
            }
          }
          
          _logger.debug('Query completed: $boxName found ${results.length} results');
          return results;
        } catch (e) {
          _errorTracking.trackDatabaseError(
            'query_with_condition',
            'Failed to query: $boxName',
            query: 'box.values.where(condition)',
            params: {'limit': limit, 'offset': offset},
          );
          rethrow;
        }
      },
    );
  }

  /// Database vacuum and cleanup
  Future<void> optimizeDatabase() async {
    await _performance.executeWithTracking(
      'db_optimize',
      () async {
        try {
          _logger.info('Starting database optimization');
          
          // Process any pending batch operations
          await _processBatch();
          
          // Compact all open boxes
          for (final entry in _openBoxes.entries) {
            try {
              await entry.value.compact();
              _logger.debug('Compacted box: ${entry.key}');
            } catch (e) {
              _logger.warning('Failed to compact box ${entry.key}: $e');
            }
          }
          
          _logger.info('Database optimization completed');
        } catch (e) {
          _errorTracking.trackDatabaseError(
            'optimize_database',
            'Database optimization failed: $e',
          );
          rethrow;
        }
      },
    );
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final stats = <String, dynamic>{
        'open_boxes': _openBoxes.length,
        'pending_operations': _operationQueue.length,
        'is_processing_batch': _isProcessingBatch,
        'box_details': <String, dynamic>{},
      };
      
      for (final entry in _openBoxes.entries) {
        final box = entry.value;
        stats['box_details'][entry.key] = {
          'length': box.length,
          'is_open': box.isOpen,
          'path': box.path,
        };
      }
      
      return stats;
    } catch (e) {
      _logger.error('Failed to get database stats', e);
      return {'error': e.toString()};
    }
  }

  /// Start batch processing timer
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (_) {
      _processBatchIfNeeded();
    });
  }

  /// Process batch if needed
  void _processBatchIfNeeded() {
    if (_operationQueue.isNotEmpty && !_isProcessingBatch) {
      if (_operationQueue.length >= _maxBatchSize) {
        _processBatch();
      }
    }
  }

  /// Process pending batch operations
  Future<void> _processBatch() async {
    if (_isProcessingBatch || _operationQueue.isEmpty) return;
    
    _isProcessingBatch = true;
    
    try {
      final operations = <_BatchOperation>[];
      
      // Collect operations for processing
      while (_operationQueue.isNotEmpty && operations.length < _maxBatchSize) {
        operations.add(_operationQueue.removeFirst());
      }
      
      // Execute operations in parallel by box
      final futures = <Future>[];
      for (final operation in operations) {
        futures.add(_executeBatchOperation(operation));
      }
      
      await Future.wait(futures);
      
      _logger.debug('Processed batch of ${operations.length} operations');
    } catch (e) {
      _logger.error('Batch processing failed', e);
      _errorTracking.trackDatabaseError(
        'batch_processing',
        'Batch processing failed: $e',
      );
    } finally {
      _isProcessingBatch = false;
    }
  }

  /// Execute a single batch operation
  Future<void> _executeBatchOperation(_BatchOperation operation) async {
    try {
      final box = await getBox(operation.boxName);
      
      for (final op in operation.operations) {
        switch (op.type) {
          case _OperationType.put:
            await box.put(op.key, op.value);
            break;
          case _OperationType.delete:
            await box.delete(op.key);
            break;
        }
      }
    } catch (e) {
      _errorTracking.trackDatabaseError(
        'execute_batch_operation',
        'Failed to execute batch operation: ${operation.boxName}',
        params: {'operation_count': operation.operations.length},
      );
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _operationQueue.clear();
    
    // Close all boxes
    for (final box in _openBoxes.values) {
      box.close();
    }
    _openBoxes.clear();
    
    _logger.info('Database optimization service disposed');
  }
}

/// Internal classes for batch operations
class _BatchOperation {
  final String boxName;
  final List<_Operation> operations;

  _BatchOperation({
    required this.boxName,
    required this.operations,
  });
}

class _Operation {
  final _OperationType type;
  final String key;
  final dynamic value;

  _Operation({
    required this.type,
    required this.key,
    this.value,
  });
}

enum _OperationType {
  put,
  delete,
}
