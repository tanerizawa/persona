import 'package:flutter_test/flutter_test.dart';
import 'package:persona_ai_assistant/features/little_brain/domain/entities/memory_entities.dart';
import 'dart:math' as math;

void main() {
  group('Little Brain Local Use Cases', () {
    group('Memory Management', () {
      test('should create memory with proper structure', () {
        // Arrange
        const content = 'User loves listening to jazz music';
        const source = 'chat_user';
        final metadata = {'mood': 'happy', 'context': 'music discussion'};

        // Act
        final memory = Memory(
          id: 'test-id',
          content: content,
          source: source,
          timestamp: DateTime.now(),
          tags: ['music', 'jazz', 'preferences'],
          contexts: ['chat', 'music_discussion'],
          emotionalWeight: 0.8,
          type: 'conversation',
          importance: 0.7,
          metadata: metadata,
        );

        // Assert
        expect(memory.content, equals(content));
        expect(memory.source, equals(source));
        expect(memory.tags, contains('music'));
        expect(memory.tags, contains('jazz'));
        expect(memory.contexts, contains('chat'));
        expect(memory.emotionalWeight, equals(0.8));
        expect(memory.metadata['mood'], equals('happy'));
        expect(memory.metadata['context'], equals('music discussion'));
      });

      test('should validate emotional weight range', () {
        // Emotional weight should be between 0.0 and 1.0
        final validWeights = [0.0, 0.5, 1.0, 0.25, 0.75];
        final invalidWeights = [-0.1, 1.1, 2.0, -1.0];

        for (final weight in validWeights) {
          expect(_isValidEmotionalWeight(weight), isTrue,
              reason: 'Emotional weight $weight should be valid');
        }

        for (final weight in invalidWeights) {
          expect(_isValidEmotionalWeight(weight), isFalse,
              reason: 'Emotional weight $weight should be invalid');
        }
      });

      test('should validate memory content quality', () {
        final validContents = [
          'I really enjoyed the movie we watched last night',
          'Feeling stressed about the upcoming exam',
          'Learned a new recipe for chocolate cake today',
        ];

        final invalidContents = ['', 'a', 'ok', 'yes'];

        for (final content in validContents) {
          expect(_isValidMemoryContent(content), isTrue,
              reason: 'Content "$content" should be valid');
        }

        for (final content in invalidContents) {
          expect(_isValidMemoryContent(content), isFalse,
              reason: 'Content "$content" should be invalid');
        }
      });
    });

    group('Personality Profile', () {
      test('should create personality profile with all required fields', () {
        // Arrange
        final traits = {
          'openness': 0.8,
          'conscientiousness': 0.7,
          'extraversion': 0.6,
          'agreeableness': 0.9,
          'neuroticism': 0.3,
        };

        final interests = ['music', 'reading', 'technology', 'psychology'];
        final values = ['honesty', 'creativity', 'growth', 'compassion'];
        final communicationPatterns = {
          'direct_communication': 15,
          'emotional_expression': 8,
          'question_asking': 12,
        };

        // Act
        final profile = PersonalityProfile(
          userId: 'test-user',
          traits: traits,
          interests: interests,
          values: values,
          communicationPatterns: communicationPatterns,
          lastUpdated: DateTime.now(),
          memoryCount: 42,
        );

        // Assert
        expect(profile.userId, equals('test-user'));
        expect(profile.traits['openness'], equals(0.8));
        expect(profile.interests, contains('psychology'));
        expect(profile.values, contains('creativity'));
        expect(profile.communicationPatterns['direct_communication'], equals(15));
        expect(profile.memoryCount, equals(42));
      });

      test('should validate trait values range', () {
        final validTraits = {
          'openness': 0.0,
          'conscientiousness': 0.5,
          'extraversion': 1.0,
        };

        final invalidTraits = {
          'openness': -0.1,
          'conscientiousness': 1.1,
          'extraversion': 2.0,
        };

        expect(_areValidTraitValues(validTraits), isTrue,
            reason: 'Valid trait values should pass validation');
        expect(_areValidTraitValues(invalidTraits), isFalse,
            reason: 'Invalid trait values should fail validation');
      });
    });

    group('Memory Context', () {
      test('should create context with proper structure', () {
        // Arrange
        const contextId = 'context-1';
        const contextName = 'music_discussion';
        const contextType = 'conversation';
        final parameters = {
          'topic': 'jazz music',
          'mood': 'positive',
          'duration_minutes': 15,
        };

        // Act
        final context = MemoryContext(
          id: contextId,
          name: contextName,
          type: contextType,
          parameters: parameters,
        );

        // Assert
        expect(context.id, equals(contextId));
        expect(context.name, equals(contextName));
        expect(context.type, equals(contextType));
        expect(context.parameters['topic'], equals('jazz music'));
        expect(context.parameters['mood'], equals('positive'));
        expect(context.parameters['duration_minutes'], equals(15));
      });
    });

    group('Memory Analytics', () {
      test('should analyze memory patterns', () {
        final memories = [
          Memory(
            id: '1', content: 'jazz music', source: 'chat', timestamp: DateTime.now(),
            tags: ['music', 'jazz'], contexts: ['chat'], emotionalWeight: 0.8, metadata: {},
          ),
          Memory(
            id: '2', content: 'reading book', source: 'activity', timestamp: DateTime.now(),
            tags: ['reading', 'books'], contexts: ['activity'], emotionalWeight: 0.7, metadata: {},
          ),
          Memory(
            id: '3', content: 'guitar practice', source: 'hobby', timestamp: DateTime.now(),
            tags: ['music', 'guitar'], contexts: ['hobby'], emotionalWeight: 0.9, metadata: {},
          ),
        ];

        final analytics = _analyzeMemoryPatterns(memories);
        
        expect(analytics['dominant_interests'], contains('music'));
        expect(analytics['average_emotional_weight'], greaterThan(0.7));
        expect(analytics['memory_count'], equals(3));
        expect(analytics['most_common_source'], isNotNull);
      });

      test('should calculate emotional trends', () {
        final emotionalWeights = [0.8, 0.6, 0.9, 0.7, 0.5];
        final trend = _calculateEmotionalTrend(emotionalWeights);
        
        expect(trend['average'], closeTo(0.7, 0.01));
        expect(trend['trend_direction'], isIn(['stable', 'increasing', 'decreasing']));
        expect(trend['volatility'], greaterThanOrEqualTo(0.0));
      });
    });
  });
}

