import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'connectivity_service.dart';

/// Service untuk menangani offline mode dan memastikan aplikasi dapat dibuka
/// dalam kondisi apapun (offline/online, dengan/tanpa API key, dengan/tanpa backend)
class OfflineModeService {
  static const String _tag = 'OfflineModeService';
  
  final ConnectivityService _connectivityService;
  
  // Keys for SharedPreferences
  static const String _hasOpenedOfflineKey = 'has_opened_offline';
  static const String _lastOnlineTimeKey = 'last_online_time';
  static const String _offlineWarningShownKey = 'offline_warning_shown';
  
  OfflineModeService(this._connectivityService);
  
  /// Initialize offline mode service
  Future<void> initialize() async {
    if (kDebugMode) {
      print('$_tag: Initializing offline mode service...');
    }
    
    await _checkAndSetOfflineStatus();
    
    // Listen for connectivity changes
    _connectivityService.onConnectivityChanged.listen(_onConnectivityChanged);
  }
  
  /// Check current offline status and update preferences
  Future<void> _checkAndSetOfflineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isOnline = _connectivityService.isOnline;
    
    if (isOnline) {
      // Record last online time
      await prefs.setString(_lastOnlineTimeKey, DateTime.now().toIso8601String());
      
      // Reset offline warning
      await prefs.setBool(_offlineWarningShownKey, false);
      
      if (kDebugMode) {
        print('$_tag: ✅ Online mode - all features available');
      }
    } else {
      // Mark that we've opened in offline mode
      await prefs.setBool(_hasOpenedOfflineKey, true);
      
      if (kDebugMode) {
        print('$_tag: 📴 Offline mode - local features only');
      }
    }
  }
  
  /// Handle connectivity changes
  void _onConnectivityChanged(bool isOnline) async {
    if (kDebugMode) {
      print('$_tag: Connectivity changed to ${isOnline ? 'online' : 'offline'}');
    }
    
    await _checkAndSetOfflineStatus();
  }
  
  /// Check if app has ever been opened offline
  Future<bool> hasOpenedOffline() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasOpenedOfflineKey) ?? false;
  }
  
  /// Get last online time
  Future<DateTime?> getLastOnlineTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_lastOnlineTimeKey);
    
    if (timeString != null) {
      try {
        return DateTime.parse(timeString);
      } catch (e) {
        return null;
      }
    }
    
    return null;
  }
  
  /// Check if offline warning should be shown
  Future<bool> shouldShowOfflineWarning() async {
    if (_connectivityService.isOnline) {
      return false;
    }
    
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_offlineWarningShownKey) ?? false);
  }
  
  /// Mark offline warning as shown
  Future<void> markOfflineWarningShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineWarningShownKey, true);
  }
  
  /// Get offline mode configuration
  Map<String, dynamic> getOfflineModeConfig() {
    final isOnline = _connectivityService.isOnline;
    
    return {
      'isOnline': isOnline,
      'hasInternet': _connectivityService.hasInternet,
      'enabledFeatures': _getEnabledFeatures(isOnline),
      'disabledFeatures': _getDisabledFeatures(isOnline),
      'userMessage': _getUserMessage(isOnline),
      'statusIcon': _connectivityService.getConnectivityIcon(),
      'statusText': _connectivityService.getConnectivityDescription(),
    };
  }
  
  /// Get list of features that are enabled in current mode
  List<String> _getEnabledFeatures(bool isOnline) {
    final enabledFeatures = [
      'mood_tracking',
      'psychology_tests',
      'local_chat_history',
      'settings',
      'profile_management',
      'data_export',
      'biometric_auth',
      'crisis_detection_local',
    ];
    
    if (isOnline) {
      enabledFeatures.addAll([
        'ai_chat',
        'content_generation',
        'personality_analysis',
        'cloud_sync',
        'crisis_intervention_online',
        'push_notifications',
      ]);
    }
    
    return enabledFeatures;
  }
  
  /// Get list of features that are disabled in current mode
  List<String> _getDisabledFeatures(bool isOnline) {
    if (isOnline) {
      return []; // All features available online
    }
    
    return [
      'ai_chat',
      'content_generation',
      'personality_analysis',
      'cloud_sync',
      'crisis_intervention_online',
      'push_notifications',
    ];
  }
  
  /// Get user-friendly message for current mode
  String _getUserMessage(bool isOnline) {
    if (isOnline) {
      return 'Semua fitur tersedia. Anda terhubung ke internet.';
    }
    
    return 'Mode offline aktif. Fitur AI tidak tersedia, tetapi Anda masih dapat '
           'menggunakan pelacakan mood, tes psikologi, dan riwayat lokal.';
  }
  
  /// Get fallback data for offline mode
  Map<String, dynamic> getOfflineFallback(String context) {
    return {
      'success': false,
      'error': 'OFFLINE_MODE',
      'message': 'Aplikasi dalam mode offline.',
      'fallback': _getOfflineContent(context),
      'userMessage': 'Mode offline aktif. Menggunakan fitur lokal.',
    };
  }
  
  /// Get offline content based on context
  Map<String, dynamic> _getOfflineContent(String context) {
    switch (context) {
      case 'chat':
        return {
          'type': 'chat_fallback',
          'content': 'Fitur chat AI tidak tersedia dalam mode offline. '
                    'Anda dapat melihat riwayat chat sebelumnya.',
        };
      case 'content_generation':
        return {
          'type': 'content_fallback',
          'content': 'Konten AI tidak tersedia dalam mode offline. '
                    'Gunakan fitur mood tracking dan psychology tests.',
        };
      default:
        return {
          'type': 'general_fallback',
          'content': 'Fitur ini memerlukan koneksi internet.',
        };
    }
  }
  
  /// Check if a specific feature is available
  bool isFeatureAvailable(String feature) {
    final config = getOfflineModeConfig();
    final enabledFeatures = config['enabledFeatures'] as List<String>;
    return enabledFeatures.contains(feature);
  }
  
  /// Get offline content for home screen
  Map<String, dynamic> getOfflineHomeContent() {
    return {
      'music_recommendations': [
        {
          'title': 'Musik Relaksasi Offline',
          'description': 'Dengarkan musik klasik atau ambient untuk menenangkan pikiran',
          'action': 'local_music_suggestion',
        }
      ],
      'articles': [
        {
          'title': 'Tips Kesehatan Mental',
          'description': 'Praktikkan teknik pernapasan dan mindfulness setiap hari',
          'category': 'mental_health',
        }
      ],
      'quotes': [
        {
          'text': 'Setiap hari adalah kesempatan baru untuk menjadi versi terbaik dari diri kita.',
          'author': 'Persona AI',
        }
      ],
      'journal_prompts': [
        {
          'text': 'Apa 3 hal yang membuat saya bersyukur hari ini?',
          'category': 'gratitude',
        }
      ],
    };
  }
  
  /// Get offline chat responses
  List<String> getOfflineChatResponses() {
    return [
      'Saya sedang dalam mode offline. Fitur AI tidak tersedia saat ini, '
      'tetapi Anda dapat mengakses pelacakan mood dan tes psikologi.',
      
      'Mode offline aktif. Anda masih dapat melihat riwayat chat sebelumnya '
      'dan menggunakan fitur lokal aplikasi.',
      
      'Koneksi internet tidak tersedia. Silakan gunakan fitur offline seperti '
      'mood tracking atau psychology tests sambil menunggu koneksi kembali.',
    ];
  }
  
  /// Get app status for debugging
  Map<String, dynamic> getAppStatus() {
    return {
      'connectivity': {
        'isOnline': _connectivityService.isOnline,
        'hasInternet': _connectivityService.hasInternet,
        'isOptimalForSync': false, // Will be updated by connectivity check
      },
      'features': {
        'enabledCount': _getEnabledFeatures(_connectivityService.isOnline).length,
        'disabledCount': _getDisabledFeatures(_connectivityService.isOnline).length,
      },
      'offline_mode': {
        'hasOpenedOffline': false, // Will be updated by async call
        'lastOnlineTime': null, // Will be updated by async call
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  /// Ensure app can start in any condition
  Future<bool> ensureAppCanStart() async {
    try {
      if (kDebugMode) {
        print('$_tag: Ensuring app can start in current conditions...');
      }
      
      // Check if we can initialize basic services
      await _initializeBasicServices();
      
      // Verify local storage is working
      final storageWorking = await _verifyLocalStorage();
      if (!storageWorking) {
        if (kDebugMode) {
          print('$_tag: ⚠️ Local storage issue detected, but app can still start');
        }
      }
      
      // App can always start, even without internet or with storage issues
      if (kDebugMode) {
        print('$_tag: ✅ App can start successfully');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('$_tag: ⚠️ App startup issue detected: $e');
        print('$_tag: ✅ But app will still attempt to start');
      }
      
      // Even if there are issues, allow app to start
      return true;
    }
  }
  
  /// Initialize basic services required for app startup
  Future<void> _initializeBasicServices() async {
    // Initialize SharedPreferences for local settings
    try {
      await SharedPreferences.getInstance();
    } catch (e) {
      if (kDebugMode) {
        print('$_tag: SharedPreferences initialization failed: $e');
      }
    }
    
    // Other basic initializations can be added here
  }
  
  /// Verify local storage is working
  Future<bool> _verifyLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Test write and read
      const testKey = 'app_startup_test';
      const testValue = 'test_value';
      
      await prefs.setString(testKey, testValue);
      final readValue = prefs.getString(testKey);
      
      // Clean up test data
      await prefs.remove(testKey);
      
      return readValue == testValue;
      
    } catch (e) {
      if (kDebugMode) {
        print('$_tag: Local storage verification failed: $e');
      }
      return false;
    }
  }
}
