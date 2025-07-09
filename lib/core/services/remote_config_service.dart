import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../constants/app_constants.dart';
import 'logging_service.dart';

/// Remote Configuration Service with Circuit Breaker Pattern
/// Fetches and caches app configuration from backend server
/// Allows dynamic configuration updates without app rebuild
@singleton
class RemoteConfigService {
  static const String _configCacheKey = 'remote_config_cache';
  static const String _configVersionKey = 'remote_config_version';
  static const String _lastFetchKey = 'remote_config_last_fetch';
  static const String _circuitBreakerKey = 'remote_config_circuit_breaker';
  
  final SharedPreferences _prefs;
  final LoggingService _logger;
  AppConfig? _cachedConfig;
  
  // Circuit Breaker Properties
  bool _circuitBreakerOpen = false;
  DateTime? _lastFailureTime;
  int _failureCount = 0;
  static const int _maxFailures = 3;
  static const Duration _circuitBreakerTimeout = Duration(minutes: 5);
  
  // Prevent multiple simultaneous requests
  Future<AppConfig>? _configFuture;

  RemoteConfigService(this._prefs, this._logger) {
    _loadCircuitBreakerState();
  }

  /// Get current app configuration with circuit breaker
  /// Returns cached config if available and not expired
  Future<AppConfig> getConfig({bool forceRefresh = false}) async {
    try {
      // Return ongoing request if exists
      if (_configFuture != null && !forceRefresh) {
        return await _configFuture!;
      }

      // Always try to return cached config first for performance
      if (!forceRefresh && _cachedConfig != null && !_isConfigExpired()) {
        // Start background fetch if circuit breaker allows it
        if (!_isCircuitBreakerOpen()) {
          unawaited(_fetchConfigInBackground());
        }
        return _cachedConfig!;
      }

      // Create new request only if necessary
      _configFuture = _fetchConfigWithCircuitBreaker();
      final config = await _configFuture!;
      _configFuture = null;
      
      return config;
      
    } catch (e) {
      _configFuture = null;
      _logger.error('Error getting remote config', e);
      // Return cached or default config on error
      return _cachedConfig ?? await _loadCachedConfig() ?? _getDefaultConfig();
    }
  }

  /// Background fetch without blocking UI
  Future<void> _fetchConfigInBackground() async {
    try {
      await _fetchConfigFromServer();
      _resetCircuitBreaker();
      _logger.info('🔄 Background config update completed');
    } catch (e) {
      _recordFailure();
      _logger.warning('⚠️ Background config update failed', e);
    }
  }

  /// Fetch configuration with circuit breaker pattern
  Future<AppConfig> _fetchConfigWithCircuitBreaker() async {
    // Check circuit breaker
    if (_isCircuitBreakerOpen()) {
      _logger.info('🔴 Circuit breaker open, using cached/default config');
      return _cachedConfig ?? await _loadCachedConfig() ?? _getDefaultConfig();
    }

    try {
      // Try to fetch from server
      await _fetchConfigFromServer();
      
      // Reset circuit breaker on success
      _resetCircuitBreaker();
      
      // Return cached config (just updated) or default
      return _cachedConfig ?? _getDefaultConfig();
      
    } catch (e) {
      // Record failure
      _recordFailure();
      
      _logger.error('❌ Failed to fetch remote config', e);
      
      // Return cached or default config
      _cachedConfig ??= await _loadCachedConfig();
      return _cachedConfig ?? _getDefaultConfig();
    }
  }

  /// Fetch configuration from backend server
  Future<void> _fetchConfigFromServer() async {
    final fullUrl = '${AppConstants.backendBaseUrl}/api/config/app-config';
    
    // Create a new Dio instance with shorter timeout for better performance
    final dio = Dio()
      ..options.connectTimeout = const Duration(seconds: 5)
      ..options.receiveTimeout = const Duration(seconds: 5)
      ..options.sendTimeout = const Duration(seconds: 5);
    
    final response = await dio.get(fullUrl);
    
    if (response.statusCode == 200 && response.data['success'] == true) {
      final configData = response.data['data'];
      _cachedConfig = AppConfig.fromJson(configData);
      
      // Cache the configuration
      await _cacheConfig(configData);
      
      _logger.info('✅ Remote configuration fetched successfully');
    } else {
      throw Exception('Invalid response from server: ${response.statusCode}');
    }
  }

