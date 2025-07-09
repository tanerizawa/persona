import 'dart:math' as math;
import '../../domain/entities/memory_entities.dart';

/// Advanced personality intelligence dengan Big Five analysis dan adaptive learning
class PersonalityIntelligence {
  
  /// Analyze Big Five personality traits dari pattern memories
  static Map<String, double> analyzeTraits(List<Memory> memories) {
    if (memories.isEmpty) {
      return _getDefaultTraits();
    }
    
    final patterns = _analyzeMemoryPatterns(memories);
    final emotionalPatterns = _analyzeEmotionalPatterns(memories);
    final socialPatterns = _analyzeSocialPatterns(memories);
    final cognitivePatterns = _analyzeCognitivePatterns(memories);
    
    return {
      'openness': _calculateOpenness(patterns, cognitivePatterns),
      'conscientiousness': _calculateConscientiousness(patterns),
      'extraversion': _calculateExtraversion(socialPatterns),
      'agreeableness': _calculateAgreeableness(socialPatterns, emotionalPatterns),
      'neuroticism': _calculateNeuroticism(emotionalPatterns),
    };
  }

  /// Get default trait values
  static Map<String, double> _getDefaultTraits() {
    return {
      'openness': 0.5,
      'conscientiousness': 0.5,
      'extraversion': 0.5,
      'agreeableness': 0.5,
      'neuroticism': 0.5,
    };
  }

  /// Analyze patterns from memory content and contexts
  static Map<String, dynamic> _analyzeMemoryPatterns(List<Memory> memories) {
    int structuredActivityCount = 0;
    int creativeActivityCount = 0;
    int socialActivityCount = 0;
    int planningActivityCount = 0;
    int noveltySeekingCount = 0;
    int helpingBehaviorCount = 0;
    
    final activityFrequency = <String, int>{};
    final contextFrequency = <String, int>{};
    
    for (final memory in memories) {
      final content = memory.content.toString().toLowerCase();
      final contexts = memory.contexts;
      
      // Structured activities (Conscientiousness indicator)
      if (_containsStructuredKeywords(content)) {
        structuredActivityCount++;
      }
      
      // Creative activities (Openness indicator)
      if (_containsCreativeKeywords(content)) {
        creativeActivityCount++;
      }
      
      // Social activities (Extraversion indicator)
      if (_containsSocialKeywords(content)) {
        socialActivityCount++;
      }
      
      // Planning activities (Conscientiousness indicator)
      if (_containsPlanningKeywords(content)) {
        planningActivityCount++;
      }
      
      // Novelty seeking (Openness indicator)
      if (_containsNoveltyKeywords(content)) {
        noveltySeekingCount++;
      }
      
      // Helping behavior (Agreeableness indicator)
      if (_containsHelpingKeywords(content)) {
        helpingBehaviorCount++;
      }
      
      // Track activity and context frequency
      for (final tag in memory.tags) {
        activityFrequency[tag] = (activityFrequency[tag] ?? 0) + 1;
      }
      
      for (final context in contexts) {
        contextFrequency[context] = (contextFrequency[context] ?? 0) + 1;
      }
    }
    
    final totalMemories = memories.length;
    
    return {
      'structured_ratio': structuredActivityCount / totalMemories,
      'creative_ratio': creativeActivityCount / totalMemories,
      'social_ratio': socialActivityCount / totalMemories,
      'planning_ratio': planningActivityCount / totalMemories,
      'novelty_ratio': noveltySeekingCount / totalMemories,
      'helping_ratio': helpingBehaviorCount / totalMemories,
      'activity_diversity': activityFrequency.length,
      'context_diversity': contextFrequency.length,
      'most_frequent_activities': _getTopItems(activityFrequency, 5),
      'most_frequent_contexts': _getTopItems(contextFrequency, 5),
    };
  }

