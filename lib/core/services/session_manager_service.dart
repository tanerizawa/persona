import 'dart:async';

import 'logging_service.dart';
import 'error_tracking_service.dart';
import 'performance_service.dart';

/// Session management service with connection pooling and optimization
class SessionManagerService {
  static final SessionManagerService _instance = SessionManagerService._internal();
  factory SessionManagerService() => _instance;
  SessionManagerService._internal();

  final LoggingService _logger = LoggingService();
  final ErrorTrackingService _errorTracking = ErrorTrackingService();
  final PerformanceService _performance = PerformanceService();

  // Session tracking
  final Map<String, SessionData> _activeSessions = {};
  
  // Request batching for optimization
  final Map<String, List<BatchedRequest>> _pendingRequests = {};
  Timer? _batchTimer;

  static const Duration _sessionTimeout = Duration(minutes: 30);
  static const Duration _batchInterval = Duration(milliseconds: 200);
  static const int _maxBatchSize = 10;

  /// Initialize session management
  Future<void> initialize() async {
    _logger.info('Initializing session manager');
    _startBatchTimer();
    _startSessionCleanup();
  }

  /// Get or create optimized session
  Future<String> getOptimizedSession({
    String? userId,
    Map<String, dynamic>? metadata,
  }) async {
    return await _performance.executeWithTracking(
      'session_get_optimized',
      () async {
        try {
          // Check for existing session
          if (userId != null) {
            final existingSession = _findSessionByUserId(userId);
            if (existingSession != null && !_isSessionExpired(existingSession)) {
              _activeSessions[existingSession]!.lastAccessed = DateTime.now();
              return existingSession;
            }
          }

          // Create new session
          final sessionId = _generateSessionId();
          final sessionData = SessionData(
            id: sessionId,
            userId: userId,
            metadata: metadata ?? {},
            createdAt: DateTime.now(),
            lastAccessed: DateTime.now(),
          );

          _activeSessions[sessionId] = sessionData;
          _logger.debug('Created new session: $sessionId for user: $userId');

          return sessionId;
        } catch (e) {
          _errorTracking.trackError(
            'Failed to get optimized session',
            context: 'session_management',
            metadata: {'user_id': userId},
          );
          rethrow;
        }
      },
    );
  }

  /// Batch similar requests for efficiency
  Future<T> batchRequest<T>(
    String endpoint,
    Future<T> Function() request, {
    String? sessionId,
    Duration? timeout,
  }) async {
    final requestId = _generateRequestId();
    final completer = Completer<T>();
    
    final batchedRequest = BatchedRequest(
      id: requestId,
      endpoint: endpoint,
      request: request,
      completer: completer,
      sessionId: sessionId,
      timestamp: DateTime.now(),
    );

    // Add to pending requests
    _pendingRequests.putIfAbsent(endpoint, () => []).add(batchedRequest);
    
    // Process batch if it's full
    if (_pendingRequests[endpoint]!.length >= _maxBatchSize) {
      await _processBatch(endpoint);
    }

    // Wait for result with timeout
    return await completer.future.timeout(
      timeout ?? const Duration(seconds: 30),
      onTimeout: () {
        _errorTracking.trackError(
          'Request timeout',
          context: 'session_batch_request',
          metadata: {'endpoint': endpoint, 'request_id': requestId},
        );
        throw TimeoutException('Request timed out', timeout);
      },
    );
  }

  /// Update session activity
  void updateSessionActivity(String sessionId, {
    Map<String, dynamic>? metadata,
  }) {
    final session = _activeSessions[sessionId];
    if (session != null) {
      session.lastAccessed = DateTime.now();
      if (metadata != null) {
        session.metadata.addAll(metadata);
      }
    }
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    return {
      'active_sessions': _activeSessions.length,
      'pending_batches': _pendingRequests.length,
      'total_pending_requests': _pendingRequests.values
          .fold(0, (sum, requests) => sum + requests.length),
      'session_details': _activeSessions.entries.map((entry) => {
        'id': entry.key,
        'user_id': entry.value.userId,
        'created_at': entry.value.createdAt.toIso8601String(),
        'last_accessed': entry.value.lastAccessed.toIso8601String(),
        'is_expired': _isSessionExpired(entry.key),
      }).toList(),
    };
  }

