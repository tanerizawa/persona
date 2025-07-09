import 'dart:async';
import 'dart:math';

import 'logging_service.dart';
import '../utils/memory_manager.dart';
import 'cache_service.dart';
import 'database_optimization_service.dart';

/// Automated performance testing and benchmarking service
class PerformanceTestingService {
  static final PerformanceTestingService _instance = PerformanceTestingService._internal();
  factory PerformanceTestingService() => _instance;
  PerformanceTestingService._internal();

  final LoggingService _logger = LoggingService();
  final MemoryManager _memoryManager = MemoryManager.instance;
  final CacheService _cache = CacheService();
  final DatabaseOptimizationService _database = DatabaseOptimizationService();

  // Test results storage
  final List<PerformanceTestResult> _testResults = [];
  final Map<String, BenchmarkResult> _benchmarks = {};
  
  // Test configuration
  static const int _defaultIterations = 10;
  static const Duration _testTimeout = Duration(minutes: 5);

  /// Run comprehensive performance tests
  Future<PerformanceTestSuite> runPerformanceTests({
    bool includeMemoryTests = true,
    bool includeCacheTests = true,
    bool includeDatabaseTests = true,
    bool includeNetworkTests = false,
    int iterations = _defaultIterations,
  }) async {
    _logger.info('Starting comprehensive performance tests');
    
    final suite = PerformanceTestSuite(
      startTime: DateTime.now(),
      iterations: iterations,
    );

    try {
      // Memory performance tests
      if (includeMemoryTests) {
        suite.memoryTests = await _runMemoryTests(iterations);
      }

      // Cache performance tests  
      if (includeCacheTests) {
        suite.cacheTests = await _runCacheTests(iterations);
      }

      // Database performance tests
      if (includeDatabaseTests) {
        suite.databaseTests = await _runDatabaseTests(iterations);
      }

      // Network performance tests
      if (includeNetworkTests) {
        suite.networkTests = await _runNetworkTests(iterations);
      }

      suite.endTime = DateTime.now();
      suite.totalDuration = suite.endTime!.difference(suite.startTime);
      
      _logger.info('Performance tests completed in ${suite.totalDuration?.inMilliseconds ?? 0}ms');
      
      return suite;
    } catch (e) {
      _logger.error('Performance tests failed', e);
      suite.error = e.toString();
      return suite;
    }
  }

  /// Run memory performance tests
  Future<MemoryTestResults> _runMemoryTests(int iterations) async {
    _logger.info('Running memory performance tests');
    
    final results = MemoryTestResults();
    
    // Memory allocation test
    results.allocationTest = await _runBenchmark(
      'memory_allocation',
      () async {
        final data = List.generate(1000, (i) => 'Test data $i');
        return data.length;
      },
      iterations,
    );

    // Memory cleanup test
    results.cleanupTest = await _runBenchmark(
      'memory_cleanup',
      () async {
        _memoryManager.performManualCleanup();
        return _memoryManager.getCurrentMemoryUsage();
      },
      iterations,
    );

    // Garbage collection stress test
    results.gcStressTest = await _runBenchmark(
      'gc_stress_test',
      () async {
        // Create and release large objects
        for (int i = 0; i < 100; i++) {
          final largeList = List.filled(10000, i);
          largeList.clear();
        }
        return _memoryManager.getCurrentMemoryUsage();
      },
      iterations,
    );

    return results;
  }

  /// Run cache performance tests
  Future<CacheTestResults> _runCacheTests(int iterations) async {
    _logger.info('Running cache performance tests');
    
    final results = CacheTestResults();
    
    // Cache write performance
    results.writeTest = await _runBenchmark(
      'cache_write',
      () async {
        for (int i = 0; i < 100; i++) {
          _cache.set('test_key_$i', 'test_value_$i');
        }
        return 100;
      },
      iterations,
    );

    // Cache read performance
    results.readTest = await _runBenchmark(
      'cache_read',
      () async {
        int hits = 0;
        for (int i = 0; i < 100; i++) {
          final value = _cache.get('test_key_$i');
          if (value != null) hits++;
        }
        return hits;
      },
      iterations,
    );

    // Cache miss performance
    results.missTest = await _runBenchmark(
      'cache_miss',
      () async {
        int misses = 0;
        for (int i = 100; i < 200; i++) {
          final value = _cache.get('missing_key_$i');
          if (value == null) misses++;
        }
        return misses;
      },
      iterations,
    );

    return results;
  }