  /// Load cached configuration from local storage
  Future<AppConfig?> _loadCachedConfig() async {
    try {
      final cachedJson = _prefs.getString(_configCacheKey);
      if (cachedJson != null) {
        final configData = jsonDecode(cachedJson);
        return AppConfig.fromJson(configData);
      }
    } catch (e) {
      _logger.error('Error loading cached config', e);
    }
    return null;
  }

  /// Cache configuration to local storage
  Future<void> _cacheConfig(Map<String, dynamic> configData) async {
    try {
      await _prefs.setString(_configCacheKey, jsonEncode(configData));
      await _prefs.setString(_configVersionKey, configData['cache']['version'] ?? '1.0');
      await _prefs.setInt(_lastFetchKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      _logger.error('Error caching config', e);
    }
  }

  /// Check if cached config is expired
  bool _isConfigExpired() {
    final lastFetch = _prefs.getInt(_lastFetchKey) ?? 0;
    final cacheAgeMs = DateTime.now().millisecondsSinceEpoch - lastFetch;
    const maxCacheAgeMs = 30 * 60 * 1000; // 30 minutes
    return cacheAgeMs > maxCacheAgeMs;
  }

  /// Circuit Breaker Logic
  bool _isCircuitBreakerOpen() {
    if (!_circuitBreakerOpen) return false;
    
    // Check if timeout has passed
    if (_lastFailureTime != null && 
        DateTime.now().difference(_lastFailureTime!) > _circuitBreakerTimeout) {
      _resetCircuitBreaker();
      return false;
    }
    
    return true;
  }

  void _recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= _maxFailures) {
      _circuitBreakerOpen = true;
      _logger.warning('🔴 Circuit breaker opened after $_failureCount failures');
    }
    
    _saveCircuitBreakerState();
  }

  void _resetCircuitBreaker() {
    _circuitBreakerOpen = false;
    _failureCount = 0;
    _lastFailureTime = null;
    _saveCircuitBreakerState();
    _logger.info('🟢 Circuit breaker reset');
  }

  void _loadCircuitBreakerState() {
    _circuitBreakerOpen = _prefs.getBool('${_circuitBreakerKey}_open') ?? false;
    _failureCount = _prefs.getInt('${_circuitBreakerKey}_failures') ?? 0;
    final lastFailureMs = _prefs.getInt('${_circuitBreakerKey}_last_failure');
    if (lastFailureMs != null) {
      _lastFailureTime = DateTime.fromMillisecondsSinceEpoch(lastFailureMs);
    }
  }

  void _saveCircuitBreakerState() {
    _prefs.setBool('${_circuitBreakerKey}_open', _circuitBreakerOpen);
    _prefs.setInt('${_circuitBreakerKey}_failures', _failureCount);
    if (_lastFailureTime != null) {
      _prefs.setInt('${_circuitBreakerKey}_last_failure', _lastFailureTime!.millisecondsSinceEpoch);
    }
  }

  /// Get default fallback configuration
  AppConfig _getDefaultConfig() {
    return AppConfig(
      app: AppInfo(
        name: 'Persona Assistant',
        version: '1.0.0',
        environment: 'development',
        domain: 'https://persona-ai.app',
        lastUpdated: DateTime.now().toIso8601String(),
      ),
      ai: AIConfig(
        baseUrl: 'https://openrouter.ai/api/v1',
        defaultModel: 'deepseek/deepseek-r1-0528:free',
        personalityModel: 'gpt-4-turbo-preview',
        moodModel: 'anthropic/claude-3-haiku:beta',
        confidenceThreshold: 0.7,
        enableLocalAI: true,
      ),
      backend: BackendConfig(
        baseUrl: 'http://10.0.2.2:3000',
        apiVersion: 'v1',
        timeout: 30000,
        retryAttempts: 3,
      ),
      features: FeatureFlags(
        pushNotifications: false,
        biometricAuth: true,
        crisisIntervention: true,
        backgroundSync: true,
        offlineMode: true,
        analytics: false,
        localAI: true,
      ),
      sync: SyncConfig(
        intervalHours: 6,
        maxRetries: 3,
        timeoutSeconds: 30,
      ),
      crisis: CrisisConfig(
        hotline: '988',
        textLine: '741741',
        emergency: '911',
      ),
      development: DevelopmentConfig(
        debugMode: true,
        mockApiResponses: false,
        skipOnboarding: false,
        logLevel: 'debug',
      ),
      security: SecurityConfig(
        forceHttps: false,
        enableSslPinning: false,
        rateLimitEnabled: true,
        maxRequestsPerWindow: 100,
        windowMs: 900000,
      ),
      ui: UIConfig(
        theme: ThemeConfig(
          primaryColor: '#6750A4',
          accentColor: '#625B71',
          darkMode: false,
        ),
        animations: AnimationConfig(
          enabled: true,
          duration: 300,
        ),
        locale: 'en',
      ),
      cache: CacheConfig(
        ttlMinutes: 30,
        version: '1.0',
      ),
    );
  }

  /// Force refresh configuration from server
  Future<AppConfig> refreshConfig() async {
    return await getConfig(forceRefresh: true);
  }

  /// Check if feature is enabled
  bool isFeatureEnabled(String featureName) {
    final config = _cachedConfig ?? _getDefaultConfig();
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
      default:
        return false;
    }
  }

  /// Get circuit breaker status for debugging
  Map<String, dynamic> getCircuitBreakerStatus() {
    return {
      'isOpen': _circuitBreakerOpen,
      'failureCount': _failureCount,
      'lastFailureTime': _lastFailureTime?.toIso8601String(),
    };
  }
}

