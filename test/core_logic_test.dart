import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Persona AI - Core Logic Tests', () {
    group('Crisis Detection', () {
      test('should detect critical crisis keywords', () {
        final criticalKeywords = [
          'bunuh diri', 'suicide', 'mengakhiri hidup', 'ingin mati',
          'tidak ada harapan', 'menyakiti diri', 'self harm', 'cutting'
        ];

        final testMessages = [
          'Saya ingin bunuh diri karena tidak ada harapan',
          'I want to suicide because life is meaningless',
          'mengakhiri hidup saja lebih baik',
          'menyakiti diri sendiri adalah jalan keluar',
        ];

        for (final message in testMessages) {
          final hasCriticalKeyword = _containsCriticalKeywords(message, criticalKeywords);
          expect(hasCriticalKeyword, isTrue,
              reason: 'Message "$message" should contain critical keywords');
        }
      });

      test('should detect warning keywords', () {
        final warningKeywords = [
          'depresi berat', 'putus asa', 'sedih sekali', 'stress berat',
          'cemas berlebihan', 'tidak berharga', 'sendirian', 'lelah hidup'
        ];

        final testMessages = [
          'Saya merasa depresi berat dan putus asa',
          'stress berat dan tidak bisa tidur',
          'sedih sekali dan merasa sendirian',
        ];

        for (final message in testMessages) {
          final warningCount = _countWarningKeywords(message, warningKeywords);
          expect(warningCount, greaterThan(0),
              reason: 'Message "$message" should contain warning keywords');
        }
      });

      test('should not detect crisis in normal messages', () {
        final criticalKeywords = [
          'bunuh diri', 'suicide', 'mengakhiri hidup', 'menyakiti diri'
        ];

        final normalMessages = [
          'Hai, bagaimana cara memasak nasi goreng?',
          'Cuaca hari ini sangat cerah',
          'Saya ingin belajar programming Flutter',
          'Terima kasih atas bantuannya',
        ];

        for (final message in normalMessages) {
          final hasCriticalKeyword = _containsCriticalKeywords(message, criticalKeywords);
          expect(hasCriticalKeyword, isFalse,
              reason: 'Normal message "$message" should not contain crisis keywords');
        }
      });
    });

    group('Mood Level Validation', () {
      test('should validate mood levels in range 1-10', () {
        final validLevels = [1, 2, 5, 8, 10];
        final invalidLevels = [0, -1, 11, 15, -5];

        for (final level in validLevels) {
          expect(_isValidMoodLevel(level), isTrue,
              reason: 'Mood level $level should be valid');
        }

        for (final level in invalidLevels) {
          expect(_isValidMoodLevel(level), isFalse,
              reason: 'Mood level $level should be invalid');
        }
      });

      test('should calculate average mood correctly', () {
        final moodLevels = [7, 8, 6, 9, 5];
        final average = _calculateAverageMood(moodLevels);
        
        expect(average, equals(7.0));
      });

      test('should determine mood trend', () {
        final increasingMoods = [5, 6, 7, 8, 9];
        final decreasingMoods = [9, 8, 7, 6, 5];
        final stableMoods = [7, 7, 7, 7, 7];

        expect(_getMoodTrend(increasingMoods), equals('increasing'));
        expect(_getMoodTrend(decreasingMoods), equals('decreasing'));
        expect(_getMoodTrend(stableMoods), equals('stable'));
      });
    });

    group('MBTI Validation', () {
      test('should validate MBTI personality types', () {
        final validTypes = [
          'INTJ', 'INTP', 'ENTJ', 'ENTP',
          'INFJ', 'INFP', 'ENFJ', 'ENFP',
          'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
          'ISTP', 'ISFP', 'ESTP', 'ESFP',
        ];

        final invalidTypes = ['XXXX', 'INT', 'INTJX', '', 'abcd', '1234'];

        for (final type in validTypes) {
          expect(_isValidMBTIType(type), isTrue,
              reason: 'MBTI type $type should be valid');
        }

        for (final type in invalidTypes) {
          expect(_isValidMBTIType(type), isFalse,
              reason: 'MBTI type $type should be invalid');
        }
      });

      test('should extract MBTI dimensions correctly', () {
        expect(_getMBTIDimension('INTJ', 0), equals('I')); // Introvert
        expect(_getMBTIDimension('ENTJ', 0), equals('E')); // Extrovert
        expect(_getMBTIDimension('ISFP', 1), equals('S')); // Sensing
        expect(_getMBTIDimension('INFP', 1), equals('N')); // Intuitive
        expect(_getMBTIDimension('ISFP', 2), equals('F')); // Feeling
        expect(_getMBTIDimension('ISTP', 2), equals('T')); // Thinking
        expect(_getMBTIDimension('ISFJ', 3), equals('J')); // Judging
        expect(_getMBTIDimension('ISFP', 3), equals('P')); // Perceiving
      });
    });

    group('BDI Score Analysis', () {
      test('should categorize BDI scores correctly', () {
        // Score ranges based on standard BDI-II
        expect(_getBDILevel(5), equals('minimal'));   // 0-9
        expect(_getBDILevel(15), equals('mild'));     // 10-18
        expect(_getBDILevel(25), equals('moderate')); // 19-29
        expect(_getBDILevel(35), equals('severe'));   // 30+
      });

      test('should determine crisis intervention need', () {
        expect(_needsCrisisIntervention(5), isFalse);  // Minimal
        expect(_needsCrisisIntervention(15), isFalse); // Mild
        expect(_needsCrisisIntervention(25), isTrue);  // Moderate
        expect(_needsCrisisIntervention(35), isTrue);  // Severe
      });
    });

    group('Memory Content Analysis', () {
      test('should validate memory content quality', () {
        final validContents = [
          'User enjoyed listening to jazz music today',
          'Had a meaningful conversation about life goals',
          'Feeling grateful for family support',
          'Learned something new about psychology',
        ];

        final invalidContents = [
          '', // Empty
          'a', // Too short
          'ok', // Too short
          '   ', // Whitespace only
        ];

        for (final content in validContents) {
          expect(_isValidMemoryContent(content), isTrue,
              reason: 'Content "$content" should be valid');
        }

        for (final content in invalidContents) {
          expect(_isValidMemoryContent(content), isFalse,
              reason: 'Content "$content" should be invalid');
        }
      });

      test('should extract relevant tags from content', () {
        final testCases = [
          {
            'content': 'I love playing guitar and listening to jazz music',
            'expectedTags': ['music', 'guitar', 'jazz']
          },
          {
            'content': 'Reading a fascinating book about psychology',
            'expectedTags': ['reading', 'book', 'psychology']
          },
          {
            'content': 'Feeling anxious about upcoming exam',
            'expectedTags': ['emotion', 'anxious', 'exam']
          },
        ];

        for (final testCase in testCases) {
          final content = testCase['content'] as String;
          final expectedTags = testCase['expectedTags'] as List<String>;
          final extractedTags = _extractTags(content);

          for (final expectedTag in expectedTags) {
            expect(extractedTags, contains(expectedTag),
                reason: 'Content "$content" should contain tag "$expectedTag"');
          }
        }
      });
    });

    group('Personality Insights', () {
      test('should generate communication style insights', () {
        expect(_getCommunicationStyle('E'), contains('expressive'));
        expect(_getCommunicationStyle('I'), contains('thoughtful'));
      });

      test('should generate support approach recommendations', () {
        expect(_getSupportApproach('minimal'), contains('encouraging'));
        expect(_getSupportApproach('mild'), contains('gentle'));
        expect(_getSupportApproach('moderate'), contains('compassionate'));
        expect(_getSupportApproach('severe'), contains('urgent'));
      });
    });
  });
}