  /// Analyze emotional patterns for personality insights
  static Map<String, dynamic> _analyzeEmotionalPatterns(List<Memory> memories) {
    final emotionalWeights = memories.map((m) => m.emotionalWeight).toList();
    
    if (emotionalWeights.isEmpty) {
      return {
        'average_emotion': 0.5,
        'emotional_variance': 0.0,
        'emotional_stability': 0.5,
        'positive_emotion_ratio': 0.5,
      };
    }
    
    final averageEmotion = emotionalWeights.reduce((a, b) => a + b) / emotionalWeights.length;
    
    // Calculate emotional variance (stability indicator)
    final variance = emotionalWeights
        .map((w) => math.pow(w - averageEmotion, 2))
        .reduce((a, b) => a + b) / emotionalWeights.length;
    
    final emotionalStability = 1.0 - math.min(1.0, variance * 4); // Invert variance for stability
    
    // Positive emotion ratio
    final positiveEmotions = emotionalWeights.where((w) => w > 0.6).length;
    final positiveRatio = positiveEmotions / emotionalWeights.length;
    
    // Emotional trend analysis
    final trend = _calculateEmotionalTrend(emotionalWeights);
    
    return {
      'average_emotion': averageEmotion,
      'emotional_variance': variance,
      'emotional_stability': emotionalStability,
      'positive_emotion_ratio': positiveRatio,
      'emotional_trend': trend,
    };
  }

  /// Analyze social interaction patterns
  static Map<String, dynamic> _analyzeSocialPatterns(List<Memory> memories) {
    int socialMemoryCount = 0;
    int leadershipIndicators = 0;
    int cooperationIndicators = 0;
    int conflictIndicators = 0;
    
    final socialContexts = <String, int>{};
    
    for (final memory in memories) {
      final content = memory.content.toString().toLowerCase();
      final contexts = memory.contexts;
      
      // Count social memories
      bool isSocial = contexts.any((c) => c.contains('social') || c.contains('friend') || c.contains('family'));
      if (isSocial || _containsSocialKeywords(content)) {
        socialMemoryCount++;
        
        // Track social contexts
        for (final context in contexts) {
          if (context.contains('social') || context.contains('friend') || context.contains('family')) {
            socialContexts[context] = (socialContexts[context] ?? 0) + 1;
          }
        }
      }
      
      // Leadership indicators
      if (_containsLeadershipKeywords(content)) {
        leadershipIndicators++;
      }
      
      // Cooperation indicators
      if (_containsCooperationKeywords(content)) {
        cooperationIndicators++;
      }
      
      // Conflict indicators
      if (_containsConflictKeywords(content)) {
        conflictIndicators++;
      }
    }
    
    final totalMemories = memories.length;
    
    return {
      'social_memory_ratio': socialMemoryCount / totalMemories,
      'leadership_tendency': leadershipIndicators / totalMemories,
      'cooperation_tendency': cooperationIndicators / totalMemories,
      'conflict_tendency': conflictIndicators / totalMemories,
      'social_diversity': socialContexts.length,
      'dominant_social_contexts': _getTopItems(socialContexts, 3),
    };
  }

  /// Analyze cognitive patterns and preferences
  static Map<String, dynamic> _analyzeCognitivePatterns(List<Memory> memories) {
    int analyticalThinking = 0;
    int creativeThinking = 0;
    int abstractThinking = 0;
    int practicalThinking = 0;
    int learningOrientation = 0;
    
    for (final memory in memories) {
      final content = memory.content.toString().toLowerCase();
      
      if (_containsAnalyticalKeywords(content)) {
        analyticalThinking++;
      }
      
      if (_containsCreativeKeywords(content)) {
        creativeThinking++;
      }
      
      if (_containsAbstractKeywords(content)) {
        abstractThinking++;
      }
      
      if (_containsPracticalKeywords(content)) {
        practicalThinking++;
      }
      
      if (_containsLearningKeywords(content)) {
        learningOrientation++;
      }
    }
    
    final totalMemories = memories.length;
    
    return {
      'analytical_ratio': analyticalThinking / totalMemories,
      'creative_ratio': creativeThinking / totalMemories,
      'abstract_ratio': abstractThinking / totalMemories,
      'practical_ratio': practicalThinking / totalMemories,
      'learning_ratio': learningOrientation / totalMemories,
    };
  }

