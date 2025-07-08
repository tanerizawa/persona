import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // API Constants
  static String get openRouterBaseUrl => dotenv.env['OPENROUTER_BASE_URL'] ?? 'https://openrouter.ai/api/v1';
  
  // SECURITY: API Key loaded from .env file
  static String get openRouterApiKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  
  // Backend API Configuration
  static String get backendBaseUrl => 
    dotenv.env['BACKEND_BASE_URL'] ?? 
    (isEmulator ? 'http://10.0.2.2:3000' : 'http://localhost:3000');
  
  // Default AI model to use
  static String get defaultAiModel => dotenv.env['DEFAULT_MODEL'] ?? 'deepseek/deepseek-r1-0528:free';
  
  // App Environment
  static String get environment => dotenv.env['NODE_ENV'] ?? 'development';
  
  // Production flags
  static bool get isProduction => environment == 'production';
  static bool get enableLogging => !isProduction;
  
  // Helper for emulator detection
  static const bool isEmulator = true; // TODO: Implement actual detection
  
  // App Constants
  static String get appName => dotenv.env['APP_NAME'] ?? 'Persona AI Assistant';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  
  // Storage Keys
  static String get userProfileKey => dotenv.env['USER_PROFILE_KEY'] ?? 'user_profile';
  static String get chatHistoryKey => dotenv.env['CHAT_HISTORY_KEY'] ?? 'chat_history';
  static String get moodDataKey => dotenv.env['MOOD_DATA_KEY'] ?? 'mood_data';
  static String get psychologyTestsKey => dotenv.env['PSYCHOLOGY_TESTS_KEY'] ?? 'psychology_tests';
  static String get personalityDataKey => dotenv.env['PERSONALITY_DATA_KEY'] ?? 'personality_data';
  static String get settingsKey => dotenv.env['SETTINGS_KEY'] ?? 'settings';
  
  // Little Brain Keys
  static String get memoriesKey => dotenv.env['MEMORIES_KEY'] ?? 'memories';
  static String get personalityModelKey => dotenv.env['PERSONALITY_MODEL_KEY'] ?? 'personality_model';
  static String get emotionalStateKey => dotenv.env['EMOTIONAL_STATE_KEY'] ?? 'emotional_state';
  
  // AI Model Constants
  static String get personalityAnalysisModel => 
    dotenv.env['PERSONALITY_ANALYSIS_MODEL'] ?? defaultAiModel;
  
  // Feature Flags
  static bool get enablePushNotifications => 
    dotenv.env['ENABLE_PUSH_NOTIFICATIONS']?.toLowerCase() == 'true';
  static bool get enableBiometricAuth => 
    dotenv.env['ENABLE_BIOMETRIC_AUTH']?.toLowerCase() == 'true';
  static bool get enableCrisisIntervention => 
    dotenv.env['ENABLE_CRISIS_INTERVENTION']?.toLowerCase() == 'true';
  static bool get enableBackgroundSync => 
    dotenv.env['ENABLE_BACKGROUND_SYNC']?.toLowerCase() == 'true';
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration pageTransitionDuration = Duration(milliseconds: 250);
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Growth Tab Constants
  static const int maxMoodLevels = 10;
  static const int lifeTreeMaxDepth = 5;
  
  // Psychology Test Constants
  static const int mbtiQuestionCount = 60;
  static const int bdiQuestionCount = 21;
  static const int crisisThreshold = 15; // BDI score threshold for crisis intervention
}

class AppStrings {
  // Tab Names
  static const String homeTab = 'Beranda';
  static const String chatTab = 'Chat';
  static const String growthTab = 'Growth';
  static const String psychologyTab = 'Psychology';
  static const String settingsTab = 'Settings';
  
  // Home Tab
  static const String musicRecommendations = 'Rekomendasi Musik';
  static const String articlesForYou = 'Artikel Untuk Anda';
  static const String dailyQuote = 'Kutipan Hari Ini';
  static const String journalEntry = 'Jurnal Hari Ini';
  
  // Chat Tab
  static const String typeMessage = 'Ketik pesan...';
  static const String aiThinking = 'AI sedang berpikir...';
  
  // Growth Tab
  static const String moodTracker = 'Pelacak Mood';
  static const String lifeTree = 'Pohon Kehidupan';
  static const String calendar = 'Kalender';
  
  // Psychology Tab
  static const String mbtiTest = 'Tes MBTI';
  static const String bdiTest = 'Tes BDI';
  static const String personalityProfile = 'Profil Kepribadian';
  
  // Settings Tab
  static const String profile = 'Profil';
  static const String privacy = 'Privasi';
  static const String security = 'Keamanan';
  static const String notifications = 'Notifikasi';
  
  // Error Messages
  static const String networkError = 'Terjadi kesalahan jaringan';
  static const String apiError = 'Terjadi kesalahan pada server';
  static const String unknownError = 'Terjadi kesalahan yang tidak diketahui';
  
  // Success Messages
  static const String dataSaved = 'Data berhasil disimpan';
  static const String profileUpdated = 'Profil berhasil diperbarui';
}
