import 'dart:async';
import 'dart:math';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/little_brain/data/services/background_sync_service.dart';
import '../../injection_container.dart';

/// Service that schedules and manages automatic background synchronization
@singleton
class SyncSchedulerService {
  static const String _lastSyncTimestampKey = 'last_sync_timestamp';
  static const String _syncIntervalMinutesKey = 'sync_interval_minutes';
  static const int _defaultSyncIntervalMinutes = 30; // 30 minutes
  static const int _maxSyncIntervalMinutes = 480; // 8 hours
  
  Timer? _syncTimer;
  bool _isRunning = false;
  late final BackgroundSyncService _syncService;

  SyncSchedulerService() {
    _syncService = getIt<BackgroundSyncService>();
  }

  /// Start automatic synchronization scheduler
  Future<void> startScheduler() async {
    if (_isRunning) return;
    
    _isRunning = true;
    
    // Initial sync attempt
    _performSyncWithRetry();
    
    // Schedule periodic syncs
    await _schedulePeriodicSync();
  }

  /// Stop automatic synchronization scheduler
  void stopScheduler() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _isRunning = false;
  }

  /// Force a manual sync
  Future<SchedulerSyncResult> forceSyncNow() async {
    try {
      final result = await _syncService.forceSync();
      
      if (result.success) {
        await _updateLastSyncTimestamp();
        await _resetSyncInterval(); // Reset to default interval on successful sync
      } else {
        await _increaseSyncInterval(); // Increase interval on failure
      }
      
      return SchedulerSyncResult(
        success: result.success,
        message: result.message,
        skipped: result.skipped,
      );
    } catch (e) {
      await _increaseSyncInterval();
      return SchedulerSyncResult(
        success: false,
        message: 'Force sync failed: $e',
        skipped: false,
      );
    }
  }

  /// Check if sync is needed based on time since last sync
  Future<bool> isSyncNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimestamp = prefs.getInt(_lastSyncTimestampKey) ?? 0;
    final syncIntervalMinutes = prefs.getInt(_syncIntervalMinutesKey) ?? _defaultSyncIntervalMinutes;
    
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);
    final nextSyncTime = lastSyncTime.add(Duration(minutes: syncIntervalMinutes));
    
    return DateTime.now().isAfter(nextSyncTime);
  }

  /// Get time until next scheduled sync
  Future<Duration> timeUntilNextSync() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimestamp = prefs.getInt(_lastSyncTimestampKey) ?? 0;
    final syncIntervalMinutes = prefs.getInt(_syncIntervalMinutesKey) ?? _defaultSyncIntervalMinutes;
    
    final lastSyncTime = DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp);
    final nextSyncTime = lastSyncTime.add(Duration(minutes: syncIntervalMinutes));
    final now = DateTime.now();
    
    if (now.isAfter(nextSyncTime)) {
      return Duration.zero; // Sync is overdue
    }
    
    return nextSyncTime.difference(now);
  }

  /// Get sync statistics
  Future<SyncStats> getSyncStats() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTimestamp = prefs.getInt(_lastSyncTimestampKey) ?? 0;
    final syncIntervalMinutes = prefs.getInt(_syncIntervalMinutesKey) ?? _defaultSyncIntervalMinutes;
    
    return SyncStats(
      lastSyncTime: lastSyncTimestamp > 0 
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp) 
          : null,
      nextSyncTime: lastSyncTimestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncTimestamp).add(Duration(minutes: syncIntervalMinutes))
          : DateTime.now().add(Duration(minutes: syncIntervalMinutes)),
      syncIntervalMinutes: syncIntervalMinutes,
      isSchedulerRunning: _isRunning,
    );
  }

  /// Schedule periodic synchronization
  Future<void> _schedulePeriodicSync() async {
    final syncIntervalMinutes = await _getCurrentSyncInterval();
    
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      Duration(minutes: syncIntervalMinutes),
      (timer) => _performSyncWithRetry(),
    );
  }

  /// Perform sync with retry logic and adaptive interval
  Future<void> _performSyncWithRetry() async {
    try {
      final result = await _syncService.syncWhenOptimal();
      
      if (result.success) {
        await _updateLastSyncTimestamp();
        await _resetSyncInterval(); // Reset to default interval on successful sync
      } else if (!result.skipped) {
        // Increase interval only for actual failures, not skipped syncs
        await _increaseSyncInterval();
      }
      
      // Reschedule with new interval if it changed
      if (result.success || !result.skipped) {
        await _schedulePeriodicSync();
      }
      
    } catch (e) {
      print('Sync error: $e');
      await _increaseSyncInterval();
      await _schedulePeriodicSync();
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get current sync interval in minutes
  Future<int> _getCurrentSyncInterval() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_syncIntervalMinutesKey) ?? _defaultSyncIntervalMinutes;
  }

  /// Reset sync interval to default
  Future<void> _resetSyncInterval() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_syncIntervalMinutesKey, _defaultSyncIntervalMinutes);
  }

  /// Increase sync interval on failures (exponential backoff)
  Future<void> _increaseSyncInterval() async {
    final prefs = await SharedPreferences.getInstance();
    final currentInterval = prefs.getInt(_syncIntervalMinutesKey) ?? _defaultSyncIntervalMinutes;
    
    // Exponential backoff with jitter
    final newInterval = min(
      (currentInterval * 1.5).round() + Random().nextInt(5), // Add 0-4 minutes of jitter
      _maxSyncIntervalMinutes
    );
    
    await prefs.setInt(_syncIntervalMinutesKey, newInterval);
  }
}

/// Result of a sync operation
class SchedulerSyncResult {
  final bool success;
  final String message;
  final bool skipped;
  final DateTime timestamp;

  SchedulerSyncResult({
    required this.success,
    required this.message,
    required this.skipped,
  }) : timestamp = DateTime.now();
}

/// Sync statistics
class SyncStats {
  final DateTime? lastSyncTime;
  final DateTime nextSyncTime;
  final int syncIntervalMinutes;
  final bool isSchedulerRunning;

  const SyncStats({
    required this.lastSyncTime,
    required this.nextSyncTime,
    required this.syncIntervalMinutes,
    required this.isSchedulerRunning,
  });
}