/// App Configuration Data Classes
class AppConfig {
  final AppInfo app;
  final AIConfig ai;
  final BackendConfig backend;
  final FeatureFlags features;
  final SyncConfig sync;
  final CrisisConfig crisis;
  final DevelopmentConfig development;
  final SecurityConfig security;
  final UIConfig ui;
  final CacheConfig cache;

  AppConfig({
    required this.app,
    required this.ai,
    required this.backend,
    required this.features,
    required this.sync,
    required this.crisis,
    required this.development,
    required this.security,
    required this.ui,
    required this.cache,
  });

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      app: AppInfo.fromJson(json['app']),
      ai: AIConfig.fromJson(json['ai']),
      backend: BackendConfig.fromJson(json['backend']),
      features: FeatureFlags.fromJson(json['features']),
      sync: SyncConfig.fromJson(json['sync']),
      crisis: CrisisConfig.fromJson(json['crisis']),
      development: DevelopmentConfig.fromJson(json['development']),
      security: SecurityConfig.fromJson(json['security']),
      ui: UIConfig.fromJson(json['ui']),
      cache: CacheConfig.fromJson(json['cache']),
    );
  }
}

class AppInfo {
  final String name;
  final String version;
  final String environment;
  final String domain;
  final String lastUpdated;

  AppInfo({
    required this.name,
    required this.version,
    required this.environment,
    required this.domain,
    required this.lastUpdated,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      name: json['name'],
      version: json['version'],
      environment: json['environment'],
      domain: json['domain'],
      lastUpdated: json['lastUpdated'],
    );
  }
}

class AIConfig {
  final String baseUrl;
  final String defaultModel;
  final String personalityModel;
  final String moodModel;
  final double confidenceThreshold;
  final bool enableLocalAI;

  AIConfig({
    required this.baseUrl,
    required this.defaultModel,
    required this.personalityModel,
    required this.moodModel,
    required this.confidenceThreshold,
    required this.enableLocalAI,
  });

  factory AIConfig.fromJson(Map<String, dynamic> json) {
    return AIConfig(
      baseUrl: json['baseUrl'],
      defaultModel: json['defaultModel'],
      personalityModel: json['personalityModel'],
      moodModel: json['moodModel'],
      confidenceThreshold: json['confidenceThreshold'].toDouble(),
      enableLocalAI: json['enableLocalAI'],
    );
  }
}

class BackendConfig {
  final String baseUrl;
  final String apiVersion;
  final int timeout;
  final int retryAttempts;

  BackendConfig({
    required this.baseUrl,
    required this.apiVersion,
    required this.timeout,
    required this.retryAttempts,
  });

  factory BackendConfig.fromJson(Map<String, dynamic> json) {
    return BackendConfig(
      baseUrl: json['baseUrl'],
      apiVersion: json['apiVersion'],
      timeout: json['timeout'],
      retryAttempts: json['retryAttempts'],
    );
  }
}

class FeatureFlags {
  final bool pushNotifications;
  final bool biometricAuth;
  final bool crisisIntervention;
  final bool backgroundSync;
  final bool offlineMode;
  final bool analytics;
  final bool localAI;

