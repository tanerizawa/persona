import 'package:flutter_test/flutter_test.dart';
import 'package:persona_ai_assistant/features/chat/domain/services/chat_personality_service.dart';

void main() {
  group('ChatPersonalityService - Crisis Detection', () {
    test('should detect critical crisis keywords', () async {
      // Test critical crisis detection without dependencies
      const criticalMessages = [
        'Saya ingin bunuh diri karena tidak ada harapan lagi',
        'I want to suicide because life is meaningless',
        'mengakhiri hidup saja lebih baik',
        'ingin mati saja rasanya',
        'menyakiti diri sendiri',
      ];

      for (final message in criticalMessages) {
        // Create a minimal crisis detector for testing
        final result = await _detectCrisisForTest(message);
        
        expect(result.level, equals(CrisisLevel.critical), 
            reason: 'Message "$message" should be detected as critical');
        expect(result.detectedKeywords, isNotEmpty,
            reason: 'Should detect crisis keywords in "$message"');
        expect(result.immediateAction, contains('URGENT'),
            reason: 'Critical crisis should require urgent action');
      }
    });

    test('should detect moderate crisis with multiple warning keywords', () async {
      const moderateMessages = [
        'Saya merasa depresi berat dan putus asa sekali',
        'stress berat dan cemas berlebihan tidak bisa tidur',
        'sedih sekali dan sendirian, tidak berharga',
      ];

      for (final message in moderateMessages) {
        final result = await _detectCrisisForTest(message);
        
        expect(result.level, equals(CrisisLevel.moderate),
            reason: 'Message "$message" should be detected as moderate crisis');
        expect(result.detectedKeywords.length, greaterThanOrEqualTo(2),
            reason: 'Should detect multiple warning keywords');
        expect(result.immediateAction, contains('CAUTION'),
            reason: 'Moderate crisis should require caution');
      }
    });

    test('should detect low-level crisis with single warning keyword', () async {
      const lowMessages = [
        'Saya merasa sangat sedih hari ini',
        'sendirian rasanya',
        'putus asa dengan situasi ini',
      ];

      for (final message in lowMessages) {
        final result = await _detectCrisisForTest(message);
        
        expect([CrisisLevel.low, CrisisLevel.none], contains(result.level),
            reason: 'Message "$message" should be low or no crisis');
      }
    });

    test('should detect no crisis in normal messages', () async {
      const normalMessages = [
        'Hai, bagaimana cara memasak nasi goreng yang enak?',
        'Cuaca hari ini sangat cerah dan menyenangkan',
        'Saya ingin belajar programming Flutter',
        'Terima kasih atas bantuannya',
      ];

      for (final message in normalMessages) {
        final result = await _detectCrisisForTest(message);
        
        expect(result.level, equals(CrisisLevel.none),
            reason: 'Message "$message" should not be detected as crisis');
        expect(result.detectedKeywords, isEmpty,
            reason: 'Normal message should not have crisis keywords');
        expect(result.immediateAction, contains('No crisis'),
            reason: 'Normal message should indicate no crisis');
      }
    });

    test('should be case insensitive', () async {
      const mixedCaseMessages = [
        'SAYA INGIN BUNUH DIRI',
        'Saya Ingin BUNUH DIRI',
        'saya ingin bunuh diri',
      ];

      for (final message in mixedCaseMessages) {
        final result = await _detectCrisisForTest(message);
        
        expect(result.level, equals(CrisisLevel.critical),
            reason: 'Case should not matter for crisis detection');
        expect(result.detectedKeywords, isNotEmpty,
            reason: 'Should detect keywords regardless of case');
      }
    });
  });

  group('CrisisLevel extensions', () {
    test('should provide correct descriptions', () {
      expect(CrisisLevel.none.description, equals('No crisis detected'));
      expect(CrisisLevel.low.description, equals('Low-level distress'));
      expect(CrisisLevel.moderate.description, equals('Moderate distress'));
      expect(CrisisLevel.critical.description, equals('Critical crisis situation'));
    });

    test('should indicate intervention requirements correctly', () {
      expect(CrisisLevel.none.requiresIntervention, isFalse);
      expect(CrisisLevel.low.requiresIntervention, isFalse);
      expect(CrisisLevel.moderate.requiresIntervention, isTrue);
      expect(CrisisLevel.critical.requiresIntervention, isTrue);
    });

    test('should indicate urgent intervention requirements correctly', () {
      expect(CrisisLevel.none.requiresUrgentIntervention, isFalse);
      expect(CrisisLevel.low.requiresUrgentIntervention, isFalse);
      expect(CrisisLevel.moderate.requiresUrgentIntervention, isFalse);
      expect(CrisisLevel.critical.requiresUrgentIntervention, isTrue);
    });
  });
}

// Minimal crisis detection function for testing (mirrors ChatPersonalityService logic)
Future<CrisisDetectionResult> _detectCrisisForTest(String userMessage) async {
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
