// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';

import 'shared/themes/app_theme.dart';
import 'core/constants/app_constants.dart' as local_constants;
import 'core/constants/app_constants_remote.dart' as remote_constants;
import 'core/config/environment_config.dart';
import 'core/auth/auth_wrapper.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/logging_service.dart';
import 'core/services/performance_monitor.dart';
import 'core/services/database_optimization_service.dart';
import 'core/services/session_manager_service.dart';
import 'core/services/production_logging_service.dart';
import 'core/services/advanced_cache_service.dart';
import 'core/services/user_session_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/offline_mode_service.dart';
import 'core/utils/memory_manager.dart';
import 'features/little_brain/data/models/hive_models.dart';
import 'injection_container.dart';

void main() async {
  // Ensure app can start in any condition
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize connectivity monitoring first (non-blocking)
  final connectivityService = ConnectivityService();
  final offlineModeService = OfflineModeService(connectivityService);
  
  try {
    // Ensure app can start regardless of connectivity or environment issues
    await offlineModeService.ensureAppCanStart();
    
    // Load environment variables (graceful fallback if .env missing)
    try {
      await dotenv.load();
    } catch (e) {
      // App can still start without .env file
      print('⚠️ Environment file not found, using defaults: $e');
    }
    
    // Validate environment configuration (non-blocking)
    try {
      EnvironmentConfig.validateConfiguration();
    } catch (e) {
      print('⚠️ Environment validation failed, continuing: $e');
    }
    
    // Initialize dependency injection (required for app structure)
    await configureDependencies();
    
    // Initialize connectivity monitoring
    await connectivityService.initialize();
    await offlineModeService.initialize();
    
    // Initialize user session service for user switching detection
    final userSessionService = getIt<UserSessionService>();
    await userSessionService.initialize();
    
    // Initialize Hive for local storage (lightweight)
    await Hive.initFlutter();
    
    // Register Hive adapters for Little Brain (lightweight)
    Hive.registerAdapter(HiveMemoryAdapter());
    Hive.registerAdapter(HivePersonalityProfileAdapter());
    Hive.registerAdapter(HiveContextAdapter());
    Hive.registerAdapter(HiveSyncMetadataAdapter());
    
    // Start the app immediately - guaranteed to work
    runApp(const PersonaAIApp());
    
    // Initialize heavy operations after app starts (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeBackgroundServices();
    });
    
  } catch (e) {
    // Even if initialization fails, try to start the app
    print('❌ Main initialization error: $e');
    print('🔄 Starting app with minimal configuration...');
    
    // Fallback app start
    runApp(const PersonaAIApp());
  }
}

/// Initialize background services after app startup
Future<void> _initializeBackgroundServices() async {
  final logger = LoggingService();
  
  try {
    // Initialize performance monitoring
    PerformanceMonitor().startPerformanceLogging();
    
    // Initialize memory management
    MemoryManager.instance.startPeriodicCleanup();
    
    // Initialize production logging
    await ProductionLoggingService().initialize();
    
    // Initialize database optimization
    await DatabaseOptimizationService().initialize();
    
    // Initialize session management
    await SessionManagerService().initialize();
    
    // Initialize advanced caching
    await AdvancedCacheService().initialize();
    
    // Initialize Remote Configuration in background (non-blocking)
    unawaited(_initializeRemoteConfigAsync());
    
    // Initialize push notification service (check feature flag dynamically)
    unawaited(_initializePushNotificationsAsync());
    
    logger.info('✅ Background services initialized successfully');
    
  } catch (e) {
    logger.warning('⚠️ Some background services failed to initialize: $e');
    // App continues to work even if background services fail
  }
}

/// Initialize remote configuration asynchronously to avoid blocking main thread
Future<void> _initializeRemoteConfigAsync() async {
  final logger = LoggingService();
  try {
    await remote_constants.AppConstants.initializeRemoteConfig();
    logger.info('✅ Remote configuration loaded successfully');
  } catch (e) {
    logger.warning('⚠️ Remote config failed, using local .env: $e');
  }
}

/// Initialize push notifications asynchronously
Future<void> _initializePushNotificationsAsync() async {
  final logger = LoggingService();
  try {
    final enablePushNotifications = await remote_constants.AppConstants.enablePushNotifications;
    if (enablePushNotifications) {
      if (getIt.isRegistered<PushNotificationService>()) {
        final pushNotificationService = getIt<PushNotificationService>();
        await pushNotificationService.initialize();
      }
    } else {
      logger.info('ℹ️ Push notifications disabled via remote configuration');
    }
  } catch (e) {
    logger.warning('⚠️ Push notifications initialization failed: $e');
  }
}

class PersonaAIApp extends StatelessWidget {
  const PersonaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getAppName(),
      builder: (context, snapshot) {
        final appName = snapshot.data ?? 'Persona Assistant';
        
        return MaterialApp(
          title: appName,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: const AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
  
  Future<String> _getAppName() async {
    try {
      return remote_constants.AppConstants.appName;
    } catch (e) {
      return local_constants.AppConstants.appName;
    }
  }
}
