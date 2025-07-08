import 'package:injectable/injectable.dart';

import '../../../psychology/domain/usecases/psychology_testing_usecases.dart';
import '../../../growth/domain/usecases/mood_tracking_usecases.dart';
import '../../../little_brain/domain/repositories/little_brain_repository.dart';

@injectable
class ChatPersonalityService {
  final PsychologyTestingUseCases _psychologyTesting;
  final MoodTrackingUseCases _moodTracking;
  final LittleBrainRepository _littleBrainRepository;

  ChatPersonalityService(
    this._psychologyTesting,
    this._moodTracking,
    this._littleBrainRepository,
  );

  /// Build personality context for AI chat responses
  Future<String> buildPersonalityContext() async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('USER PERSONALITY CONTEXT:');

      // Get MBTI information
      final psychologyAnalytics = await _psychologyTesting.getPsychologyAnalytics();
      if (psychologyAnalytics.latestMBTI != null) {
        final mbti = psychologyAnalytics.latestMBTI!;
        buffer.writeln('- MBTI Type: ${mbti.personalityType}');
        buffer.writeln('- Description: ${mbti.description}');
        
        // Add communication preferences based on MBTI
        buffer.writeln('- Communication Style: ${_getMBTICommunicationStyle(mbti.personalityType)}');
      }

      // Get BDI mental health information
      if (psychologyAnalytics.latestBDI != null) {
        final bdi = psychologyAnalytics.latestBDI!;
        buffer.writeln('- Mental Health Level: ${bdi.level.indonesianDescription}');
        buffer.writeln('- Support Approach: ${_getBDISupportApproach(bdi.level.name)}');
      }

      // Get recent mood information
      final recentMoods = await _moodTracking.getRecentMoodEntries(limit: 3);
      if (recentMoods.isNotEmpty) {
        final avgMood = recentMoods.map((m) => m.moodLevel).reduce((a, b) => a + b) / recentMoods.length;
        buffer.writeln('- Recent Mood: ${avgMood.toStringAsFixed(1)}/10 (${_getMoodDescription(avgMood)})');
      }

      // Get conversation context from recent memories
      final recentMemories = await _littleBrainRepository.getAllMemories();
      final chatMemories = recentMemories
          .where((m) => m.source.startsWith('chat') && m.timestamp.isAfter(DateTime.now().subtract(const Duration(days: 2))))
          .take(5)
          .toList();

      if (chatMemories.isNotEmpty) {
        final interests = <String>{};
        for (final memory in chatMemories) {
          interests.addAll(memory.tags.where((tag) => !['chat', 'conversation', 'user_input', 'ai_insight'].contains(tag)));
        }
        if (interests.isNotEmpty) {
          buffer.writeln('- Recent Interests: ${interests.take(3).join(', ')}');
        }
      }

      buffer.writeln('\nPLEASE RESPOND IN A WAY THAT:');
      buffer.writeln('- Matches their personality type and communication preferences');
      buffer.writeln('- Is appropriate for their current mental health level');
      buffer.writeln('- Acknowledges their recent mood and emotional state');
      buffer.writeln('- Builds on their interests and previous conversations');
      buffer.writeln('- Provides supportive and helpful guidance');

      return buffer.toString();
    } catch (e) {
      return 'USER PERSONALITY CONTEXT: Unable to load personality data. Please provide general supportive responses.';
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

  String _getMBTICommunicationStyle(String mbtiType) {
    switch (mbtiType.substring(0, 1)) {
      case 'E':
        return 'Energetic, expressive, enjoys interactive discussions';
      case 'I':
        return 'Thoughtful, reflective, prefers deeper conversations';
      default:
        return 'Balanced communication approach';
    }
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

  String _getMoodDescription(double avgMood) {
    if (avgMood >= 8) return 'Very positive';
    if (avgMood >= 6) return 'Good';
    if (avgMood >= 4) return 'Neutral';
    if (avgMood >= 2) return 'Low';
    return 'Very low';
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