  /// Calculate Openness to Experience
  static double _calculateOpenness(Map<String, dynamic> patterns, Map<String, dynamic> cognitive) {
    double openness = 0.5; // Start with neutral
    
    // Creative activities boost openness
    openness += patterns['creative_ratio'] * 0.3;
    
    // Novelty seeking boost
    openness += patterns['novelty_ratio'] * 0.25;
    
    // Activity diversity boost
    final activityDiversity = patterns['activity_diversity'] as int;
    openness += math.min(0.2, activityDiversity / 20.0);
    
    // Abstract thinking boost
    openness += cognitive['abstract_ratio'] * 0.2;
    
    // Creative thinking boost
    openness += cognitive['creative_ratio'] * 0.25;
    
    return openness.clamp(0.1, 0.9);
  }

  /// Calculate Conscientiousness
  static double _calculateConscientiousness(Map<String, dynamic> patterns) {
    double conscientiousness = 0.5;
    
    // Structured activities boost
    conscientiousness += patterns['structured_ratio'] * 0.4;
    
    // Planning activities boost
    conscientiousness += patterns['planning_ratio'] * 0.35;
    
    // Reduce if too much novelty seeking (impulsiveness indicator)
    conscientiousness -= patterns['novelty_ratio'] * 0.1;
    
    return conscientiousness.clamp(0.1, 0.9);
  }

  /// Calculate Extraversion
  static double _calculateExtraversion(Map<String, dynamic> social) {
    double extraversion = 0.5;
    
    // Social interaction ratio
    extraversion += social['social_memory_ratio'] * 0.4;
    
    // Leadership tendency
    extraversion += social['leadership_tendency'] * 0.3;
    
    // Social diversity
    final socialDiversity = social['social_diversity'] as int;
    extraversion += math.min(0.2, socialDiversity / 10.0);
    
    // Reduce for conflict tendency (introversion indicator)
    extraversion -= social['conflict_tendency'] * 0.1;
    
    return extraversion.clamp(0.1, 0.9);
  }

  /// Calculate Agreeableness
  static double _calculateAgreeableness(Map<String, dynamic> social, Map<String, dynamic> emotional) {
    double agreeableness = 0.5;
    
    // Cooperation tendency boost
    agreeableness += social['cooperation_tendency'] * 0.4;
    
    // Helping behavior boost (from patterns)
    agreeableness += (social['leadership_tendency'] ?? 0.0) * 0.2; // Assuming leadership includes helping
    
    // Positive emotions boost agreeableness
    agreeableness += emotional['positive_emotion_ratio'] * 0.2;
    
    // Reduce for conflict tendency
    agreeableness -= social['conflict_tendency'] * 0.3;
    
    return agreeableness.clamp(0.1, 0.9);
  }

  /// Calculate Neuroticism (emotional instability)
  static double _calculateNeuroticism(Map<String, dynamic> emotional) {
    double neuroticism = 0.5;
    
    // High emotional variance increases neuroticism
    neuroticism += emotional['emotional_variance'] * 0.4;
    
    // Low emotional stability increases neuroticism
    neuroticism += (1.0 - emotional['emotional_stability']) * 0.3;
    
    // Low positive emotion ratio increases neuroticism
    neuroticism += (1.0 - emotional['positive_emotion_ratio']) * 0.2;
    
    // Negative emotional trend increases neuroticism
    final trend = emotional['emotional_trend'] as Map<String, dynamic>;
    if (trend['direction'] == 'declining') {
      neuroticism += 0.1;
    }
    
    return neuroticism.clamp(0.1, 0.9);
  }

