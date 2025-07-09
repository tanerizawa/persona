import 'dart:math' as math;
import 'package:injectable/injectable.dart';
import '../models/hive_models.dart';
import '../../domain/entities/memory_entities.dart';
import 'enhanced_emotion_detector.dart';
import 'advanced_context_extractor.dart';
import 'personality_intelligence.dart';
import '../../../../core/services/little_brain_performance_monitor.dart';

@injectable
class LocalAIService {
  // Predefined emotion keywords untuk local processing (Indonesia & English)
  static const Map<String, List<String>> emotionKeywords = {
    'happy': [
      'senang', 'gembira', 'bahagia', 'excited', 'joy', 'suka', 'riang',
      'happy', 'cheerful', 'delighted', 'pleased', 'glad', 'euphoric'
    ],
    'sad': [
      'sedih', 'down', 'kecewa', 'disappointed', 'grief', 'dukacita', 'murung',
      'sad', 'depressed', 'sorrowful', 'melancholy', 'heartbroken', 'upset'
    ],
    'angry': [
      'marah', 'kesal', 'frustrated', 'annoyed', 'furious', 'jengkel', 'benci',
      'angry', 'rage', 'irritated', 'mad', 'livid', 'outraged'
    ],
    'anxious': [
      'cemas', 'worry', 'nervous', 'stress', 'panic', 'khawatir', 'gelisah',
      'anxious', 'worried', 'tense', 'uneasy', 'restless', 'apprehensive'
    ],
    'calm': [
      'tenang', 'peaceful', 'relaxed', 'serene', 'zen', 'damai', 'santai',
      'calm', 'tranquil', 'composed', 'stable', 'balanced', 'centered'
    ],
    'excited': [
      'antusias', 'semangat', 'passionate', 'eager', 'enthusiastic',
      'excited', 'thrilled', 'pumped', 'energetic', 'motivated'
    ],
  };

  static const Map<String, List<String>> activityKeywords = {
    'work': [
      'kerja', 'kantor', 'meeting', 'project', 'deadline', 'tugas', 'bisnis',
      'work', 'office', 'professional', 'career', 'job', 'business'
    ],
    'study': [
      'belajar', 'kuliah', 'sekolah', 'exam', 'research', 'ujian', 'kampus',
      'study', 'school', 'university', 'learning', 'education', 'course'
    ],
    'exercise': [
      'olahraga', 'gym', 'running', 'workout', 'fitness', 'lari', 'senam',
      'exercise', 'sport', 'training', 'physical', 'cardio', 'strength'
    ],
    'social': [
      'teman', 'family', 'party', 'gathering', 'dinner', 'keluarga', 'hangout',
      'social', 'friends', 'relationship', 'community', 'together', 'meet'
    ],
    'hobby': [
      'musik', 'reading', 'gaming', 'art', 'creative', 'hobi', 'seni',
      'hobby', 'music', 'book', 'game', 'painting', 'photography'
    ],
    'health': [
      'sehat', 'sakit', 'dokter', 'obat', 'rumah sakit', 'medical',
      'health', 'sick', 'doctor', 'medicine', 'hospital', 'wellness'
    ],
    'travel': [
      'jalan', 'liburan', 'pergi', 'wisata', 'vacation', 'trip',
      'travel', 'holiday', 'journey', 'visit', 'explore', 'adventure'
    ],
  };

  static const Map<String, List<String>> relationshipKeywords = {
    'family': [
      'keluarga', 'orangtua', 'ayah', 'ibu', 'adik', 'kakak', 'anak',
      'family', 'parents', 'father', 'mother', 'brother', 'sister', 'child'
    ],
    'romantic': [
      'pacar', 'suami', 'istri', 'cinta', 'sayang', 'relationship',
      'boyfriend', 'girlfriend', 'husband', 'wife', 'love', 'romantic'
    ],
    'friends': [
      'teman', 'sahabat', 'bestfriend', 'kawan', 'sobat',
      'friends', 'buddy', 'pal', 'companion', 'colleague'
    ],
  };

