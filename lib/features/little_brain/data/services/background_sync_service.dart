import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';

import '../repositories/little_brain_local_repository.dart';
import '../../../../core/services/backend_api_service.dart';

@injectable
class BackgroundSyncService {
  final LittleBrainLocalRepository _localRepo;
  final BackendApiService _backendApi;

  BackgroundSyncService(
    this._localRepo,
    this._backendApi,
  );

  // Set token untuk authentication (tidak diperlukan lagi karena BackendApiService handle ini)
  void setAuthToken(String token) {
    // BackendApiService automatically handles authentication tokens
  }

  // Main sync method - hanya sync ketika kondisi optimal
  Future<SyncResult> syncWhenOptimal() async {
    try {
      // Check kondisi optimal
      if (!await _isOptimalConditions()) {
        return SyncResult(
          success: false,
          message: 'Conditions not optimal for sync',
          skipped: true,
        );
      }

      // Check jika sync diperlukan
      final syncNeeded = await _isSyncNeeded();
      if (!syncNeeded) {
        return SyncResult(
          success: true,
          message: 'No sync needed - data unchanged',
          skipped: true,
        );
      }

      // Perform sync
      await _performSync();
      
      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        skipped: false,
      );

    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        skipped: false,
      );
    }
  }

  // Force sync tanpa checking kondisi optimal
  Future<SyncResult> forceSync() async {
    try {
      await _performSync();
      return SyncResult(
        success: true,
        message: 'Force sync completed',
        skipped: false,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Force sync failed: $e',
        skipped: false,
      );
    }
  }

  // Check apakah kondisi optimal untuk sync
  Future<bool> _isOptimalConditions() async {
    // Check WiFi connection
    final connectivity = Connectivity();
    final connectivityResults = await connectivity.checkConnectivity();
    
    bool hasWifi = false;
    for (final result in connectivityResults) {
      if (result == ConnectivityResult.wifi) {
        hasWifi = true;
        break;
      }
    }
    
    if (!hasWifi) {
      return false;
    }

    // Check battery level (sync only if > 30% atau sedang charging)
    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;
    final batteryState = await battery.batteryState;
    
    if (batteryLevel < 30 && batteryState != BatteryState.charging) {
      return false;
    }

    // Check time - avoid sync during late night (23:00 - 06:00)
    final hour = DateTime.now().hour;
    if (hour >= 23 || hour < 6) {
      return false;
    }

    return true;
  }

  // Check apakah sync diperlukan berdasarkan checksum
  Future<bool> _isSyncNeeded() async {
    final localChecksum = await _calculateLocalChecksum();
    final lastSyncChecksum = await _getLastSyncChecksum();
    
    return localChecksum != lastSyncChecksum;
  }

  // Perform actual sync operation
  Future<void> _performSync() async {
    try {
      // Prepare sync data
      final syncData = await _prepareSyncData();
      final deviceId = await _getDeviceId();
      
      // Create backup using BackendApiService
      await _backendApi.createBackup(
        encryptedData: syncData['encryptedData'],
        dataSize: syncData['dataSize'],
        checksum: syncData['checksum'],
      );

      // Update sync status
      await _backendApi.updateSyncStatus(
        deviceId: deviceId,
        dataHash: syncData['checksum'],
        syncVersion: syncData['syncVersion'] ?? 1,
      );

      // Update local sync metadata
      await _updateLocalSyncMetadata(syncData['checksum']);
    } catch (e) {
      throw Exception('Sync failed: $e');
    }
  }

  // Prepare minimal sync data
  Future<Map<String, dynamic>> _prepareSyncData() async {
    final profile = await _localRepo.getPersonalityProfile();
    final checksum = await _calculateLocalChecksum();
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'checksum': checksum,
      'memory_count': profile?.memoryCount ?? 0,
      'personality_traits': profile?.traits ?? {},
      'interests': (profile?.interests != null) ? profile!.interests.take(10).toList() : <dynamic>[],
      'values': (profile?.values != null) ? profile!.values.take(5).toList() : <dynamic>[],
      'communication_patterns': profile?.communicationPatterns ?? {},
      'device_info': {
        'platform': Platform.operatingSystem,
        'version': Platform.operatingSystemVersion,
        'app_version': '1.0.0',
      },
      'sync_metadata': {
        'sync_type': 'background',
        'data_size': await _estimateDataSize(),
      }
    };
  }

  // Calculate checksum dari data lokal
  Future<String> _calculateLocalChecksum() async {
    final profile = await _localRepo.getPersonalityProfile();
    
    final dataString = jsonEncode({
      'memory_count': profile?.memoryCount ?? 0,
      'traits_sum': (profile?.traits != null) ? profile!.traits.values.fold(0.0, (a, b) => a + b) : 0.0,
      'interests_hash': (profile?.interests != null) ? profile!.interests.join('|') : '',
      'last_updated': (profile?.lastUpdated != null) ? profile!.lastUpdated.toIso8601String() : '',
    });
    
    return sha256.convert(utf8.encode(dataString)).toString().substring(0, 16);
  }

  // Get checksum dari last sync
  Future<String> _getLastSyncChecksum() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_sync_checksum') ?? '';
  }

  // Update local sync metadata
  Future<void> _updateLocalSyncMetadata(String checksum) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_sync_checksum', checksum);
    await prefs.setString('last_sync_time', DateTime.now().toIso8601String());
  }

  // Estimate ukuran data untuk logging
  Future<int> _estimateDataSize() async {
    final profile = await _localRepo.getPersonalityProfile();
    final dataString = jsonEncode({
      'personality_traits': profile?.traits ?? {},
      'interests': profile?.interests ?? [],
      'values': profile?.values ?? [],
    });
    return utf8.encode(dataString).length;
  }

  // Get sync status untuk UI
  Future<SyncStatus> getSyncStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncTime = prefs.getString('last_sync_time');
    final lastSyncChecksum = prefs.getString('last_sync_checksum') ?? '';
    final currentChecksum = await _calculateLocalChecksum();
    
    return SyncStatus(
      lastSyncTime: lastSyncTime != null ? DateTime.parse(lastSyncTime) : null,
      syncNeeded: lastSyncChecksum != currentChecksum,
      isOptimalConditions: await _isOptimalConditions(),
    );
  }

  // Schedule sync untuk dijalankan secara periodic
  Future<void> schedulePeriodicSync() async {
    // This could be implemented with background tasks/isolates
    // For now, just store the schedule preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', true);
    await prefs.setInt('sync_interval_hours', 6); // Sync every 6 hours if optimal
  }

  // Download backup dari server (untuk disaster recovery)
  Future<SyncResult> downloadBackup() async {
    try {
      final backup = await _backendApi.getLatestBackup();
      
      if (backup != null) {
        // Implement backup restoration logic if needed
        return SyncResult(
          success: true,
          message: 'Backup downloaded successfully',
          skipped: false,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'No backup available',
          skipped: true,
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Download backup failed: $e',
        skipped: false,
      );
    }
  }

  // Clear sync history (for reset)
  Future<void> clearSyncHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_sync_checksum');
    await prefs.remove('last_sync_time');
  }

  // Get device ID for sync tracking
  Future<String> _getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('device_id');
    
    if (deviceId == null) {
      deviceId = DateTime.now().millisecondsSinceEpoch.toString();
      await prefs.setString('device_id', deviceId);
    }
    
    return deviceId;
  }
}

// Result class untuk sync operations
class SyncResult {
  final bool success;
  final String message;
  final bool skipped;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    required this.message,
    required this.skipped,
  }) : timestamp = DateTime.now();

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, skipped: $skipped, timestamp: $timestamp)';
  }
}

// Status class untuk sync information
class SyncStatus {
  final DateTime? lastSyncTime;
  final bool syncNeeded;
  final bool isOptimalConditions;

  SyncStatus({
    required this.lastSyncTime,
    required this.syncNeeded,
    required this.isOptimalConditions,
  });

  String get statusMessage {
    if (lastSyncTime == null) {
      return 'Never synced';
    }
    
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);
    
    String timeAgo;
    if (difference.inMinutes < 60) {
      timeAgo = '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      timeAgo = '${difference.inHours} hours ago';
    } else {
      timeAgo = '${difference.inDays} days ago';
    }
    
    if (syncNeeded) {
      return 'Sync needed (last: $timeAgo)';
    } else {
      return 'Up to date (last: $timeAgo)';
    }
  }

  bool get shouldShowSyncButton {
    return syncNeeded || (lastSyncTime == null);
  }
}
