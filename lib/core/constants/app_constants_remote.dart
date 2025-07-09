import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/remote_config_service.dart';
import '../services/logging_service.dart';
import '../../injection_container.dart';

class AppConstants {
  static RemoteConfigService? _remoteConfig;
  static final LoggingService _logger = LoggingService();
  
  /// Initialize remote config service
  static Future<void> initializeRemoteConfig() async {
    try {
      _remoteConfig = getIt<RemoteConfigService>();
      await _remoteConfig!.getConfig();
      _logger.info('✅ Remote configuration initialized');
    } catch (e) {
      _logger.warning('⚠️ Remote config initialization failed, using local .env', e);
    }
  }
  
  /// Get current app config (remote or fallback to local)
  static Future<AppConfig?> getRemoteConfig() async {
    try {
      return await _remoteConfig?.getConfig();
    } catch (e) {
      return null;
    }
  }
  
  // ==========================================================================
  // DYNAMIC CONFIGURATION (Server-managed)
  // ==========================================================================
  
  /// App Information
  static String get appName {
    try {
      return _remoteConfig?.getConfig().then((config) => config.app.name) as String? 
        ?? dotenv.env['APP_NAME'] 
        ?? 'Persona Assistant';
    } catch (e) {
      return dotenv.env['APP_NAME'] ?? 'Persona Assistant';
    }
  }
  
  static String get appVersion {
    try {
      return _remoteConfig?.getConfig().then((config) => config.app.version) as String?
        ?? dotenv.env['APP_VERSION'] 
        ?? '1.0.0';
    } catch (e) {
      return dotenv.env['APP_VERSION'] ?? '1.0.0';
    }
  }
  
  /// Backend Configuration
  static Future<String> get backendBaseUrl async {
    try {
      final config = await _remoteConfig?.getConfig();
      return config?.backend.baseUrl ?? _fallbackBackendUrl;
    } catch (e) {
      return _fallbackBackendUrl;
    }
  }
  
  static String get _fallbackBackendUrl => 
    dotenv.env['BACKEND_BASE_URL'] ?? 
    (isEmulator ? 'http://10.0.2.2:3000' : 'http://localhost:3000');
  
  /// AI Configuration
  static Future<String> get defaultAiModel async {
    try {
      final config = await _remoteConfig?.getConfig();
      return config?.ai.defaultModel ?? _fallbackAiModel;
    } catch (e) {
      return _fallbackAiModel;
    }
  }
  
  static String get _fallbackAiModel => 
    dotenv.env['DEFAULT_MODEL'] ?? 'deepseek/deepseek-r1-0528:free';
  
  static Future<String> get personalityAnalysisModel async {
    try {
      final config = await _remoteConfig?.getConfig();
      return config?.ai.personalityModel ?? _fallbackPersonalityModel;
    } catch (e) {
      return _fallbackPersonalityModel;
    }
  }
  
  static String get _fallbackPersonalityModel => 
    dotenv.env['PERSONALITY_ANALYSIS_MODEL'] ?? 'gpt-4-turbo-preview';
  
  static Future<String> get moodAnalysisModel async {
    try {
      final config = await _remoteConfig?.getConfig();
      return config?.ai.moodModel ?? _fallbackMoodModel;
    } catch (e) {
      return _fallbackMoodModel;
    }
  }
  
  static String get _fallbackMoodModel => 
    dotenv.env['MOOD_ANALYSIS_MODEL'] ?? 'anthropic/claude-3-haiku:beta';
  
  /// Feature Flags (Dynamic)
  static Future<bool> get enablePushNotifications async {
    try {
      final config = await _remoteConfig?.getConfig();
      return config?.features.pushNotifications ?? _fallbackPushNotifications;
    } catch (e) {
      return _fallbackPushNotifications;
    }
  }
  
  static bool get _fallbackPushNotifications => 
    dotenv.env['ENABLE_PUSH_NOTIFICATIONS']?.toLowerCase() == 'true';
  
  static Future<bool> get enableBiometricAuth async {
    try {
      final config = await _remoteConfig?.getConfig();
      return config?.features.biometricAuth ?? _fallbackBiometricAuth;
    } catch (e) {
      return _fallbackBiometricAuth;
    }
  }
  
  static bool get _fallbackBiometricAuth => 
    dotenv.env['ENABLE_BIOMETRIC_AUTH']?.toLowerCase() == 'true';
  
  static Future<bool> get enableCrisisIntervention async {
    try {
      final config = await _remoteConfig?.getConfig();
      return config?.features.crisisIntervention ?? _fallbackCrisisIntervention;
    } catch (e) {
      return _fallbackCrisisIntervention;
    }
  }
  