  /// Run database performance tests
  Future<DatabaseTestResults> _runDatabaseTests(int iterations) async {
    _logger.info('Running database performance tests');
    
    final results = DatabaseTestResults();
    
    // Database write performance
    results.writeTest = await _runBenchmark(
      'database_write',
      () async {
        final data = <String, String>{};
        for (int i = 0; i < 50; i++) {
          data['db_test_key_$i'] = 'db_test_value_$i';
        }
        await _database.batchWrite('performance_test', data, immediate: true);
        return data.length;
      },
      iterations,
    );

    // Database read performance
    results.readTest = await _runBenchmark(
      'database_read',
      () async {
        final keys = List.generate(50, (i) => 'db_test_key_$i');
        final result = await _database.bulkRead('performance_test', keys);
        return result.values.where((v) => v != null).length;
      },
      iterations,
    );

    // Database batch operations
    results.batchTest = await _runBenchmark(
      'database_batch',
      () async {
        final data = <String, String>{};
        for (int i = 0; i < 100; i++) {
          data['batch_test_key_$i'] = 'batch_test_value_$i';
        }
        await _database.batchWrite('performance_test', data, immediate: false);
        return data.length;
      },
      iterations,
    );

    return results;
  }

  /// Run network performance tests
  Future<NetworkTestResults> _runNetworkTests(int iterations) async {
    _logger.info('Running network performance tests');
    
    final results = NetworkTestResults();
    
    // Simulated API call performance
    results.apiCallTest = await _runBenchmark(
      'api_call_simulation',
      () async {
        // Simulate network delay
        await Future.delayed(Duration(milliseconds: Random().nextInt(100) + 50));
        return 1;
      },
      iterations,
    );

    // Connection pool simulation
    results.connectionPoolTest = await _runBenchmark(
      'connection_pool_simulation',
      () async {
        final futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(Future.delayed(Duration(milliseconds: Random().nextInt(50) + 10)));
        }
        await Future.wait(futures);
        return futures.length;
      },
      iterations,
    );

    return results;
  }

  /// Run benchmark for specific operation
  Future<BenchmarkResult> _runBenchmark(
    String name,
    Future<dynamic> Function() operation,
    int iterations,
  ) async {
    final durations = <Duration>[];
    final results = <dynamic>[];
    dynamic error;

    for (int i = 0; i < iterations; i++) {
      try {
        final stopwatch = Stopwatch()..start();
        final result = await operation().timeout(_testTimeout);
        stopwatch.stop();
        
        durations.add(stopwatch.elapsed);
        results.add(result);
      } catch (e) {
        error = e;
        _logger.warning('Benchmark iteration failed: $name', e);
      }
    }

    final benchmark = BenchmarkResult(
      name: name,
      iterations: iterations,
      durations: durations,
      results: results,
      error: error?.toString(),
    );

    _benchmarks[name] = benchmark;
    return benchmark;
  }

  /// Generate performance report
  String generatePerformanceReport(PerformanceTestSuite suite) {
    final buffer = StringBuffer();
    
    buffer.writeln('=== Performance Test Report ===');
    buffer.writeln('Started: ${suite.startTime}');
    buffer.writeln('Completed: ${suite.endTime ?? 'N/A'}');
    buffer.writeln('Total Duration: ${suite.totalDuration?.inMilliseconds ?? 0}ms');
    buffer.writeln('Iterations: ${suite.iterations}');
    buffer.writeln();

    if (suite.error != null) {
      buffer.writeln('ERROR: ${suite.error}');
      buffer.writeln();
    }

    // Memory tests
    if (suite.memoryTests != null) {
      buffer.writeln('--- Memory Tests ---');
      _addBenchmarkToReport(buffer, suite.memoryTests!.allocationTest);
      _addBenchmarkToReport(buffer, suite.memoryTests!.cleanupTest);
      _addBenchmarkToReport(buffer, suite.memoryTests!.gcStressTest);
      buffer.writeln();
    }

    // Cache tests
    if (suite.cacheTests != null) {
      buffer.writeln('--- Cache Tests ---');
      _addBenchmarkToReport(buffer, suite.cacheTests!.writeTest);
      _addBenchmarkToReport(buffer, suite.cacheTests!.readTest);
      _addBenchmarkToReport(buffer, suite.cacheTests!.missTest);
      buffer.writeln();
    }

    // Database tests
    if (suite.databaseTests != null) {
      buffer.writeln('--- Database Tests ---');
      _addBenchmarkToReport(buffer, suite.databaseTests!.writeTest);
      _addBenchmarkToReport(buffer, suite.databaseTests!.readTest);
      _addBenchmarkToReport(buffer, suite.databaseTests!.batchTest);
      buffer.writeln();
    }

    // Network tests
    if (suite.networkTests != null) {
      buffer.writeln('--- Network Tests ---');
      _addBenchmarkToReport(buffer, suite.networkTests!.apiCallTest);
      _addBenchmarkToReport(buffer, suite.networkTests!.connectionPoolTest);
      buffer.writeln();
    }

    buffer.writeln('=== End Report ===');
    return buffer.toString();
  }

  /// Add benchmark results to report
  void _addBenchmarkToReport(StringBuffer buffer, BenchmarkResult benchmark) {
    buffer.writeln('${benchmark.name}:');
    buffer.writeln('  Average: ${benchmark.averageDuration.inMilliseconds}ms');
    buffer.writeln('  Min: ${benchmark.minDuration.inMilliseconds}ms');
    buffer.writeln('  Max: ${benchmark.maxDuration.inMilliseconds}ms');
    buffer.writeln('  Success Rate: ${benchmark.successRate.toStringAsFixed(2)}%');
    if (benchmark.error != null) {
      buffer.writeln('  Error: ${benchmark.error}');
    }
  }

  /// Get all benchmark results
  Map<String, BenchmarkResult> getAllBenchmarks() => Map.unmodifiable(_benchmarks);

  /// Clear all test results
  void clearResults() {
    _testResults.clear();
    _benchmarks.clear();
    _logger.info('Performance test results cleared');
  }
}