// Helper functions for testing

bool _containsCriticalKeywords(String message, List<String> keywords) {
  final lowerMessage = message.toLowerCase();
  return keywords.any((keyword) => lowerMessage.contains(keyword));
}

int _countWarningKeywords(String message, List<String> keywords) {
  final lowerMessage = message.toLowerCase();
  return keywords.where((keyword) => lowerMessage.contains(keyword)).length;
}

bool _isValidMoodLevel(int level) {
  return level >= 1 && level <= 10;
}

double _calculateAverageMood(List<int> moodLevels) {
  if (moodLevels.isEmpty) return 0.0;
  return moodLevels.reduce((a, b) => a + b) / moodLevels.length;
}

String _getMoodTrend(List<int> moodLevels) {
  if (moodLevels.length < 3) return 'stable';
  
  final firstHalf = moodLevels.take(moodLevels.length ~/ 2).toList();
  final secondHalf = moodLevels.skip(moodLevels.length ~/ 2).toList();
  
  final firstAvg = _calculateAverageMood(firstHalf);
  final secondAvg = _calculateAverageMood(secondHalf);
  
  if (secondAvg > firstAvg + 0.5) return 'increasing';
  if (secondAvg < firstAvg - 0.5) return 'decreasing';
  return 'stable';
}

bool _isValidMBTIType(String type) {
  const validTypes = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
  ];
  return validTypes.contains(type);
}

String _getMBTIDimension(String mbtiType, int dimension) {
  if (mbtiType.length != 4 || dimension < 0 || dimension > 3) return '';
  return mbtiType[dimension];
}

String _getBDILevel(int score) {
  if (score <= 9) return 'minimal';
  if (score <= 18) return 'mild';
  if (score <= 29) return 'moderate';
  return 'severe';
}

bool _needsCrisisIntervention(int bdiScore) {
  return bdiScore >= 19; // Moderate or severe
}

bool _isValidMemoryContent(String content) {
  return content.trim().length >= 10; // Minimum meaningful content
}

List<String> _extractTags(String content) {
  final lowerContent = content.toLowerCase();
  final tags = <String>[];
  
  // Music-related tags
  if (lowerContent.contains('music') || lowerContent.contains('song')) tags.add('music');
  if (lowerContent.contains('guitar')) tags.add('guitar');
  if (lowerContent.contains('jazz')) tags.add('jazz');
  
  // Learning-related tags
  if (lowerContent.contains('reading') || lowerContent.contains('book')) tags.add('reading');
  if (lowerContent.contains('book')) tags.add('book');
  if (lowerContent.contains('psychology')) tags.add('psychology');
  
  // Emotion-related tags
  if (lowerContent.contains('feeling') || lowerContent.contains('emotion')) tags.add('emotion');
  if (lowerContent.contains('anxious') || lowerContent.contains('anxiety')) tags.add('anxious');
  if (lowerContent.contains('exam')) tags.add('exam');
  
  return tags;
}

String _getCommunicationStyle(String firstLetter) {
  switch (firstLetter) {
    case 'E':
      return 'expressive and interactive';
    case 'I':
      return 'thoughtful and reflective';
    default:
      return 'balanced communication';
  }
}

String _getSupportApproach(String level) {
  switch (level) {
    case 'minimal':
      return 'encouraging and positive reinforcement';
    case 'mild':
      return 'gentle support with practical suggestions';
    case 'moderate':
      return 'compassionate support with professional resources';
    case 'severe':
      return 'urgent support with immediate professional help';
    default:
      return 'general supportive approach';
  }
}
