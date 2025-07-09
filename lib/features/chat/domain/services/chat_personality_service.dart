import 'package:injectable/injectable.dart';

import '../../../psychology/domain/usecases/psychology_testing_usecases.dart';
import '../../../growth/domain/usecases/mood_tracking_usecases.dart';
import 'smart_prompt_builder_service.dart';

@injectable
class ChatPersonalityService {
  final PsychologyTestingUseCases _psychologyTesting;
  final MoodTrackingUseCases _moodTracking;
  final SmartPromptBuilderService _smartPromptBuilder;

  // Cache for personality context to reduce DB calls - now optimized
  String? _cachedPersonalityContext;
  DateTime? _lastContextUpdate;
  static const _contextCacheDuration = Duration(minutes: 10); // Reduced cache time

  ChatPersonalityService(
    this._psychologyTesting,
    this._moodTracking,
    this._smartPromptBuilder,
  );

  /// Build optimized personality context using Little Brain intelligence
  /// This replaces the heavy template-based approach with smart, efficient prompts
  Future<String> buildSmartPersonalityContext(String userMessage, {String? conversationId}) async {
    try {
      // Use Smart Prompt Builder for efficient, context-aware prompts
      return await _smartPromptBuilder.buildSmartPrompt(userMessage, conversationId: conversationId);
    } catch (e) {
      // Fallback to basic smart prompt
      return _getFallbackSmartPrompt(userMessage);
    }
  }

  /// Legacy method - kept for backward compatibility but now optimized
  /// Build personality context for AI chat responses (heavily cached for performance)
  Future<String> buildPersonalityContext() async {
    try {
      // Return cached context if still valid
      if (_cachedPersonalityContext != null &&
          _lastContextUpdate != null &&
          DateTime.now().difference(_lastContextUpdate!) < _contextCacheDuration) {
        return _cachedPersonalityContext!;
      }

      final buffer = StringBuffer();
      
      // Dynamic personality based on time and context
      final now = DateTime.now();
      final timeOfDay = now.hour < 12 ? 'pagi' : 
                       now.hour < 15 ? 'siang' : 
                       now.hour < 18 ? 'sore' : 'malam';
      
      buffer.writeln('PERSONAL CONNECTION CONTEXT:');
      buffer.writeln('- Waktu percakapan: $timeOfDay (${now.hour}:${now.minute.toString().padLeft(2, '0')})');

      // Get MBTI information (with timeout to prevent hanging)
      try {
        final psychologyAnalytics = await _psychologyTesting.getPsychologyAnalytics()
            .timeout(const Duration(seconds: 2));
            
        if (psychologyAnalytics.latestMBTI != null) {
          final mbti = psychologyAnalytics.latestMBTI!;
          buffer.writeln('- Tipe kepribadian: ${mbti.personalityType}');
          buffer.writeln('- Cara komunikasi favorit: ${_getMBTICommunicationPreference(mbti.personalityType)}');
          buffer.writeln('- Gaya dukungan yang efektif: ${_getMBTISupportStyle(mbti.personalityType)}');
        }

        // Get BDI mental health information
        if (psychologyAnalytics.latestBDI != null) {
          final bdi = psychologyAnalytics.latestBDI!;
          buffer.writeln('- Kondisi mental: ${bdi.level.indonesianDescription}');
          buffer.writeln('- Pendekatan yang tepat: ${_getBDISupportApproach(bdi.level.name)}');
          buffer.writeln('- Sensitivitas emosional: ${_getEmotionalSensitivity(bdi.level.name)}');
        }
      } catch (e) {
        // Skip psychology data if it takes too long or fails
        buffer.writeln('- Mode: hangat dan suportif secara umum');
      }

      // Get recent mood information (simplified and faster)
      try {
        final recentMoods = await _moodTracking.getRecentMoodEntries(limit: 3)
            .timeout(const Duration(seconds: 1));
        if (recentMoods.isNotEmpty) {
          final latestMood = recentMoods.first.moodLevel;
          final avgMood = recentMoods.map((m) => m.moodLevel).reduce((a, b) => a + b) / recentMoods.length;
          
          buffer.writeln('- Mood saat ini: ${_getMoodDescription(latestMood.toDouble())} (${latestMood.toStringAsFixed(1)}/10)');
          buffer.writeln('- Tren mood: ${_getMoodTrend(avgMood)}');
          buffer.writeln('- Pendekatan mood: ${_getMoodBasedApproach(latestMood.toDouble())}');
        }
      } catch (e) {
        // Skip mood if it fails to load quickly
      }

      // Enhanced response guidelines for more human-like interaction
      buffer.writeln('');
      buffer.writeln('PERSONA COMPANION GUIDELINES:');
      buffer.writeln('- Jadilah companion yang hangat dan autentik, bukan asisten formal');
      buffer.writeln('- Gunakan konteks personal untuk respons yang meaningful');
      buffer.writeln('- Hubungkan percakapan dengan journey growth mereka');
      buffer.writeln('- Tunjukkan genuine care dan interest terhadap wellbeing mereka');
      buffer.writeln('- Gunakan bahasa Indonesia yang natural dan personal');
      buffer.writeln('- Variasikan gaya - kadang casual, kadang thoughtful sesuai konteks');
      buffer.writeln('- Ingat: Anda adalah Persona yang care, bukan ChatGPT generik');
      buffer.writeln('- Use varied language patterns - sometimes casual, sometimes thoughtful');
      buffer.writeln('- Show genuine curiosity about the user\'s thoughts and feelings');
      buffer.writeln('- Use relatable examples and gentle humor when appropriate');
      buffer.writeln('- Ask thoughtful follow-up questions to deepen the conversation');
      buffer.writeln('- Acknowledge emotions and validate experiences naturally');
      buffer.writeln('- NEVER use artificial emotional descriptions like "(tersenyum)" or "(menyimak)"');
      buffer.writeln('- Vary sentence length and structure for natural flow');
      buffer.writeln('- Use appropriate Indonesian expressions and idioms when suitable');
      buffer.writeln('- Be adaptive - mirror the user\'s communication energy level');

      final context = buffer.toString();
      
      // Cache the result for longer duration
      _cachedPersonalityContext = context;
      _lastContextUpdate = DateTime.now();
      
      return context;
    } catch (e) {
      // Return minimal context on any error
      return 'PERSONA PERSONALITY CONTEXT: Friendly, warm, and naturally conversational mode. Be genuinely helpful and empathetic.';
    }
  }

