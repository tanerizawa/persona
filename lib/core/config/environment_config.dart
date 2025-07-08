import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../constants/app_constants.dart';
import '../utils/api_key_helper.dart';

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
    // Validate API key on app startup
    try {
      if (isApiKeyConfigured) {
        print('✅ OpenRouter API key configured successfully');
      } else {
        print('⚠️ OpenRouter API key needs configuration');
        ApiKeyHelper.logApiKeyError();
      }
      
      // Validate other critical configuration
      if (AppConstants.backendBaseUrl.isEmpty) {
        print('⚠️ Backend base URL is not configured');
      } else {
        print('✅ Backend base URL: ${AppConstants.backendBaseUrl}');
      }
      
      print('✅ Environment: ${AppConstants.environment}');
      print('✅ Default AI Model: ${AppConstants.defaultAiModel}');
      
      // Log feature flags
      print('ℹ️ Feature Flags:');
      print('  - Push Notifications: ${AppConstants.enablePushNotifications}');
      print('  - Biometric Auth: ${AppConstants.enableBiometricAuth}');
      print('  - Crisis Intervention: ${AppConstants.enableCrisisIntervention}');
      print('  - Background Sync: ${AppConstants.enableBackgroundSync}');
    } catch (e) {
      print('❌ Environment configuration error: $e');
    }
  }
}
