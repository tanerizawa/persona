import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/app_constants.dart';
import '../utils/api_key_helper.dart';
import '../services/logging_service.dart';

class EnvironmentConfig {
  // API Configuration
  static String get openRouterApiKey {
    final key = AppConstants.openRouterApiKey;
    
    if (!ApiKeyHelper.isApiKeyValid(key)) {
      ApiKeyHelper.logApiKeyError();
      throw Exception(
        'OpenRouter API Key is not configured!\n'
        'Please ensure your .env file contains a valid OPENROUTER_API_KEY.\n'
        'Get your API key from: https://openrouter.ai/keys'
      );
    }
    
    return key;
  }
  
  static String get appDomain {
    return dotenv.env['APP_DOMAIN'] ?? 'https://persona-ai.app';
  }
  
  static bool get isDevelopment {
    return AppConstants.environment != 'production';
  }
  
  static bool get isApiKeyConfigured {
    return ApiKeyHelper.isApiKeyValid(AppConstants.openRouterApiKey);
  }
  
  // JWT Configuration
  static String get jwtSecret {
    return dotenv.env['JWT_SECRET'] ?? '';
  }
  
  static String get jwtRefreshSecret {
    return dotenv.env['JWT_REFRESH_SECRET'] ?? '';
  }
  
  // Database Configuration
  static String get databaseUrl {
    return dotenv.env['DATABASE_URL'] ?? '';
  }
  
  // Rate Limiting
  static int get rateLimitWindowMs {
    return int.tryParse(dotenv.env['RATE_LIMIT_WINDOW_MS'] ?? '900000') ?? 900000;
  }
  
  static int get rateLimitMaxRequests {
    return int.tryParse(dotenv.env['RATE_LIMIT_MAX_REQUESTS'] ?? '100') ?? 100;
  }
  
  static void validateConfiguration() {
    // Create a basic logger since we can't use dependency injection here
    final logger = LoggingService();
    
    // Validate API key on app startup
    try {
      if (isApiKeyConfigured) {
        logger.info('✅ OpenRouter API key configured successfully');
      } else {
        logger.warning('⚠️ OpenRouter API key needs configuration');
        ApiKeyHelper.logApiKeyError();
      }
      
      // Validate other critical configuration
      if (AppConstants.backendBaseUrl.isEmpty) {
        logger.warning('⚠️ Backend base URL is not configured');
      } else {
        logger.info('✅ Backend base URL: ${AppConstants.backendBaseUrl}');
      }
      
      logger.info('✅ Environment: ${AppConstants.environment}');
      logger.info('✅ Default AI Model: ${AppConstants.defaultAiModel}');
      
      // Log feature flags
      logger.info('ℹ️ Feature Flags:');
      logger.info('  - Push Notifications: ${AppConstants.enablePushNotifications}');
      logger.info('  - Biometric Auth: ${AppConstants.enableBiometricAuth}');
      logger.info('  - Crisis Intervention: ${AppConstants.enableCrisisIntervention}');
      logger.info('  - Background Sync: ${AppConstants.enableBackgroundSync}');
    } catch (e) {
      logger.error('❌ Environment configuration error', e);
    }
  }
}