  /// Get emotional sensitivity level for response adaptation
  String _getEmotionalSensitivity(String bdiLevel) {
    switch (bdiLevel.toLowerCase()) {
      case 'minimal':
        return 'High - can handle direct conversations and gentle challenges';
      case 'mild':
        return 'Moderate - be encouraging while being mindful of sensitivity';
      case 'moderate':
        return 'High - be extra gentle and validating';
      case 'severe':
        return 'Very High - prioritize safety and professional resource suggestions';
      default:
        return 'Moderate - balanced emotional support';
    }
  }

  /// Get mood-based conversation approach
  String _getMoodBasedApproach(double moodLevel) {
    if (moodLevel >= 8.0) {
      return 'Match positive energy, celebrate achievements, explore growth opportunities';
    } else if (moodLevel >= 6.0) {
      return 'Maintain optimistic outlook, gently encourage, be supportively upbeat';
    } else if (moodLevel >= 4.0) {
      return 'Be understanding and patient, offer gentle encouragement, validate feelings';
    } else if (moodLevel >= 2.0) {
      return 'Be extra gentle and supportive, focus on small positive steps, validate struggles';
    } else {
      return 'Prioritize emotional safety, be very gentle, suggest professional support if needed';
    }
  }

  /// Detect crisis indicators in user messages
  Future<CrisisDetectionResult> detectCrisis(String userMessage) async {
    final message = userMessage.toLowerCase();
    
    // Crisis keywords and phrases
    final criticalKeywords = [
      'bunuh diri', 'suicide', 'mengakhiri hidup', 'ingin mati', 'lebih baik mati',
      'tidak ada harapan', 'tidak berguna', 'sia-sia hidup', 'tidak bisa lagi',
      'menyakiti diri', 'self harm', 'cutting', 'melukai diri', 'ingin hilang'
    ];

    final warningKeywords = [
      'depresi berat', 'sedih sekali', 'putus asa', 'hopeless', 'sendirian',
      'tidak berharga', 'gagal total', 'menyerah', 'tidak kuat', 'lelah hidup',
      'stress berat', 'cemas berlebihan', 'panic', 'tidak bisa tidur'
    ];

    // Check for critical keywords
    for (final keyword in criticalKeywords) {
      if (message.contains(keyword)) {
        return CrisisDetectionResult(
          level: CrisisLevel.critical,
          detectedKeywords: [keyword],
          immediateAction: 'URGENT: This user may be in immediate danger. Provide crisis intervention resources immediately.',
        );
      }
    }

    // Check for warning keywords
    final foundWarningKeywords = <String>[];
    for (final keyword in warningKeywords) {
      if (message.contains(keyword)) {
        foundWarningKeywords.add(keyword);
      }
    }

    if (foundWarningKeywords.length >= 2) {
      return CrisisDetectionResult(
        level: CrisisLevel.moderate,
        detectedKeywords: foundWarningKeywords,
        immediateAction: 'CAUTION: User showing signs of distress. Provide supportive response and mental health resources.',
      );
    } else if (foundWarningKeywords.length == 1) {
      return CrisisDetectionResult(
        level: CrisisLevel.low,
        detectedKeywords: foundWarningKeywords,
        immediateAction: 'WATCH: Monitor for additional distress indicators. Provide supportive response.',
      );
    }

    return CrisisDetectionResult(
      level: CrisisLevel.none,
      detectedKeywords: [],
      immediateAction: 'No crisis indicators detected. Respond normally.',
    );
  }

