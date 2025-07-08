import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'shared/themes/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/config/environment_config.dart';
import 'core/auth/auth_wrapper.dart';
import 'core/services/push_notification_service.dart';
import 'features/little_brain/data/models/hive_models.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load();
  
  // Validate environment configuration
  EnvironmentConfig.validateConfiguration();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters for Little Brain
  Hive.registerAdapter(HiveMemoryAdapter());
  Hive.registerAdapter(HivePersonalityProfileAdapter());
  Hive.registerAdapter(HiveContextAdapter());
  Hive.registerAdapter(HiveSyncMetadataAdapter());
  
  // Initialize dependency injection
  await configureDependencies();
  
  // Initialize push notification service (only if enabled)
  if (AppConstants.enablePushNotifications) {
    try {
      if (getIt.isRegistered<PushNotificationService>()) {
        final pushNotificationService = getIt<PushNotificationService>();
        await pushNotificationService.initialize();
      }
    } catch (e) {
      print('Warning: Push notifications not available: $e');
    }
  } else {
    print('ℹ️ Push notifications disabled via configuration');
  }
  
  runApp(const PersonaAIApp());
}

class PersonaAIApp extends StatelessWidget {
  const PersonaAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}