  // Extract contexts dari text secara lokal
  Future<List<String>> extractContextsFromText(String text) async {
    return await PerformanceWrapper.track('context_extraction', () async {
      final contexts = <String>{};
      final lowerText = text.toLowerCase();

      // Emotion detection
      for (final emotion in emotionKeywords.keys) {
        for (final keyword in emotionKeywords[emotion]!) {
          if (lowerText.contains(keyword)) {
            contexts.add('emotion:$emotion');
            break;
          }
        }
      }

      // Activity detection
      for (final activity in activityKeywords.keys) {
        for (final keyword in activityKeywords[activity]!) {
          if (lowerText.contains(keyword)) {
            contexts.add('activity:$activity');
            break;
          }
        }
      }

      // Relationship detection
      for (final relationship in relationshipKeywords.keys) {
        for (final keyword in relationshipKeywords[relationship]!) {
          if (lowerText.contains(keyword)) {
            contexts.add('relationship:$relationship');
            break;
          }
        }
      }

      // Time-based context
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) {
        contexts.add('time:morning');
      } else if (hour >= 12 && hour < 17) {
        contexts.add('time:afternoon');
      } else if (hour >= 17 && hour < 21) {
        contexts.add('time:evening');
      } else {
        contexts.add('time:night');
      }

      // Day-based context
      final weekday = DateTime.now().weekday;
      if (weekday <= 5) {
        contexts.add('time:weekday');
      } else {
        contexts.add('time:weekend');
      }

      return contexts.toList();
    });
  }

  // Generate tags menggunakan keyword extraction + NLP sederhana
  Future<List<String>> generateTagsFromText(String text) async {
    return await PerformanceWrapper.track('tag_generation', () async {
      final tags = <String>{};
    
    // Split text menjadi kata-kata
    final words = text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ') // Remove punctuation
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    // Stop words yang diabaikan
    final stopWords = {
      // Indonesian stop words
      'dan', 'atau', 'yang', 'ini', 'itu', 'dengan', 'untuk', 'dari', 'ke', 
      'di', 'pada', 'adalah', 'akan', 'sudah', 'telah', 'tidak', 'juga', 
      'ada', 'saya', 'kamu', 'dia', 'kita', 'mereka', 'kami', 'nya',
      // English stop words
      'the', 'and', 'or', 'is', 'are', 'was', 'were', 'have', 'has', 'had',
      'will', 'would', 'could', 'should', 'can', 'may', 'must', 'shall',
      'do', 'did', 'does', 'won', 'couldn', 'shouldn',
      'a', 'an', 'at', 'by', 'for', 'from', 'in', 'into', 'of', 'on',
      'to', 'with', 'about', 'against', 'between', 'during', 'before',
      'after', 'above', 'below', 'up', 'down', 'out', 'off', 'over',
      'under', 'again', 'further', 'then', 'once', 'here', 'there',
      'when', 'where', 'why', 'how', 'all', 'any', 'both', 'each',
      'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor',
      'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very',
      'just', 'now', 'i', 'me', 'my', 'myself', 'we', 'our', 'ours',
      'ourselves', 'you', 'your', 'yours', 'yourself', 'yourselves',
      'he', 'him', 'his', 'himself', 'she', 'her', 'hers', 'herself',
      'it', 'its', 'itself', 'they', 'them', 'their', 'theirs',
      'themselves', 'what', 'which', 'who', 'whom', 'this', 'that',
      'these', 'those', 'am', 'being', 'been'
    };

    // Extract meaningful words
    for (final word in words) {
      if (word.length >= 3 && !stopWords.contains(word)) {
        // Check if word contains letters (not just numbers)
        if (RegExp(r'[a-zA-Z]').hasMatch(word)) {
          tags.add(word);
        }
      }
    }

    // Extract compound phrases (2-3 words) yang meaningful
    for (int i = 0; i < words.length - 1; i++) {
      final phrase = '${words[i]} ${words[i + 1]}';
      if (!stopWords.contains(words[i]) && !stopWords.contains(words[i + 1])) {
        if (phrase.length >= 6 && phrase.length <= 30) {
          tags.add(phrase);
        }
      }
    }

    // Sort by frequency in all emotion/activity keywords (boost relevant words)
    final boostedTags = <String>[];
    final regularTags = <String>[];

    for (final tag in tags) {
      bool isBoosted = false;
      for (final keywordList in [...emotionKeywords.values, ...activityKeywords.values, ...relationshipKeywords.values]) {
        if (keywordList.contains(tag)) {
          boostedTags.add(tag);
          isBoosted = true;
          break;
        }
      }
      if (!isBoosted) {
        regularTags.add(tag);
      }
    }

    // Combine boosted tags first, then regular tags
    final result = [...boostedTags, ...regularTags];
    return result.take(10).toList(); // Max 10 tags
    });
  }

  // Hitung emotional weight berdasarkan keywords dan context
  Future<double> calculateEmotionalWeight(String text, List<String> contexts) async {
    return await PerformanceWrapper.track('emotional_weight_calculation', () async {
      double weight = 0.5; // Neutral baseline

    // Analyze emotional contexts
    for (final context in contexts) {
      if (context.startsWith('emotion:')) {
        final emotion = context.substring(8);
        switch (emotion) {
          case 'happy':
          case 'excited':
            weight += 0.3;
            break;
          case 'calm':
            weight += 0.1;
            break;
          case 'sad':
          case 'angry':
            weight -= 0.3;
            break;
          case 'anxious':
            weight -= 0.2;
            break;
        }
      }
    }

    // Intensity modifiers
    final intensityWords = [
      'very', 'really', 'extremely', 'super', 'totally', 'completely',
      'sangat', 'sekali', 'banget', 'benar-benar', 'sungguh', 'amat'
    ];
    
    for (final word in intensityWords) {
      if (text.toLowerCase().contains(word)) {
        // Amplify current weight direction
        if (weight > 0.5) {
          weight = math.min(1.0, weight + 0.2);
        } else if (weight < 0.5) {
          weight = math.max(0.0, weight - 0.2);
        }
        break;
      }
    }

    // Positive amplifiers
    final positiveWords = [
      'amazing', 'awesome', 'fantastic', 'wonderful', 'perfect', 'best',
      'luar biasa', 'hebat', 'keren', 'bagus', 'sempurna', 'terbaik'
    ];
    
    for (final word in positiveWords) {
      if (text.toLowerCase().contains(word)) {
        weight = math.min(1.0, weight + 0.25);
        break;
      }
    }

    // Negative amplifiers
    final negativeWords = [
      'terrible', 'awful', 'horrible', 'worst', 'hate', 'disgusting',
      'buruk', 'jelek', 'parah', 'menyebalkan', 'terburuk', 'benci'
    ];
    
    for (final word in negativeWords) {
      if (text.toLowerCase().contains(word)) {
        weight = math.max(0.0, weight - 0.25);
        break;
      }
    }

    return weight.clamp(0.0, 1.0);
    });
  }

  // Analyze personality traits dari collection memories
  Future<Map<String, double>> analyzePersonalityTraits(List<HiveMemory> memories) async {
    return await PerformanceWrapper.track('personality_analysis', () async {
      final traits = <String, double>{
        'openness': 0.5,
        'conscientiousness': 0.5,
        'extraversion': 0.5,
        'agreeableness': 0.5,
        'neuroticism': 0.5,
      };

    if (memories.isEmpty) return traits;

    // Counters untuk analysis
    int socialCount = 0;
    int workCount = 0;
    int creativeCount = 0;
    int structuredCount = 0;
    int helpfulCount = 0;

    double totalEmotionalWeight = 0.0;
    double emotionalVariance = 0.0;

    // Analyze patterns dari memories
    for (final memory in memories) {
      totalEmotionalWeight += memory.emotionalWeight;

      // Count different activity types
      for (final context in memory.contexts) {
        if (context.contains('social') || context.contains('friends') || context.contains('family')) {
          socialCount++;
        }
        if (context.contains('work') || context.contains('study')) {
          workCount++;
        }
        if (context.contains('hobby') || context.contains('art') || context.contains('creative')) {
          creativeCount++;
        }
      }

      // Check for emotional stability (removed - not used in calculations)

      // Check for structure/planning indicators
      if (memory.content.toLowerCase().contains(RegExp(r'plan|schedule|organize|structured|routine'))) {
        structuredCount++;
      }

      // Check for helping/agreeable behavior
      if (memory.content.toLowerCase().contains(RegExp(r'help|assist|support|care|kind|nice'))) {
        helpfulCount++;
      }
    }

    final total = memories.length;
    final avgEmotionalWeight = totalEmotionalWeight / total;

    // Calculate emotional variance
    for (final memory in memories) {
      emotionalVariance += (memory.emotionalWeight - avgEmotionalWeight) * (memory.emotionalWeight - avgEmotionalWeight);
    }
    emotionalVariance /= total;

    // Calculate personality scores
    traits['extraversion'] = (socialCount / total * 0.7 + 0.3).clamp(0.1, 0.9);
    traits['conscientiousness'] = (workCount / total * 0.6 + structuredCount / total * 0.4).clamp(0.1, 0.9);
    traits['openness'] = (creativeCount / total * 0.8 + 0.2).clamp(0.1, 0.9);
    traits['neuroticism'] = (emotionalVariance * 2).clamp(0.1, 0.9);
    traits['agreeableness'] = (helpfulCount / total * 0.7 + (1.0 - traits['neuroticism']!) * 0.3).clamp(0.1, 0.9);

    return traits;
    });
  }

  // Create AI context string untuk chat berdasarkan relevant memories
  Future<String> createAIContext(List<HiveMemory> relevantMemories, String currentInput) async {
    return await PerformanceWrapper.track('ai_context_creation', () async {
      if (relevantMemories.isEmpty) {
        return "User is starting a new conversation with no previous context.";
      }

    // Extract unique contexts
    final contexts = relevantMemories
        .expand((m) => m.contexts)
        .toSet()
        .take(8)
        .toList();

    // Get recent memories (max 3)
    final recentMemories = relevantMemories
        .take(3)
        .map((m) => "- ${m.content} (${_formatTimestamp(m.timestamp)})")
        .join('\n');

    // Analyze current mood
    final currentMood = await _inferCurrentMood(relevantMemories);
    
    // Extract interests
    final interests = relevantMemories
        .expand((m) => m.tags)
        .toList();
    final topInterests = _getTopItems(interests, 5);

    return """
USER CONTEXT:
- Current mood: $currentMood
- Active contexts: ${contexts.join(', ')}
- Main interests: ${topInterests.join(', ')}

RECENT RELEVANT MEMORIES:
$recentMemories

PERSONALITY INSIGHTS:
${await _generatePersonalityInsights(relevantMemories)}

Instructions: Use this context to provide personalized, empathetic responses that align with the user's personality and current situation.
""";
    });
  }

  /// Enhanced emotion detection dengan multi-language support
  Future<List<String>> detectEmotionsEnhanced(String text, {List<String>? contexts}) async {
    return await PerformanceWrapper.track('emotion_detection', () async {
      final result = EnhancedEmotionDetector.detectEmotions(text, contexts: contexts);
      return result.emotions.map((e) => e.emotion).toList();
    });
  }

  /// Enhanced context extraction dengan pattern recognition
  Future<List<String>> extractContextsEnhanced(String text, {DateTime? timestamp}) async {
    return await PerformanceWrapper.track('context_extraction', () async {
      final result = AdvancedContextExtractor.extractContexts(text, timestamp: timestamp);
      return result.contextTags;
    });
  }

  /// Enhanced emotional weight calculation
  Future<double> calculateEmotionalWeightEnhanced(String text, List<String> contexts) async {
    return await PerformanceWrapper.track('emotional_weight_calculation', () async {
      final emotionResult = EnhancedEmotionDetector.detectEmotions(text, contexts: contexts);
      
      if (emotionResult.emotions.isEmpty) return 0.5;
      
      // Calculate weighted average based on emotion polarity and confidence
      double totalWeight = 0.0;
      double totalConfidence = 0.0;
      
      for (final emotion in emotionResult.emotions) {
        final polarity = _getEmotionPolarity(emotion.emotion);
        final weight = 0.5 + (polarity * 0.5); // Convert -1,1 to 0,1 range
        
        totalWeight += weight * emotion.confidence;
        totalConfidence += emotion.confidence;
      }
      
      return totalConfidence > 0 ? totalWeight / totalConfidence : 0.5;
    });
  }

  /// Enhanced personality trait analysis
  Future<Map<String, double>> analyzePersonalityTraitsEnhanced(List<HiveMemory> memories) async {
    return await PerformanceWrapper.track('personality_analysis', () async {
      // Convert HiveMemory to Memory entities
      final memoryEntities = memories.map((hive) => Memory(
        id: hive.id,
        content: hive.content,
        tags: hive.tags,
        contexts: hive.contexts,
        emotionalWeight: hive.emotionalWeight,
        timestamp: hive.timestamp,
        source: hive.source,
        metadata: hive.metadata,
      )).toList();
      
      return PersonalityIntelligence.analyzeTraits(memoryEntities);
    });
  }

  /// Enhanced AI context generation dengan comprehensive analysis
  Future<String> createAIContextEnhanced(List<HiveMemory> relevantMemories, String currentInput) async {
    return await PerformanceWrapper.track('ai_context_generation', () async {
      if (relevantMemories.isEmpty) {
        return "User is starting a new conversation with no previous context.";
      }

      // Enhanced emotion and context analysis
      final emotionResult = EnhancedEmotionDetector.detectEmotions(currentInput);
      final contextResult = AdvancedContextExtractor.extractContexts(currentInput, timestamp: DateTime.now());
      
      // Convert memories to entities for personality analysis
      final memoryEntities = relevantMemories.map((hive) => Memory(
        id: hive.id,
        content: hive.content,
        tags: hive.tags,
        contexts: hive.contexts,
        emotionalWeight: hive.emotionalWeight,
        timestamp: hive.timestamp,
        source: hive.source,
        metadata: hive.metadata,
      )).toList();

      // Generate personality insights
      final traits = PersonalityIntelligence.analyzeTraits(memoryEntities);
      final insights = PersonalityIntelligence.generateInsights(traits, memoryEntities);

      // Extract unique contexts and emotions
      final contexts = contextResult.contextTags.take(5).toList();
      final emotions = emotionResult.emotions.take(3).map((e) => 
        '${e.emotion} (${(e.confidence * 100).toInt()}%)'
      ).toList();

      // Get recent memories summary
      final recentMemories = relevantMemories
          .take(3)
          .map((m) => "- ${m.content} (${_formatTimestamp(m.timestamp)})")
          .join('\n');

      return """
USER CONTEXT:
- Current emotions: ${emotions.join(', ')}
- Active contexts: ${contexts.join(', ')}
- Personality type: ${insights.personalityType}
- Main interests: ${insights.interests.take(5).join(', ')}
- Core values: ${insights.values.take(3).join(', ')}

RECENT RELEVANT MEMORIES:
$recentMemories

PERSONALITY INSIGHTS:
- Strengths: ${insights.strengths.take(2).join(', ')}
- Communication style: ${_getCommunicationStyle(traits)}
- Emotional state: ${EnhancedEmotionDetector.generateEmotionSummary(emotionResult)}

RECOMMENDATIONS:
${insights.recommendations.take(2).join('. ')}.

Instructions: Use this context to provide personalized, empathetic responses that align with the user's personality, emotional state, and current situation. Adapt your communication style to match their personality traits.
""";
    });
  }

  // Helper methods
  Future<String> _inferCurrentMood(List<HiveMemory> memories) async {
    if (memories.isEmpty) return "neutral";

    final recentMemory = memories.first;
    final emotionalWeight = recentMemory.emotionalWeight;

    if (emotionalWeight >= 0.8) return "very positive";
    if (emotionalWeight >= 0.65) return "positive";
    if (emotionalWeight >= 0.35) return "neutral";
    if (emotionalWeight >= 0.2) return "negative";
    return "very negative";
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  List<String> _getTopItems(List<String> items, int count) {
    final frequency = <String, int>{};
    for (final item in items) {
      frequency[item] = (frequency[item] ?? 0) + 1;
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(count).map((e) => e.key).toList();
  }

  Future<String> _generatePersonalityInsights(List<HiveMemory> memories) async {
    final traits = await analyzePersonalityTraits(memories);
    final insights = <String>[];

    if (traits['extraversion']! > 0.6) {
      insights.add("User enjoys social interactions and external stimulation");
    } else if (traits['extraversion']! < 0.4) {
      insights.add("User prefers quieter, more introspective activities");
    }

    if (traits['openness']! > 0.6) {
      insights.add("User is open to new experiences and creative activities");
    }

    if (traits['conscientiousness']! > 0.6) {
      insights.add("User values structure, planning, and achievement");
    }

    if (traits['neuroticism']! > 0.6) {
      insights.add("User may be experiencing emotional fluctuations");
    }

    if (traits['agreeableness']! > 0.6) {
      insights.add("User tends to be cooperative and considerate of others");
    }

    return insights.isEmpty ? "Building personality profile..." : insights.join('; ');
  }

  /// Get emotion polarity (-1 to 1, negative to positive)
  double _getEmotionPolarity(String emotion) {
    const positiveEmotions = ['happy', 'excited', 'calm', 'confident', 'love', 'grateful'];
    const negativeEmotions = ['sad', 'angry', 'anxious', 'frustrated', 'disappointed'];
    
    if (positiveEmotions.contains(emotion)) {
      return 1.0;
    } else if (negativeEmotions.contains(emotion)) {
      return -1.0;
    } else {
      return 0.0; // Neutral
    }
  }

  /// Get communication style based on personality traits
  String _getCommunicationStyle(Map<String, double> traits) {
    final extraversion = traits['extraversion'] ?? 0.5;
    final agreeableness = traits['agreeableness'] ?? 0.5;
    final openness = traits['openness'] ?? 0.5;
    
    if (extraversion > 0.7 && agreeableness > 0.7) {
      return 'Warm and engaging';
    } else if (extraversion < 0.3 && openness > 0.7) {
      return 'Thoughtful and reflective';
    } else if (agreeableness > 0.7) {
      return 'Supportive and empathetic';
    } else if (openness > 0.7) {
      return 'Curious and explorative';
    } else if (extraversion > 0.7) {
      return 'Direct and energetic';
    } else {
      return 'Balanced and adaptable';
    }
  }

  // Find similar memories berdasarkan content similarity
  Future<List<HiveMemory>> findSimilarMemories(
    HiveMemory targetMemory, 
    List<HiveMemory> allMemories,
    {double threshold = 0.3, int limit = 5}
  ) async {
    final similarMemories = <(HiveMemory, double)>[];

    for (final memory in allMemories) {
      if (memory.id == targetMemory.id) continue;

      final similarity = _calculateSimilarity(targetMemory, memory);
      if (similarity >= threshold) {
        similarMemories.add((memory, similarity));
      }
    }

    // Sort by similarity dan return top results
    similarMemories.sort((a, b) => b.$2.compareTo(a.$2));
    return similarMemories.take(limit).map((item) => item.$1).toList();
  }

  double _calculateSimilarity(HiveMemory memory1, HiveMemory memory2) {
    double similarity = 0.0;

    // Context similarity (50% weight)
    final commonContexts = memory1.contexts.toSet().intersection(memory2.contexts.toSet());
    final totalContexts = memory1.contexts.toSet().union(memory2.contexts.toSet());
    if (totalContexts.isNotEmpty) {
      similarity += (commonContexts.length / totalContexts.length) * 0.5;
    }

    // Tag similarity (30% weight)
    final commonTags = memory1.tags.toSet().intersection(memory2.tags.toSet());
    final totalTags = memory1.tags.toSet().union(memory2.tags.toSet());
    if (totalTags.isNotEmpty) {
      similarity += (commonTags.length / totalTags.length) * 0.3;
    }

    // Emotional similarity (20% weight)
    final emotionalDiff = (memory1.emotionalWeight - memory2.emotionalWeight).abs();
    similarity += (1.0 - emotionalDiff) * 0.2;

    return similarity.clamp(0.0, 1.0);
  }
}
