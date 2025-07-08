import 'package:flutter_test/flutter_test.dart';
import 'package:persona_ai_assistant/features/growth/domain/entities/mood_entities.dart';

void main() {
  group('Mood Tracking Entities', () {
    group('MoodEntry', () {
      test('should create mood entry with valid data', () {
        final timestamp = DateTime.now();
        
        final moodEntry = MoodEntry(
          id: 'mood-1',
          moodLevel: 8,
          timestamp: timestamp,
          tags: ['happy', 'productive'],
        );
        
        expect(moodEntry.id, equals('mood-1'));
        expect(moodEntry.moodLevel, equals(8));
        expect(moodEntry.timestamp, equals(timestamp));
        expect(moodEntry.tags, contains('happy'));
        expect(moodEntry.tags, contains('productive'));
      });

      test('should validate mood level range', () {
        // Valid mood levels (1-10)
        final validLevels = [1, 5, 10, 7, 3];
        final invalidLevels = [0, 11, -1, 15];

        for (final level in validLevels) {
          expect(_isValidMoodLevel(level), isTrue,
              reason: 'Mood level $level should be valid');
        }

        for (final level in invalidLevels) {
          expect(_isValidMoodLevel(level), isFalse,
              reason: 'Mood level $level should be invalid');
        }
      });

      test('should convert to memory content format', () {
        final moodEntry = MoodEntry(
          id: 'mood-1',
          moodLevel: 8,
          timestamp: DateTime(2024, 1, 15),
          tags: ['happy', 'productive'],
          note: 'Great day at work',
        );

        final memoryContent = moodEntry.toMemoryContent();

        expect(memoryContent['type'], equals('mood_entry'));
        expect(memoryContent['mood_level'], equals(8));
        expect(memoryContent['tags'], equals(['happy', 'productive']));
        expect(memoryContent['note'], equals('Great day at work'));
      });

      test('should get appropriate emoji for mood level', () {
        expect(_getMoodEmoji(1), equals('😢'));
        expect(_getMoodEmoji(3), equals('😔'));
        expect(_getMoodEmoji(5), equals('😐'));
        expect(_getMoodEmoji(7), equals('😊'));
        expect(_getMoodEmoji(9), equals('😁'));
      });
    });

    group('MoodAnalytics', () {
      test('should create analytics with proper calculations', () {
        final dataPoints = [
          MoodDataPoint(date: DateTime(2024, 1, 1), moodValue: 7.0, entryCount: 3),
          MoodDataPoint(date: DateTime(2024, 1, 2), moodValue: 8.0, entryCount: 2),
        ];
        
        final trends = [
          MoodTrend(
            period: 'week',
            trendDirection: 0.5,
            description: 'Improving trend this week',
            dataPoints: dataPoints,
          ),
        ];
        
        final analytics = MoodAnalytics(
          averageMood: 7.0,
          totalEntries: 5,
          moodDistribution: {'happy': 3, 'okay': 2},
          tagMoodAverages: {'work': 6.5, 'family': 8.0},
          trends: trends,
          lastEntryDate: DateTime(2024, 1, 15),
        );

        expect(analytics.averageMood, equals(7.0));
        expect(analytics.totalEntries, equals(5));
        expect(analytics.moodDistribution, containsPair('happy', 3));
        expect(analytics.tagMoodAverages, containsPair('work', 6.5));
        expect(analytics.trends.length, equals(1));
        expect(analytics.lastEntryDate, equals(DateTime(2024, 1, 15)));
      });
    });

    group('MoodTrend', () {
      test('should create mood trend with period data', () {
        final dataPoints = [
          MoodDataPoint(date: DateTime(2024, 1, 1), moodValue: 7.0, entryCount: 3),
          MoodDataPoint(date: DateTime(2024, 1, 2), moodValue: 8.0, entryCount: 2),
        ];
        
        final trend = MoodTrend(
          period: 'week',
          trendDirection: 0.5,
          description: 'Improving trend this week',
          dataPoints: dataPoints,
        );

        expect(trend.period, equals('week'));
        expect(trend.trendDirection, equals(0.5));
        expect(trend.description, equals('Improving trend this week'));
        expect(trend.dataPoints.length, equals(2));
      });
    });

    group('MoodDataPoint', () {
      test('should create data point with date and mood value', () {
        final dataPoint = MoodDataPoint(
          date: DateTime(2024, 1, 1),
          moodValue: 7.5,
          entryCount: 3,
        );

        expect(dataPoint.date, equals(DateTime(2024, 1, 1)));
        expect(dataPoint.moodValue, equals(7.5));
        expect(dataPoint.entryCount, equals(3));
      });
    });

    group('Mood Validation', () {
      test('should determine mood category correctly', () {
        expect(_getMoodCategory(1), equals('Very Low'));
        expect(_getMoodCategory(3), equals('Low'));
        expect(_getMoodCategory(5), equals('Neutral'));
        expect(_getMoodCategory(7), equals('Good'));
        expect(_getMoodCategory(9), equals('Very Good'));
      });

      test('should calculate mood change percentage', () {
        expect(_calculateMoodChange(6.0, 8.0), closeTo(33.33, 0.01));
        expect(_calculateMoodChange(8.0, 6.0), closeTo(-25.0, 0.01));
        expect(_calculateMoodChange(5.0, 5.0), equals(0.0));
      });
    });
  });
}

// Helper functions for testing
bool _isValidMoodLevel(int level) {
  return level >= 1 && level <= 10;
}

String _getMoodEmoji(int level) {
  if (level <= 2) return '😢';
  if (level <= 4) return '😔';
  if (level <= 6) return '😐';
  if (level <= 8) return '😊';
  return '😁';
}

String _getMoodCategory(int level) {
  if (level <= 2) return 'Very Low';
  if (level <= 4) return 'Low';
  if (level <= 6) return 'Neutral';
  if (level <= 8) return 'Good';
  return 'Very Good';
}

double _calculateMoodChange(double oldMood, double newMood) {
  if (oldMood == 0) return 0.0;
  return ((newMood - oldMood) / oldMood) * 100;
}