  /// Calculate emotional trend from weights
  static Map<String, dynamic> _calculateEmotionalTrend(List<double> weights) {
    if (weights.length < 3) {
      return {'direction': 'stable', 'slope': 0.0, 'consistency': 0.5};
    }
    
    // Simple linear regression for trend
    final n = weights.length;
    final x = List.generate(n, (i) => i.toDouble());
    final y = weights;
    
    final meanX = x.reduce((a, b) => a + b) / n;
    final meanY = y.reduce((a, b) => a + b) / n;
    
    double numerator = 0.0;
    double denominator = 0.0;
    
    for (int i = 0; i < n; i++) {
      numerator += (x[i] - meanX) * (y[i] - meanY);
      denominator += math.pow(x[i] - meanX, 2);
    }
    
    final slope = denominator != 0 ? numerator / denominator : 0.0;
    
    String direction;
    if (slope > 0.01) {
      direction = 'improving';
    } else if (slope < -0.01) {
      direction = 'declining';
    } else {
      direction = 'stable';
    }
    
    // Calculate consistency (inverse of variance)
    final variance = weights.map((w) => math.pow(w - meanY, 2)).reduce((a, b) => a + b) / n;
    final consistency = 1.0 - math.min(1.0, variance * 4);
    
    return {
      'direction': direction,
      'slope': slope,
      'consistency': consistency,
    };
  }

