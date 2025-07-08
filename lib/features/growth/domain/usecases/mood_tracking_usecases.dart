import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../entities/mood_entities.dart';
import '../../../little_brain/domain/entities/memory_entities.dart';
import '../../../little_brain/domain/repositories/little_brain_repository.dart';

@injectable
class MoodTrackingUseCases {
  final LittleBrainRepository _littleBrainRepository;
  final Uuid _uuid = const Uuid();

  MoodTrackingUseCases(this._littleBrainRepository);

  /// Save mood entry to Little Brain as memory
  Future<void> saveMoodEntry(MoodEntry moodEntry) async {
    final memory = Memory(
      id: moodEntry.id,
      content: '${moodEntry.moodDescription} (${moodEntry.moodLevel}/10)${moodEntry.note != null ? ': ${moodEntry.note}' : ''}',
      timestamp: moodEntry.timestamp,
      source: 'mood_tracker',
      emotionalWeight: _calculateEmotionalWeight(moodEntry.moodLevel),
      contexts: _generateContexts(moodEntry),
      tags: ['mood', 'growth', ...moodEntry.tags],
      metadata: {
        'mood_level': moodEntry.moodLevel,
        'mood_description': moodEntry.moodDescription,
        'mood_emoji': moodEntry.moodEmoji,
        'type': 'mood_entry',
        'note': moodEntry.note,
        'activity': moodEntry.activity,
        'location': moodEntry.location,
        ...?moodEntry.metadata,
      },
    );

    await _littleBrainRepository.addMemory(memory);
  }

  /// Create and save new mood entry
  Future<void> logMood({
    required int moodLevel,
    String? note,
    List<String> tags = const [],
    String? activity,
    String? location,
  }) async {
    final moodEntry = MoodEntry(
      id: _uuid.v4(),
      timestamp: DateTime.now(),
      moodLevel: moodLevel,
      note: note,
      tags: tags,
      activity: activity,
      location: location,
    );

    await saveMoodEntry(moodEntry);
  }

  /// Get recent mood entries
  Future<List<MoodEntry>> getRecentMoodEntries({int limit = 30}) async {
    final memories = await _littleBrainRepository.getMemoriesBySource('mood_tracker');
    
    return memories
        .where((memory) => memory.metadata['type'] == 'mood_entry')
        .take(limit)
        .map((memory) => _memoryToMoodEntry(memory))
        .toList();
  }

  /// Get mood entries for specific date range
  Future<List<MoodEntry>> getMoodEntriesInRange(DateTime start, DateTime end) async {
    final memories = await _littleBrainRepository.getMemoriesInRange(start, end);
    
    return memories
        .where((memory) => 
            memory.source == 'mood_tracker' && 
            memory.metadata['type'] == 'mood_entry')
        .map((memory) => _memoryToMoodEntry(memory))
        .toList();
  }

