import 'package:flutter_test/flutter_test.dart';
import 'package:persona_ai_assistant/features/psychology/domain/entities/psychology_entities.dart';

void main() {
  group('Psychology Entities', () {
    group('MBTIResult', () {
      test('should create MBTI result with all required fields', () {
        final mbtiResult = MBTIResult(
          id: 'mbti_123',
          timestamp: DateTime(2024, 1, 15),
          personalityType: 'INTJ',
          scores: {'E': 20, 'I': 80, 'S': 30, 'N': 70, 'T': 85, 'F': 15, 'J': 75, 'P': 25},
          description: 'The Architect',
          strengths: ['Strategic thinking', 'Independent'],
          weaknesses: ['Overly critical', 'Impatient'],
          careers: ['Scientist', 'Engineer'],
        );

        expect(mbtiResult.id, equals('mbti_123'));
        expect(mbtiResult.personalityType, equals('INTJ'));
        expect(mbtiResult.description, equals('The Architect'));
        expect(mbtiResult.scores['I'], equals(80));
        expect(mbtiResult.strengths, contains('Strategic thinking'));
        expect(mbtiResult.careers, contains('Scientist'));
      });

      test('should convert to memory content format', () {
        final mbtiResult = MBTIResult(
          id: 'mbti_123',
          timestamp: DateTime(2024, 1, 15),
          personalityType: 'INTJ',
          scores: {'E': 20, 'I': 80, 'S': 30, 'N': 70, 'T': 85, 'F': 15, 'J': 75, 'P': 25},
          description: 'The Architect',
          strengths: ['Strategic thinking', 'Independent'],
          weaknesses: ['Overly critical', 'Impatient'],
          careers: ['Scientist', 'Engineer'],
        );

        final memoryContent = mbtiResult.toMemoryContent();

        expect(memoryContent['type'], equals('mbti_result'));
        expect(memoryContent['personality_type'], equals('INTJ'));
        expect(memoryContent['description'], equals('The Architect'));
      });
    });

    group('BDIResult', () {
      test('should create BDI result with all required fields', () {
        final bdiResult = BDIResult(
          id: 'bdi_123',
          timestamp: DateTime(2024, 1, 15),
          totalScore: 15,
          level: DepressionLevel.mild,
          description: 'Mild depression symptoms detected',
          recommendations: ['Regular exercise', 'Consider counseling'],
          needsCrisisIntervention: false,
        );

        expect(bdiResult.id, equals('bdi_123'));
        expect(bdiResult.totalScore, equals(15));
        expect(bdiResult.level, equals(DepressionLevel.mild));
        expect(bdiResult.description, equals('Mild depression symptoms detected'));
        expect(bdiResult.needsCrisisIntervention, equals(false));
      });

      test('should convert to memory content format', () {
        final bdiResult = BDIResult(
          id: 'bdi_123',
          timestamp: DateTime(2024, 1, 15),
          totalScore: 15,
          level: DepressionLevel.mild,
          description: 'Mild depression symptoms detected',
          recommendations: ['Regular exercise', 'Consider counseling'],
          needsCrisisIntervention: false,
        );

        final memoryContent = bdiResult.toMemoryContent();

        expect(memoryContent['type'], equals('bdi_result'));
        expect(memoryContent['total_score'], equals(15));
        expect(memoryContent['level'], equals('mild'));
        expect(memoryContent['needs_crisis_intervention'], equals(false));
      });
    });

    group('PsychologyAnalytics', () {
      test('should create analytics with test history', () {
        final mbtiResult = MBTIResult(
          id: 'mbti_123',
          timestamp: DateTime(2024, 1, 15),
          personalityType: 'INTJ',
          scores: {'E': 20, 'I': 80, 'S': 30, 'N': 70, 'T': 85, 'F': 15, 'J': 75, 'P': 25},
          description: 'The Architect',
          strengths: ['Strategic thinking', 'Independent'],
          weaknesses: ['Overly critical', 'Impatient'],
          careers: ['Scientist', 'Engineer'],
        );

        final bdiResult = BDIResult(
          id: 'bdi_123',
          timestamp: DateTime(2024, 1, 15),
          totalScore: 15,
          level: DepressionLevel.mild,
          description: 'Mild depression symptoms detected',
          recommendations: ['Regular exercise', 'Consider counseling'],
          needsCrisisIntervention: false,
        );

        final analytics = PsychologyAnalytics(
          totalMBTITests: 1,
          totalBDITests: 1,
          latestMBTI: mbtiResult,
          latestBDI: bdiResult,
          bdiHistory: [bdiResult],
          personalityTypeHistory: {'INTJ': 1},
          averageBDIScore: 15.0,
          personalityInsights: ['Prefers logical analysis'],
        );

        expect(analytics.totalMBTITests, equals(1));
        expect(analytics.totalBDITests, equals(1));
        expect(analytics.latestMBTI, equals(mbtiResult));
        expect(analytics.latestBDI, equals(bdiResult));
        expect(analytics.bdiHistory.length, equals(1));
        expect(analytics.averageBDIScore, equals(15.0));
        expect(analytics.personalityInsights, contains('Prefers logical analysis'));
      });
    });

    group('DepressionLevel enum', () {
      test('should provide correct descriptions', () {
        expect(DepressionLevel.minimal.description, contains('Minimal'));
        expect(DepressionLevel.mild.description, contains('Mild'));
        expect(DepressionLevel.moderate.description, contains('Moderate'));
        expect(DepressionLevel.severe.description, contains('Severe'));
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

        final invalidTypes = ['XXXX', 'INT', 'INTJX', '', 'abcd'];

        for (final type in validTypes) {
          expect(_isValidMBTIType(type), isTrue,
              reason: 'MBTI type $type should be valid');
        }

        for (final type in invalidTypes) {
          expect(_isValidMBTIType(type), isFalse,
              reason: 'MBTI type $type should be invalid');
        }
      });
    });

    group('BDI Scoring', () {
      test('should categorize BDI scores correctly', () {
        expect(_getBDILevel(5), equals(DepressionLevel.minimal));
        expect(_getBDILevel(15), equals(DepressionLevel.mild));
        expect(_getBDILevel(25), equals(DepressionLevel.moderate));
        expect(_getBDILevel(35), equals(DepressionLevel.severe));
      });
    });
  });
}

// Helper functions for validation tests
bool _isValidMBTIType(String type) {
  final validTypes = [
    'INTJ', 'INTP', 'ENTJ', 'ENTP',
    'INFJ', 'INFP', 'ENFJ', 'ENFP',
    'ISTJ', 'ISFJ', 'ESTJ', 'ESFJ',
    'ISTP', 'ISFP', 'ESTP', 'ESFP',
  ];
  return validTypes.contains(type);
}

DepressionLevel _getBDILevel(int score) {
  if (score <= 9) return DepressionLevel.minimal;
  if (score <= 18) return DepressionLevel.mild;
  if (score <= 29) return DepressionLevel.moderate;
  return DepressionLevel.severe;
}