  /// Get top items from frequency map
  static List<String> _getTopItems(Map<String, int> frequency, int limit) {
    final sorted = frequency.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  // Keyword detection methods
  static bool _containsStructuredKeywords(String content) {
    const keywords = [
      'plan', 'schedule', 'organize', 'structure', 'routine', 'systematic',
      'rencana', 'jadwal', 'teratur', 'sistematis', 'rutin', 'disiplin'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsCreativeKeywords(String content) {
    const keywords = [
      'creative', 'art', 'music', 'design', 'imagine', 'innovative',
      'kreatif', 'seni', 'musik', 'desain', 'inovasi', 'ide', 'inspirasi'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsSocialKeywords(String content) {
    const keywords = [
      'friend', 'social', 'party', 'meeting', 'together', 'group',
      'teman', 'sosial', 'pesta', 'bertemu', 'bersama', 'grup', 'kumpul'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsPlanningKeywords(String content) {
    const keywords = [
      'plan', 'goal', 'target', 'deadline', 'prepare', 'strategy',
      'rencana', 'tujuan', 'target', 'persiapan', 'strategi'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsNoveltyKeywords(String content) {
    const keywords = [
      'new', 'different', 'explore', 'adventure', 'try', 'experiment',
      'baru', 'berbeda', 'jelajah', 'petualangan', 'coba', 'eksperimen'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsHelpingKeywords(String content) {
    const keywords = [
      'help', 'assist', 'support', 'care', 'kind', 'give',
      'bantu', 'dukung', 'peduli', 'baik', 'beri', 'tolong'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsLeadershipKeywords(String content) {
    const keywords = [
      'lead', 'manage', 'direct', 'organize', 'coordinate', 'guide',
      'pimpin', 'kelola', 'arah', 'organisir', 'koordinasi', 'bimbing'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsCooperationKeywords(String content) {
    const keywords = [
      'cooperate', 'collaborate', 'team', 'together', 'share', 'agree',
      'kerjasama', 'kolaborasi', 'tim', 'bersama', 'berbagi', 'setuju'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsConflictKeywords(String content) {
    const keywords = [
      'conflict', 'argue', 'fight', 'disagree', 'problem', 'issue',
      'konflik', 'bertengkar', 'tidak setuju', 'masalah', 'isu'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsAnalyticalKeywords(String content) {
    const keywords = [
      'analyze', 'think', 'logic', 'reason', 'study', 'research',
      'analisis', 'pikir', 'logika', 'alasan', 'belajar', 'riset'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsAbstractKeywords(String content) {
    const keywords = [
      'concept', 'theory', 'philosophy', 'abstract', 'idea', 'meaning',
      'konsep', 'teori', 'filosofi', 'abstrak', 'ide', 'makna'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsPracticalKeywords(String content) {
    const keywords = [
      'practical', 'useful', 'apply', 'implement', 'real', 'concrete',
      'praktis', 'berguna', 'terapkan', 'implementasi', 'nyata', 'konkret'
    ];
    return keywords.any((k) => content.contains(k));
  }

  static bool _containsLearningKeywords(String content) {
    const keywords = [
      'learn', 'study', 'education', 'knowledge', 'skill', 'understand',
      'belajar', 'pendidikan', 'pengetahuan', 'keterampilan', 'mengerti'
    ];
    return keywords.any((k) => content.contains(k));
  }

  /// Generate personality insights summary
  static PersonalityInsights generateInsights(Map<String, double> traits, List<Memory> memories) {
    final insights = <String>[];
    final strengths = <String>[];
    final growthAreas = <String>[];
    final recommendations = <String>[];
    
    // Analyze each trait
    for (final entry in traits.entries) {
      final trait = entry.key;
      final value = entry.value;
      
      if (value > 0.7) {
        strengths.add(_getTraitStrength(trait));
        insights.add(_getHighTraitInsight(trait));
      } else if (value < 0.3) {
        growthAreas.add(_getTraitGrowthArea(trait));
        recommendations.add(_getTraitRecommendation(trait));
      } else {
        insights.add(_getBalancedTraitInsight(trait));
      }
    }
    
    // Generate personality type description
    final personalityType = _generatePersonalityType(traits);
    
    return PersonalityInsights(
      traits: traits,
      interests: _extractInterests(memories),
      values: _extractValues(memories),
      personalityType: personalityType,
      strengths: strengths,
      growthAreas: growthAreas,
      recommendations: recommendations,
      insights: insights,
      lastUpdated: DateTime.now(),
      memoryCount: memories.length,
    );
  }

  static String _getTraitStrength(String trait) {
    const strengths = {
      'openness': 'Creative and curious mind',
      'conscientiousness': 'Highly organized and disciplined',
      'extraversion': 'Socially energetic and outgoing',
      'agreeableness': 'Cooperative and empathetic',
      'neuroticism': 'Emotionally sensitive and aware',
    };
    return strengths[trait] ?? 'Strong in $trait';
  }

  static String _getTraitGrowthArea(String trait) {
    const growthAreas = {
      'openness': 'Could benefit from exploring new experiences',
      'conscientiousness': 'Might improve organization and planning skills',
      'extraversion': 'Could develop social interaction skills',
      'agreeableness': 'Might work on cooperation and empathy',
      'neuroticism': 'Could benefit from emotional regulation techniques',
    };
    return growthAreas[trait] ?? 'Growth opportunity in $trait';
  }

  static String _getTraitRecommendation(String trait) {
    const recommendations = {
      'openness': 'Try new hobbies or creative activities',
      'conscientiousness': 'Use planning tools and set clear goals',
      'extraversion': 'Engage in social activities and group events',
      'agreeableness': 'Practice active listening and collaboration',
      'neuroticism': 'Consider mindfulness or stress management techniques',
    };
    return recommendations[trait] ?? 'Focus on developing $trait';
  }

  static String _getHighTraitInsight(String trait) {
    const insights = {
      'openness': 'You have a naturally curious and creative personality',
      'conscientiousness': 'You demonstrate strong self-discipline and organization',
      'extraversion': 'You thrive in social situations and enjoy interpersonal connections',
      'agreeableness': 'You show high empathy and cooperation with others',
      'neuroticism': 'You are emotionally sensitive and highly attuned to your feelings',
    };
    return insights[trait] ?? 'High $trait detected';
  }

  static String _getBalancedTraitInsight(String trait) {
    const insights = {
      'openness': 'You show a balanced approach to new experiences',
      'conscientiousness': 'You maintain a moderate level of organization',
      'extraversion': 'You balance social time with personal reflection',
      'agreeableness': 'You show appropriate cooperation while maintaining boundaries',
      'neuroticism': 'You demonstrate good emotional stability',
    };
    return insights[trait] ?? 'Balanced $trait levels';
  }

  static String _generatePersonalityType(Map<String, double> traits) {
    final high = <String>[];
    final low = <String>[];
    
    for (final entry in traits.entries) {
      if (entry.value > 0.6) {
        high.add(entry.key);
      } else if (entry.value < 0.4) {
        low.add(entry.key);
      }
    }
    
    // Generate descriptive type
    if (high.contains('extraversion') && high.contains('openness')) {
      return 'Creative Enthusiast';
    } else if (high.contains('conscientiousness') && high.contains('agreeableness')) {
      return 'Reliable Helper';
    } else if (high.contains('openness') && low.contains('extraversion')) {
      return 'Thoughtful Creator';
    } else if (high.contains('extraversion') && high.contains('agreeableness')) {
      return 'Social Connector';
    } else if (high.contains('conscientiousness') && high.contains('openness')) {
      return 'Innovative Organizer';
    } else {
      return 'Balanced Individual';
    }
  }

  static List<String> _extractInterests(List<Memory> memories) {
    final interests = <String, int>{};
    
    for (final memory in memories) {
      for (final tag in memory.tags) {
        interests[tag] = (interests[tag] ?? 0) + 1;
      }
    }
    
    return _getTopItems(interests, 10);
  }

  static List<String> _extractValues(List<Memory> memories) {
    // Simple value extraction based on memory patterns
    const valueKeywords = {
      'family': ['family', 'keluarga', 'loved ones'],
      'achievement': ['success', 'goal', 'accomplish', 'sukses', 'prestasi'],
      'creativity': ['art', 'creative', 'design', 'seni', 'kreatif'],
      'helping_others': ['help', 'support', 'volunteer', 'bantu', 'peduli'],
      'learning': ['learn', 'education', 'knowledge', 'belajar', 'pendidikan'],
      'freedom': ['freedom', 'independent', 'choice', 'bebas', 'mandiri'],
    };
    
    final values = <String, int>{};
    
    for (final memory in memories) {
      final content = memory.content.toString().toLowerCase();
      
      for (final entry in valueKeywords.entries) {
        for (final keyword in entry.value) {
          if (content.contains(keyword)) {
            values[entry.key] = (values[entry.key] ?? 0) + 1;
            break;
          }
        }
      }
    }
    
    return _getTopItems(values, 5);
  }
}

/// Comprehensive personality insights
class PersonalityInsights {
  final Map<String, double> traits;
  final List<String> interests;
  final List<String> values;
  final String personalityType;
  final List<String> strengths;
  final List<String> growthAreas;
  final List<String> recommendations;
  final List<String> insights;
  final DateTime lastUpdated;
  final int memoryCount;

  const PersonalityInsights({
    required this.traits,
    required this.interests,
    required this.values,
    required this.personalityType,
    required this.strengths,
    required this.growthAreas,
    required this.recommendations,
    required this.insights,
    required this.lastUpdated,
    required this.memoryCount,
  });

  static PersonalityInsights empty() {
    return PersonalityInsights(
      traits: {
        'openness': 0.5,
        'conscientiousness': 0.5,
        'extraversion': 0.5,
        'agreeableness': 0.5,
        'neuroticism': 0.5,
      },
      interests: [],
      values: [],
      personalityType: 'Unknown',
      strengths: [],
      growthAreas: [],
      recommendations: [],
      insights: [],
      lastUpdated: DateTime.now(),
      memoryCount: 0,
    );
  }
}