  FeatureFlags({
    required this.pushNotifications,
    required this.biometricAuth,
    required this.crisisIntervention,
    required this.backgroundSync,
    required this.offlineMode,
    required this.analytics,
    required this.localAI,
  });

  factory FeatureFlags.fromJson(Map<String, dynamic> json) {
    return FeatureFlags(
      pushNotifications: json['pushNotifications'],
      biometricAuth: json['biometricAuth'],
      crisisIntervention: json['crisisIntervention'],
      backgroundSync: json['backgroundSync'],
      offlineMode: json['offlineMode'],
      analytics: json['analytics'],
      localAI: json['localAI'],
    );
  }
}

class SyncConfig {
  final int intervalHours;
  final int maxRetries;
  final int timeoutSeconds;

  SyncConfig({
    required this.intervalHours,
    required this.maxRetries,
    required this.timeoutSeconds,
  });

  factory SyncConfig.fromJson(Map<String, dynamic> json) {
    return SyncConfig(
      intervalHours: json['intervalHours'],
      maxRetries: json['maxRetries'],
      timeoutSeconds: json['timeoutSeconds'],
    );
  }
}

class CrisisConfig {
  final String hotline;
  final String textLine;
  final String emergency;

  CrisisConfig({
    required this.hotline,
    required this.textLine,
    required this.emergency,
  });

  factory CrisisConfig.fromJson(Map<String, dynamic> json) {
    return CrisisConfig(
      hotline: json['hotline'],
      textLine: json['textLine'],
      emergency: json['emergency'],
    );
  }
}

class DevelopmentConfig {
  final bool debugMode;
  final bool mockApiResponses;
  final bool skipOnboarding;
  final String logLevel;

  DevelopmentConfig({
    required this.debugMode,
    required this.mockApiResponses,
    required this.skipOnboarding,
    required this.logLevel,
  });

  factory DevelopmentConfig.fromJson(Map<String, dynamic> json) {
    return DevelopmentConfig(
      debugMode: json['debugMode'],
      mockApiResponses: json['mockApiResponses'],
      skipOnboarding: json['skipOnboarding'],
      logLevel: json['logLevel'],
    );
  }
}

class SecurityConfig {
  final bool forceHttps;
  final bool enableSslPinning;
  final bool rateLimitEnabled;
  final int maxRequestsPerWindow;
  final int windowMs;

  SecurityConfig({
    required this.forceHttps,
    required this.enableSslPinning,
    required this.rateLimitEnabled,
    required this.maxRequestsPerWindow,
    required this.windowMs,
  });

  factory SecurityConfig.fromJson(Map<String, dynamic> json) {
    return SecurityConfig(
      forceHttps: json['forceHttps'],
      enableSslPinning: json['enableSslPinning'],
      rateLimitEnabled: json['rateLimitEnabled'],
      maxRequestsPerWindow: json['maxRequestsPerWindow'],
      windowMs: json['windowMs'],
    );
  }
}

class UIConfig {
  final ThemeConfig theme;
  final AnimationConfig animations;
  final String locale;

  UIConfig({
    required this.theme,
    required this.animations,
    required this.locale,
  });

  factory UIConfig.fromJson(Map<String, dynamic> json) {
    return UIConfig(
      theme: ThemeConfig.fromJson(json['theme']),
      animations: AnimationConfig.fromJson(json['animations']),
      locale: json['locale'],
    );
  }
}

class ThemeConfig {
  final String primaryColor;
  final String accentColor;
  final bool darkMode;

  ThemeConfig({
    required this.primaryColor,
    required this.accentColor,
    required this.darkMode,
  });

  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      primaryColor: json['primaryColor'],
      accentColor: json['accentColor'],
      darkMode: json['darkMode'],
    );
  }
}

class AnimationConfig {
  final bool enabled;
  final int duration;

  AnimationConfig({
    required this.enabled,
    required this.duration,
  });

  factory AnimationConfig.fromJson(Map<String, dynamic> json) {
    return AnimationConfig(
      enabled: json['enabled'],
      duration: json['duration'],
    );
  }
}

class CacheConfig {
  final int ttlMinutes;
  final String version;

  CacheConfig({
    required this.ttlMinutes,
    required this.version,
  });

  factory CacheConfig.fromJson(Map<String, dynamic> json) {
    return CacheConfig(
      ttlMinutes: json['ttlMinutes'],
      version: json['version'],
    );
  }
}