// Helper functions for testing

bool _isValidMemoryContent(String content) {
  return content.trim().length >= 5;
}

bool _isValidEmotionalWeight(double weight) {
  return weight >= 0.0 && weight <= 1.0;
}

bool _areValidTraitValues(Map<String, double> traits) {
  return traits.values.every((value) => value >= 0.0 && value <= 1.0);
}

Map<String, dynamic> _analyzeMemoryPatterns(List<Memory> memories) {
  final tagFrequency = <String, int>{};
  final sourceFrequency = <String, int>{};
  double totalEmotionalWeight = 0.0;
  
  for (final memory in memories) {
    for (final tag in memory.tags) {
      tagFrequency[tag] = (tagFrequency[tag] ?? 0) + 1;
    }
    
    sourceFrequency[memory.source] = (sourceFrequency[memory.source] ?? 0) + 1;
    totalEmotionalWeight += memory.emotionalWeight;
  }
  
  final dominantInterests = tagFrequency.entries
      .where((entry) => entry.value > 1)
      .map((entry) => entry.key)
      .toList();
      
  final mostCommonSource = sourceFrequency.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;
  
  return {
    'dominant_interests': dominantInterests,
    'average_emotional_weight': totalEmotionalWeight / memories.length,
    'memory_count': memories.length,
    'most_common_source': mostCommonSource,
  };
}

Map<String, dynamic> _calculateEmotionalTrend(List<double> weights) {
  if (weights.isEmpty) return {'average': 0.0, 'trend_direction': 'stable', 'volatility': 0.0};
  
  final average = weights.reduce((a, b) => a + b) / weights.length;
  
  String trendDirection = 'stable';
  if (weights.length > 2) {
    final firstHalf = weights.take(weights.length ~/ 2).toList();
    final secondHalf = weights.skip(weights.length ~/ 2).toList();
    
    final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
    final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;
    
    if (secondAvg > firstAvg + 0.1) {
      trendDirection = 'increasing';
    } else if (secondAvg < firstAvg - 0.1) {
      trendDirection = 'decreasing';
    }
  }
  
  final variance = weights.map((w) => (w - average) * (w - average)).reduce((a, b) => a + b) / weights.length;
  final volatility = (math.sqrt(variance) * 100).round() / 100;
  
  return {
    'average': (average * 100).round() / 100,
    'trend_direction': trendDirection,
    'volatility': volatility,
  };
}
