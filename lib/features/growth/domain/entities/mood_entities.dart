import 'package:equatable/equatable.dart';

/// Mood entry that will be stored in Little Brain as a memory
class MoodEntry extends Equatable {
  final String id;
  final DateTime timestamp;
  final int moodLevel; // 1-10 scale
  final String? note;
  final List<String> tags; // e.g., ['work', 'family', 'health']
  final String? activity; // What was the user doing
  final String? location; // Where was the user
  final Map<String, dynamic>? metadata; // Additional context

  const MoodEntry({
    required this.id,
    required this.timestamp,
    required this.moodLevel,
    this.note,
    this.tags = const [],
    this.activity,
    this.location,
    this.metadata,
  });

  /// Convert to memory format for Little Brain storage
  Map<String, dynamic> toMemoryContent() {
    return {
      'type': 'mood_entry',
      'mood_level': moodLevel,
      'note': note,
      'tags': tags,
      'activity': activity,
      'location': location,
      'metadata': metadata,
    };
  }

  /// Get mood description based on level
  String get moodDescription {
    switch (moodLevel) {
      case 1:
      case 2:
        return 'Sangat Sedih';
      case 3:
      case 4:
        return 'Sedih';
      case 5:
      case 6:
        return 'Netral';
      case 7:
      case 8:
        return 'Senang';
      case 9:
      case 10:
        return 'Sangat Senang';
      default:
        return 'Netral';
    }
  }

  /// Get mood emoji based on level
  String get moodEmoji {
    switch (moodLevel) {
      case 1:
      case 2:
        return '😢';
      case 3:
      case 4:
        return '😞';
      case 5:
      case 6:
        return '😐';
      case 7:
      case 8:
        return '😊';
      case 9:
      case 10:
        return '😄';
      default:
        return '😐';
    }
  }

  /// Get mood color based on level
  String get moodColorHex {
    switch (moodLevel) {
      case 1:
      case 2:
        return '#FF5252'; // Red
      case 3:
      case 4:
        return '#FF9800'; // Orange
      case 5:
      case 6:
        return '#FFC107'; // Amber
      case 7:
      case 8:
        return '#8BC34A'; // Light Green
      case 9:
      case 10:
        return '#4CAF50'; // Green
      default:
        return '#FFC107'; // Amber
    }
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        moodLevel,
        note,
        tags,
        activity,
        location,
        metadata,
      ];
}

/// Mood analytics data for insights
class MoodAnalytics extends Equatable {
  final double averageMood;
  final int totalEntries;
  final Map<String, int> moodDistribution; // mood level -> count
  final Map<String, double> tagMoodAverages; // tag -> average mood
  final List<MoodTrend> trends;
  final DateTime? lastEntryDate;

  const MoodAnalytics({
    required this.averageMood,
    required this.totalEntries,
    required this.moodDistribution,
    required this.tagMoodAverages,
    required this.trends,
    this.lastEntryDate,
  });

  @override
  List<Object?> get props => [
        averageMood,
        totalEntries,
        moodDistribution,
        tagMoodAverages,
        trends,
        lastEntryDate,
      ];
}

/// Mood trend analysis
class MoodTrend extends Equatable {
  final String period; // 'week', 'month', 'year'
  final double trendDirection; // -1 to 1, negative = declining, positive = improving
  final String description;
  final List<MoodDataPoint> dataPoints;

  const MoodTrend({
    required this.period,
    required this.trendDirection,
    required this.description,
    required this.dataPoints,
  });

  @override
  List<Object?> get props => [period, trendDirection, description, dataPoints];
}

/// Data point for mood charts
class MoodDataPoint extends Equatable {
  final DateTime date;
  final double moodValue;
  final int entryCount;

  const MoodDataPoint({
    required this.date,
    required this.moodValue,
    required this.entryCount,
  });

  @override
  List<Object?> get props => [date, moodValue, entryCount];
}