/// Performance test suite container
class PerformanceTestSuite {
  final DateTime startTime;
  final int iterations;
  DateTime? endTime;
  Duration? totalDuration;
  String? error;
  
  MemoryTestResults? memoryTests;
  CacheTestResults? cacheTests;
  DatabaseTestResults? databaseTests;
  NetworkTestResults? networkTests;

  PerformanceTestSuite({
    required this.startTime,
    required this.iterations,
  });
}

/// Memory test results
class MemoryTestResults {
  late BenchmarkResult allocationTest;
  late BenchmarkResult cleanupTest;
  late BenchmarkResult gcStressTest;
}

/// Cache test results
class CacheTestResults {
  late BenchmarkResult writeTest;
  late BenchmarkResult readTest;
  late BenchmarkResult missTest;
}

/// Database test results
class DatabaseTestResults {
  late BenchmarkResult writeTest;
  late BenchmarkResult readTest;
  late BenchmarkResult batchTest;
}

/// Network test results
class NetworkTestResults {
  late BenchmarkResult apiCallTest;
  late BenchmarkResult connectionPoolTest;
}

/// Individual benchmark result
class BenchmarkResult {
  final String name;
  final int iterations;
  final List<Duration> durations;
  final List<dynamic> results;
  final String? error;

  BenchmarkResult({
    required this.name,
    required this.iterations,
    required this.durations,
    required this.results,
    this.error,
  });

  Duration get averageDuration {
    if (durations.isEmpty) return Duration.zero;
    final totalMs = durations.fold(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: totalMs ~/ durations.length);
  }

  Duration get minDuration {
    if (durations.isEmpty) return Duration.zero;
    return durations.reduce((a, b) => a < b ? a : b);
  }

  Duration get maxDuration {
    if (durations.isEmpty) return Duration.zero;
    return durations.reduce((a, b) => a > b ? a : b);
  }

  double get successRate {
    if (iterations == 0) return 0.0;
    return (durations.length / iterations) * 100.0;
  }
}

/// Performance test result
class PerformanceTestResult {
  final String testName;
  final DateTime timestamp;
  final Duration duration;
  final bool success;
  final String? error;
  final Map<String, dynamic> metrics;

  PerformanceTestResult({
    required this.testName,
    required this.timestamp,
    required this.duration,
    required this.success,
    this.error,
    this.metrics = const {},
  });
}