  /// Invalidate session
  Future<void> invalidateSession(String sessionId) async {
    await _performance.executeWithTracking(
      'session_invalidate',
      () async {
        final session = _activeSessions.remove(sessionId);
        if (session != null) {
          _logger.debug('Invalidated session: $sessionId');
          
          // Cancel any pending requests for this session
          for (final requests in _pendingRequests.values) {
            requests.removeWhere((request) {
              if (request.sessionId == sessionId) {
                request.completer.completeError(
                  Exception('Session invalidated')
                );
                return true;
              }
              return false;
            });
          }
        }
      },
    );
  }

  /// Cleanup expired sessions
  Future<void> cleanupExpiredSessions() async {
    await _performance.executeWithTracking(
      'session_cleanup_expired',
      () async {
        final expiredSessions = <String>[];
        
        for (final entry in _activeSessions.entries) {
          if (_isSessionExpired(entry.key)) {
            expiredSessions.add(entry.key);
          }
        }
        
        for (final sessionId in expiredSessions) {
          await invalidateSession(sessionId);
        }
        
        if (expiredSessions.isNotEmpty) {
          _logger.info('Cleaned up ${expiredSessions.length} expired sessions');
        }
      },
    );
  }

  /// Find session by user ID
  String? _findSessionByUserId(String userId) {
    for (final entry in _activeSessions.entries) {
      if (entry.value.userId == userId) {
        return entry.key;
      }
    }
    return null;
  }

  /// Check if session is expired
  bool _isSessionExpired(String sessionId) {
    final session = _activeSessions[sessionId];
    if (session == null) return true;
    
    return DateTime.now().difference(session.lastAccessed) > _sessionTimeout;
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${_activeSessions.length}';
  }

  /// Generate unique request ID
  String _generateRequestId() {
    return 'req_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Start batch processing timer
  void _startBatchTimer() {
    _batchTimer?.cancel();
    _batchTimer = Timer.periodic(_batchInterval, (_) {
      _processAllBatches();
    });
  }

  /// Start session cleanup timer
  void _startSessionCleanup() {
    Timer.periodic(const Duration(minutes: 5), (_) {
      cleanupExpiredSessions();
    });
  }

  /// Process all pending batches
  Future<void> _processAllBatches() async {
    final endpointsToProcess = _pendingRequests.keys.toList();
    
    for (final endpoint in endpointsToProcess) {
      if (_pendingRequests[endpoint]?.isNotEmpty == true) {
        await _processBatch(endpoint);
      }
    }
  }

  /// Process batch for specific endpoint
  Future<void> _processBatch(String endpoint) async {
    final requests = _pendingRequests[endpoint];
    if (requests == null || requests.isEmpty) return;

    // Take up to max batch size
    final batch = requests.take(_maxBatchSize).toList();
    requests.removeRange(0, batch.length);

    // Remove empty endpoint list
    if (requests.isEmpty) {
      _pendingRequests.remove(endpoint);
    }

    _logger.debug('Processing batch of ${batch.length} requests for $endpoint');

    // Execute requests in parallel with limited concurrency
    final futures = <Future>[];
    for (final request in batch) {
      futures.add(_executeRequest(request));
    }

    try {
      await Future.wait(futures);
    } catch (e) {
      _logger.error('Batch processing failed for $endpoint', e);
    }
  }

  /// Execute individual request
  Future<void> _executeRequest(BatchedRequest request) async {
    try {
      final result = await request.request();
      request.completer.complete(result);
    } catch (e) {
      _errorTracking.trackError(
        'Batched request failed',
        context: 'session_batch_execution',
        metadata: {
          'endpoint': request.endpoint,
          'request_id': request.id,
          'session_id': request.sessionId,
        },
      );
      request.completer.completeError(e);
    }
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _batchTimer = null;
    _activeSessions.clear();
    _pendingRequests.clear();
    _logger.info('Session manager disposed');
  }
}

/// Session data class
class SessionData {
  final String id;
  final String? userId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  DateTime lastAccessed;

  SessionData({
    required this.id,
    this.userId,
    required this.metadata,
    required this.createdAt,
    required this.lastAccessed,
  });
}

/// Batched request class
class BatchedRequest<T> {
  final String id;
  final String endpoint;
  final Future<T> Function() request;
  final Completer<T> completer;
  final String? sessionId;
  final DateTime timestamp;

  BatchedRequest({
    required this.id,
    required this.endpoint,
    required this.request,
    required this.completer,
    this.sessionId,
    required this.timestamp,
  });
}