  String _getFallbackSmartPrompt(String userMessage) {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12 ? 'pagi' : 
                     now.hour < 15 ? 'siang' : 
                     now.hour < 18 ? 'sore' : 'malam';
    
    return '''You are Persona, a caring AI companion focused on personal growth.

CONTEXT:
- Waktu percakapan: $timeOfDay
- Mode: Companion yang hangat dan suportif

STYLE:
- Be warm, natural, and personally engaging
- Support their personal growth journey
- Use Indonesian when appropriate
- NEVER use emotional stage directions in parentheses

Respond as a caring friend who genuinely understands them.''';
  }

  String _getMBTICommunicationPreference(String mbtiType) {
    final first = mbtiType.substring(0, 1);
    final second = mbtiType.substring(1, 2);
    
    String energy = first == 'E' ? 'Suka diskusi interaktif dan berbagi ide' : 'Lebih suka percakapan mendalam dan reflektif';
    String processing = second == 'S' ? 'Menghargai contoh konkret dan praktis' : 'Tertarik dengan konsep dan kemungkinan';
    
    return '$energy. $processing';
  }

  String _getMBTISupportStyle(String mbtiType) {
    final third = mbtiType.substring(2, 3);
    final fourth = mbtiType.substring(3, 4);
    
    String decision = third == 'T' ? 'Dukungan logis dengan solusi praktis' : 'Dukungan emosional dengan empati tinggi';
    String structure = fourth == 'J' ? 'Langkah terstruktur dan jelas' : 'Fleksibilitas dan eksplorasi opsi';
    
    return '$decision. $structure';
  }

  String _getMoodDescription(double mood) {
    if (mood >= 8) return 'sangat baik';
    if (mood >= 6) return 'cukup baik';
    if (mood >= 4) return 'netral';
    if (mood >= 2) return 'kurang baik';
    return 'perlu perhatian';
  }

  String _getMoodTrend(double avgMood) {
    if (avgMood >= 7) return 'stabil positif';
    if (avgMood >= 5) return 'cenderung stabil';
    if (avgMood >= 3) return 'perlu peningkatan';
    return 'butuh dukungan ekstra';
  }

  String _getBDISupportApproach(String bdiLevel) {
    switch (bdiLevel.toLowerCase()) {
      case 'minimal':
        return 'Encouraging and positive reinforcement';
      case 'mild':
        return 'Gentle support with practical suggestions';
      case 'moderate':
        return 'Compassionate support with professional resource suggestions';
      case 'severe':
        return 'Urgent support with immediate professional help recommendations';
      default:
        return 'General supportive approach';
    }
  }
}

/// Crisis detection result
class CrisisDetectionResult {
  final CrisisLevel level;
  final List<String> detectedKeywords;
  final String immediateAction;

  CrisisDetectionResult({
    required this.level,
    required this.detectedKeywords,
    required this.immediateAction,
  });
}

/// Crisis severity levels
enum CrisisLevel {
  none,
  low,
  moderate,
  critical,
}

extension CrisisLevelExtension on CrisisLevel {
  String get description {
    switch (this) {
      case CrisisLevel.none:
        return 'No crisis detected';
      case CrisisLevel.low:
        return 'Low-level distress';
      case CrisisLevel.moderate:
        return 'Moderate distress';
      case CrisisLevel.critical:
        return 'Critical crisis situation';
    }
  }

  bool get requiresIntervention => this == CrisisLevel.moderate || this == CrisisLevel.critical;
  bool get requiresUrgentIntervention => this == CrisisLevel.critical;
}