  static bool get _fallbackCrisisIntervention => 
    dotenv.env['ENABLE_CRISIS_INTERVENTION']?.toLowerCase() == 'true';
  
  static Future<bool> get enableBackgroundSync async {
    try {
      final config = await _remoteConfig?.getConfig();
      return config?.features.backgroundSync ?? _fallbackBackgroundSync;
    } catch (e) {
      return _fallbackBackgroundSync;
    }
  }
  
  static bool get _fallbackBackgroundSync => 
    dotenv.env['ENABLE_BACKGROUND_SYNC']?.toLowerCase() == 'true';
  
  // ==========================================================================
  // STATIC CONFIGURATION (Security-sensitive, never exposed to server)
  // ==========================================================================
  
  /// API Keys (Always local, never from server)
  static String get openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static String get openRouterBaseUrl => dotenv.env['OPENROUTER_BASE_URL'] ?? 'https://openrouter.ai/api/v1';
  
  /// App Environment
  static String get environment => dotenv.env['NODE_ENV'] ?? 'development';
  static bool get isProduction => environment == 'production';
  static bool get enableLogging => !isProduction;
  static const bool isEmulator = true; // TODO: Implement actual detection
  
  /// Local Storage Keys (Static)
  static const String userProfileKey = 'user_profile';
  static const String chatHistoryKey = 'chat_history';
  static const String moodDataKey = 'mood_data';
  static const String psychologyTestsKey = 'psychology_tests';
  static const String personalityDataKey = 'personality_data';
  static const String settingsKey = 'settings';
  static const String memoriesKey = 'memories';
  static const String personalityModelKey = 'personality_model';
  static const String emotionalStateKey = 'emotional_state';
  
  // ==========================================================================
  // UTILITY METHODS
  // ==========================================================================
  
  /// Check if a feature is enabled (using remote config)
  static Future<bool> isFeatureEnabled(String featureName) async {
    try {
      final config = await _remoteConfig?.getConfig();
      if (config != null) {
        switch (featureName.toLowerCase()) {
          case 'pushnotifications':
            return config.features.pushNotifications;
          case 'biometricauth':
            return config.features.biometricAuth;
          case 'crisisintervention':
            return config.features.crisisIntervention;
          case 'backgroundsync':
            return config.features.backgroundSync;
          case 'offlinemode':
            return config.features.offlineMode;
          case 'analytics':
            return config.features.analytics;
          case 'localai':
            return config.features.localAI;
        }
      }
    } catch (e) {
      _logger.error('Error checking feature flag', e);
    }
    
    // Fallback to local .env
    final envKey = 'ENABLE_${featureName.toUpperCase()}';
    return dotenv.env[envKey]?.toLowerCase() == 'true';
  }
  
  /// Refresh remote configuration
  static Future<void> refreshRemoteConfig() async {
    try {
      await _remoteConfig?.refreshConfig();
      _logger.info('✅ Remote configuration refreshed');
    } catch (e) {
      _logger.error('❌ Failed to refresh remote config', e);
    }
  }
  
  /// Get crisis intervention contacts
  static Future<Map<String, String>> get crisisContacts async {
    try {
      final config = await _remoteConfig?.getConfig();
      if (config != null) {
        return {
          'hotline': config.crisis.hotline,
          'textLine': config.crisis.textLine,
          'emergency': config.crisis.emergency,
        };
      }
    } catch (e) {
      _logger.error('Error getting crisis contacts', e);
    }
    
    // Fallback to local .env
    return {
      'hotline': dotenv.env['CRISIS_HOTLINE'] ?? '988',
      'textLine': dotenv.env['CRISIS_TEXT'] ?? '741741',
      'emergency': dotenv.env['EMERGENCY_CONTACT'] ?? '911',
    };
  }
  
  /// Get sync configuration
  static Future<Map<String, int>> get syncConfig async {
    try {
      final config = await _remoteConfig?.getConfig();
      if (config != null) {
        return {
          'intervalHours': config.sync.intervalHours,
          'maxRetries': config.sync.maxRetries,
          'timeoutSeconds': config.sync.timeoutSeconds,
        };
      }
    } catch (e) {
      _logger.error('Error getting sync config', e);
    }
    
    // Fallback to local .env
    return {
      'intervalHours': int.tryParse(dotenv.env['SYNC_INTERVAL_HOURS'] ?? '6') ?? 6,
      'maxRetries': int.tryParse(dotenv.env['MAX_SYNC_RETRIES'] ?? '3') ?? 3,
      'timeoutSeconds': int.tryParse(dotenv.env['SYNC_TIMEOUT_SECONDS'] ?? '30') ?? 30,
    };
  }
}