  /// Get mood analytics
  Future<MoodAnalytics> getMoodAnalytics({DateTime? since}) async {
    final cutoffDate = since ?? DateTime.now().subtract(const Duration(days: 30));
    final entries = await getMoodEntriesInRange(cutoffDate, DateTime.now());

    if (entries.isEmpty) {
      return const MoodAnalytics(
        averageMood: 5.0,
        totalEntries: 0,
        moodDistribution: {},
        tagMoodAverages: {},
        trends: [],
      );
    }

    // Calculate average mood
    final averageMood = entries.map((e) => e.moodLevel).reduce((a, b) => a + b) / entries.length;

    // Calculate mood distribution
    final moodDistribution = <String, int>{};
    for (final entry in entries) {
      final key = entry.moodDescription;
      moodDistribution[key] = (moodDistribution[key] ?? 0) + 1;
    }

    // Calculate tag mood averages
    final tagMoodAverages = <String, double>{};
    final tagCounts = <String, int>{};
    
    for (final entry in entries) {
      for (final tag in entry.tags) {
        tagMoodAverages[tag] = (tagMoodAverages[tag] ?? 0) + entry.moodLevel;
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    
    for (final tag in tagMoodAverages.keys) {
      tagMoodAverages[tag] = tagMoodAverages[tag]! / tagCounts[tag]!;
    }

    // Calculate trends
    final trends = _calculateTrends(entries);

    return MoodAnalytics(
      averageMood: averageMood,
      totalEntries: entries.length,
      moodDistribution: moodDistribution,
      tagMoodAverages: tagMoodAverages,
      trends: trends,
      lastEntryDate: entries.isNotEmpty ? entries.first.timestamp : null,
    );
  }

  /// Get today's mood entries
  Future<List<MoodEntry>> getTodayMoodEntries() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return getMoodEntriesInRange(startOfDay, endOfDay);
  }

  /// Check if user has logged mood today
  Future<bool> hasLoggedMoodToday() async {
    final todayEntries = await getTodayMoodEntries();
    return todayEntries.isNotEmpty;
  }

  /// Get mood streak (consecutive days with mood entries)
  Future<int> getMoodStreak() async {
    final now = DateTime.now();
    int streak = 0;
    
    for (int i = 0; i < 365; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final startOfDay = DateTime(checkDate.year, checkDate.month, checkDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final dayEntries = await getMoodEntriesInRange(startOfDay, endOfDay);
      if (dayEntries.isNotEmpty) {
        streak++;
      } else {
        break;
      }
    }
    
    return streak;
  }

  /// Calculate emotional weight based on mood level
  double _calculateEmotionalWeight(int moodLevel) {
    // Extreme moods (very happy or very sad) have higher emotional weight
    final distance = (moodLevel - 5.5).abs();
    return (distance / 4.5).clamp(0.3, 1.0);
  }

  /// Convert memory to mood entry
  MoodEntry _memoryToMoodEntry(Memory memory) {
    final metadata = memory.metadata;
    return MoodEntry(
      id: memory.id,
      timestamp: memory.timestamp,
      moodLevel: metadata['mood_level'] ?? 5,
      note: metadata['note'],
      tags: memory.tags.where((tag) => !['mood', 'growth'].contains(tag)).toList(),
      activity: metadata['activity'],
      location: metadata['location'],
      metadata: metadata,
    );
  }

  /// Generate contexts for mood entry
  List<String> _generateContexts(MoodEntry entry) {
    final contexts = <String>['personal_wellbeing', 'emotional_state'];
    
    if (entry.activity != null) {
      contexts.add('activity:${entry.activity}');
    }
    
    if (entry.location != null) {
      contexts.add('location:${entry.location}');
    }
    
    // Add time-based context
    final hour = entry.timestamp.hour;
    if (hour < 6) {
      contexts.add('time:night');
    } else if (hour < 12) {
      contexts.add('time:morning');
    } else if (hour < 18) {
      contexts.add('time:afternoon');
    } else {
      contexts.add('time:evening');
    }
    
    // Add mood level context
    if (entry.moodLevel <= 3) {
      contexts.add('mood:low');
    } else if (entry.moodLevel >= 8) {
      contexts.add('mood:high');
    } else {
      contexts.add('mood:neutral');
    }
    
    return contexts;
  }

  /// Calculate mood trends
  List<MoodTrend> _calculateTrends(List<MoodEntry> entries) {
    if (entries.length < 7) return [];

    final trends = <MoodTrend>[];
    
    // Weekly trend
    final weeklyTrend = _calculateWeeklyTrend(entries);
    if (weeklyTrend != null) trends.add(weeklyTrend);
    
    // Monthly trend
    final monthlyTrend = _calculateMonthlyTrend(entries);
    if (monthlyTrend != null) trends.add(monthlyTrend);
    
    return trends;
  }

  MoodTrend? _calculateWeeklyTrend(List<MoodEntry> entries) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    
    final recentEntries = entries.where((e) => e.timestamp.isAfter(oneWeekAgo)).toList();
    if (recentEntries.length < 3) return null;
    
    final recentAverage = recentEntries.map((e) => e.moodLevel).reduce((a, b) => a + b) / recentEntries.length;
    final overallAverage = entries.map((e) => e.moodLevel).reduce((a, b) => a + b) / entries.length;
    
    final trendDirection = (recentAverage - overallAverage) / 5.0; // Normalize to -1 to 1
    
    String description;
    if (trendDirection > 0.2) {
      description = 'Mood Anda meningkat minggu ini! 📈';
    } else if (trendDirection < -0.2) {
      description = 'Mood Anda menurun minggu ini. Jaga diri Anda 💙';
    } else {
      description = 'Mood Anda stabil minggu ini 😌';
    }
    
    return MoodTrend(
      period: 'week',
      trendDirection: trendDirection,
      description: description,
      dataPoints: _generateDataPoints(recentEntries, 7),
    );
  }

  MoodTrend? _calculateMonthlyTrend(List<MoodEntry> entries) {
    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    
    final recentEntries = entries.where((e) => e.timestamp.isAfter(oneMonthAgo)).toList();
    if (recentEntries.length < 7) return null;
    
    final recentAverage = recentEntries.map((e) => e.moodLevel).reduce((a, b) => a + b) / recentEntries.length;
    final overallAverage = entries.map((e) => e.moodLevel).reduce((a, b) => a + b) / entries.length;
    
    final trendDirection = (recentAverage - overallAverage) / 5.0;
    
    String description;
    if (trendDirection > 0.15) {
      description = 'Tren positif bulan ini! Pertahankan! 🌟';
    } else if (trendDirection < -0.15) {
      description = 'Perhatikan kesehatan mental Anda bulan ini 🤗';
    } else {
      description = 'Mood Anda konsisten bulan ini 📊';
    }
    
    return MoodTrend(
      period: 'month',
      trendDirection: trendDirection,
      description: description,
      dataPoints: _generateDataPoints(recentEntries, 30),
    );
  }

  List<MoodDataPoint> _generateDataPoints(List<MoodEntry> entries, int days) {
    final dataPoints = <MoodDataPoint>[];
    final now = DateTime.now();
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      
      final dayEntries = entries.where((e) => 
          e.timestamp.isAfter(dayStart) && e.timestamp.isBefore(dayEnd)).toList();
      
      if (dayEntries.isNotEmpty) {
        final averageMood = dayEntries.map((e) => e.moodLevel).reduce((a, b) => a + b) / dayEntries.length;
        dataPoints.add(MoodDataPoint(
          date: dayStart,
          moodValue: averageMood,
          entryCount: dayEntries.length,
        ));
      }
    }
    
    return dataPoints;
  }
}
