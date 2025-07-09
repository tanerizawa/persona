import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service untuk mendeteksi status konektivitas dan menangani mode offline/online
class ConnectivityService {
  static const String _tag = 'ConnectivityService';
  
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  
  // Stream controller untuk broadcast status konektivitas
  final StreamController<bool> _isOnlineController = StreamController<bool>.broadcast();
  
  bool _isOnline = true;
  bool _hasInternet = true;
  
  /// Get current online status
  bool get isOnline => _isOnline;
  
  /// Get current internet status (actual internet connectivity)
  bool get hasInternet => _hasInternet;
  
  /// Stream untuk listen perubahan status online/offline
  Stream<bool> get onConnectivityChanged => _isOnlineController.stream;
  
  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (kDebugMode) {
      print('$_tag: Initializing connectivity monitoring...');
    }
    
    // Check initial connectivity status
    await _checkInitialConnectivity();
    
    // Listen for connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
      onError: (error) {
        if (kDebugMode) {
          print('$_tag: Connectivity stream error: $error');
        }
      },
    );
  }
  
  /// Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      await _updateConnectivityStatus(connectivityResults);
    } catch (e) {
      if (kDebugMode) {
        print('$_tag: Error checking initial connectivity: $e');
      }
      // Assume offline if we can't check
      _updateOnlineStatus(false, false);
    }
  }
  
  /// Handle connectivity changes
  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    await _updateConnectivityStatus(results);
  }
  
  /// Update connectivity status based on results
  Future<void> _updateConnectivityStatus(List<ConnectivityResult> results) async {
    bool hasConnection = false;
    bool hasWifi = false;
    
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
          hasConnection = true;
          hasWifi = true;
          break;
        case ConnectivityResult.mobile:
          hasConnection = true;
          break;
        case ConnectivityResult.ethernet:
          hasConnection = true;
          break;
        case ConnectivityResult.none:
          break;
        default:
          break;
      }
    }
    
    if (kDebugMode) {
      print('$_tag: Connectivity changed - hasConnection: $hasConnection, hasWifi: $hasWifi');
    }
    
    // If we have a connection, verify actual internet access
    bool hasActualInternet = false;
    if (hasConnection) {
      hasActualInternet = await _verifyInternetAccess();
    }
    
    _updateOnlineStatus(hasConnection, hasActualInternet);
  }
  
  /// Verify actual internet access by pinging a reliable endpoint
  Future<bool> _verifyInternetAccess() async {
    // For now, assume we have internet if we have connectivity
    // In production, you might want to ping a reliable endpoint
    // But this could add latency to app startup
    return true;
  }
  
  /// Update online status and notify listeners
  void _updateOnlineStatus(bool isOnline, bool hasInternet) {
    final wasOnline = _isOnline;
    
    _isOnline = isOnline;
    _hasInternet = hasInternet;
    
    if (kDebugMode) {
      print('$_tag: Status updated - isOnline: $isOnline, hasInternet: $hasInternet');
    }
    
    // Notify listeners if status changed
    if (wasOnline != isOnline) {
      _isOnlineController.add(isOnline);
      
      if (kDebugMode) {
        print('$_tag: ${isOnline ? '🌐 Online' : '📴 Offline'} mode detected');
      }
    }
  }
  
  /// Force check connectivity status
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      await _updateConnectivityStatus(results);
      return _isOnline;
    } catch (e) {
      if (kDebugMode) {
        print('$_tag: Error checking connectivity: $e');
      }
      return false;
    }
  }
  
  /// Check if conditions are optimal for background sync
  Future<bool> isOptimalForSync() async {
    if (!_isOnline || !_hasInternet) {
      return false;
    }
    
    // Check if we're on WiFi (optimal for sync)
    try {
      final results = await _connectivity.checkConnectivity();
      return results.contains(ConnectivityResult.wifi);
    } catch (e) {
      return false;
    }
  }
  
  /// Get connectivity status description for UI
  String getConnectivityDescription() {
    if (!_isOnline) {
      return 'Tidak ada koneksi internet';
    }
    
    if (!_hasInternet) {
      return 'Koneksi terbatas';
    }
    
    return 'Tersambung ke internet';
  }
  
  /// Get connectivity icon for UI
  String getConnectivityIcon() {
    if (!_isOnline) {
      return '📴';
    }
    
    if (!_hasInternet) {
      return '⚠️';
    }
    
    return '🌐';
  }
  
  /// Dispose the service
  void dispose() {
    _connectivitySubscription?.cancel();
    _isOnlineController.close();
    
    if (kDebugMode) {
      print('$_tag: Connectivity service disposed');
    }
  }
}
