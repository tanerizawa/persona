import 'dart:math' as math;

/// Enhanced emotion detection dengan support multi-language dan context awareness
class EnhancedEmotionDetector {
  static const Map<String, EmotionConfig> emotionConfigs = {
    'happy': EmotionConfig(
      keywords: [
        // Indonesian
        'senang', 'gembira', 'bahagia', 'riang', 'ceria', 'sukacita', 'girang',
        'antusias', 'semangat', 'excited', 'bangga', 'puas', 'lega', 'syukur',
        // English
        'happy', 'joyful', 'cheerful', 'delighted', 'pleased', 'content', 'glad',
        'excited', 'thrilled', 'elated', 'ecstatic', 'overjoyed', 'euphoric',
        // Expressions
        '😊', '😄', '😃', '🥳', '🎉', '👏', 'haha', 'hehe', 'yeay', 'yay'
      ],
      intensity: 0.7,
      contextBoost: {
        'achievement': 0.3,
        'social': 0.2,
        'hobby': 0.2,
        'family': 0.25,
      },
    ),
    
    'sad': EmotionConfig(
      keywords: [
        // Indonesian
        'sedih', 'kecewa', 'galau', 'murung', 'patah hati', 'hancur', 'terpuruk',
        'down', 'depresi', 'frustasi', 'putus asa', 'nelangsa', 'duka',
        // English
        'sad', 'disappointed', 'heartbroken', 'depressed', 'down', 'upset',
        'devastated', 'crushed', 'miserable', 'melancholy', 'blue', 'gloomy',
        // Expressions
        '😢', '😭', '💔', '😞', '☹️', 'huhu', 'sob', 'cry'
      ],
      intensity: 0.3,
      contextBoost: {
        'relationship': 0.3,
        'work': 0.2,
        'health': 0.25,
        'family': 0.3,
      },
    ),
    
    'angry': EmotionConfig(
      keywords: [
        // Indonesian
        'marah', 'kesal', 'jengkel', 'dongkol', 'geram', 'murka', 'berang',
        'sebel', 'bete', 'annoyed', 'irritated', 'furious', 'rage', 'mad',
        // English
        'angry', 'furious', 'mad', 'irritated', 'annoyed', 'frustrated',
        'outraged', 'livid', 'enraged', 'irate', 'pissed', 'fed up',
        // Expressions
        '😠', '😡', '🤬', '💢', 'grr', 'argh', 'ugh'
      ],
      intensity: 0.2,
      contextBoost: {
        'work': 0.3,
        'traffic': 0.25,
        'technology': 0.2,
        'social': 0.25,
      },
    ),
    
    'anxious': EmotionConfig(
      keywords: [
        // Indonesian
        'cemas', 'khawatir', 'gelisah', 'panik', 'takut', 'deg-degan', 'grogi',
        'nervous', 'tegang', 'stress', 'overthinking', 'was-was', 'resah',
        // English
        'anxious', 'worried', 'nervous', 'stressed', 'tense', 'panicked',
        'concerned', 'uneasy', 'restless', 'agitated', 'jittery', 'overwhelmed',
        // Expressions
        '😰', '😥', '😟', '🥺', '😬', 'omg', 'aduh', 'waduh'
      ],
      intensity: 0.25,
      contextBoost: {
        'work': 0.3,
        'health': 0.35,
        'exam': 0.4,
        'deadline': 0.35,
      },
    ),
    
    'calm': EmotionConfig(
      keywords: [
        // Indonesian
        'tenang', 'rileks', 'santai', 'damai', 'kalem', 'nyaman', 'sejuk',
        'peaceful', 'cool', 'chill', 'adem', 'teduh', 'hening',
        // English
        'calm', 'peaceful', 'relaxed', 'serene', 'tranquil', 'composed',
        'zen', 'chill', 'cool', 'mellow', 'laid-back', 'at ease',
        // Expressions
        '😌', '🧘', '☺️', '😇', 'ahh', 'hmm'
      ],
      intensity: 0.6,
      contextBoost: {
        'meditation': 0.4,
        'nature': 0.3,
        'hobby': 0.2,
        'vacation': 0.35,
      },
    ),
    
    'confident': EmotionConfig(
      keywords: [
        // Indonesian
        'percaya diri', 'yakin', 'optimis', 'mantap', 'berani', 'pede',
        'kuat', 'determined', 'siap', 'confident', 'bold', 'teguh',
        // English
        'confident', 'sure', 'certain', 'optimistic', 'determined', 'bold',
        'assured', 'self-assured', 'positive', 'strong', 'brave', 'fearless',
        // Expressions
        '💪', '🔥', '⭐', '✨', 'yes!', 'let\'s go', 'siap!'
      ],
      intensity: 0.8,
      contextBoost: {
        'achievement': 0.4,
        'presentation': 0.35,
        'challenge': 0.3,
        'goal': 0.3,
      },
    ),
    
    'love': EmotionConfig(
      keywords: [
        // Indonesian
        'cinta', 'sayang', 'kasih', 'rindu', 'kangen', 'romantis', 'mesra',
        'loved', 'beloved', 'dear', 'honey', 'sweetheart', 'darling',
        // English
        'love', 'adore', 'cherish', 'treasure', 'romantic', 'affection',
        'devoted', 'passionate', 'intimate', 'tender', 'caring', 'sweet',
        // Expressions
        '❤️', '💕', '💖', '💗', '😍', '🥰', '😘', 'xoxo'
      ],
      intensity: 0.85,
      contextBoost: {
        'relationship': 0.5,
        'family': 0.4,
        'anniversary': 0.4,
        'valentine': 0.5,
      },
    ),
    
    'grateful': EmotionConfig(
      keywords: [
        // Indonesian
        'syukur', 'terima kasih', 'bersyukur', 'grateful', 'thanks', 'makasih',
        'appreciate', 'blessed', 'berkah', 'anugerah', 'berkat', 'nikmat',
        // English
        'grateful', 'thankful', 'appreciative', 'blessed', 'fortunate',
        'honored', 'privileged', 'indebted', 'obliged', 'much appreciated',
        // Expressions
        '🙏', '🤲', '😇', 'alhamdulillah', 'thank god', 'puji tuhan'
      ],
      intensity: 0.75,
      contextBoost: {
        'family': 0.3,
        'achievement': 0.3,
        'health': 0.35,
        'spiritual': 0.4,
      },
    ),
  };

  /// Detect emotions from text with context awareness
  static EmotionResult detectEmotions(String text, {List<String>? contexts}) {
    final detectedEmotions = <DetectedEmotion>[];
    final lowerText = text.toLowerCase();
    
    for (final entry in emotionConfigs.entries) {
      final emotionName = entry.key;
      final config = entry.value;
      
      double confidence = 0.0;
      int matchCount = 0;
      
      // Check for keyword matches
      for (final keyword in config.keywords) {
        if (lowerText.contains(keyword.toLowerCase())) {
          matchCount++;
          confidence += _calculateKeywordWeight(keyword, text);
        }
      }
      
      if (matchCount > 0) {
        // Base confidence from keyword matches
        confidence = (confidence / config.keywords.length).clamp(0.0, 1.0);
        
        // Apply context boost
        if (contexts != null) {
          confidence = _applyContextBoost(confidence, config, contexts);
        }
        
        // Apply intensity modifier
        confidence = _applyIntensityModifier(confidence, lowerText);
        
        // Apply negation detection
        confidence = _applyNegationDetection(confidence, text, emotionName);
        
        if (confidence > 0.1) { // Minimum threshold
          detectedEmotions.add(DetectedEmotion(
            emotion: emotionName,
            confidence: confidence,
            matchCount: matchCount,
          ));
        }
      }
    }
    
    // Sort by confidence and return top emotions
    detectedEmotions.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    return EmotionResult(
      emotions: detectedEmotions.take(3).toList(), // Top 3 emotions
      primaryEmotion: detectedEmotions.isNotEmpty ? detectedEmotions.first.emotion : 'neutral',
      overallConfidence: detectedEmotions.isNotEmpty 
          ? detectedEmotions.first.confidence 
          : 0.0,
      emotionalComplexity: detectedEmotions.length,
    );
  }

  /// Calculate weight of keyword based on its specificity
  static double _calculateKeywordWeight(String keyword, String text) {
    // Longer, more specific keywords get higher weight
    double weight = math.min(1.0, keyword.length / 10.0);
    
    // Emoji and expressions get bonus weight
    if (keyword.contains('�') || keyword.contains('🔥') || keyword.contains('❤️')) {
      weight += 0.3;
    }
    
    // Exact word match gets bonus
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    if (words.contains(keyword.toLowerCase())) {
      weight += 0.2;
    }
    
    return weight.clamp(0.1, 1.0);
  }

  /// Apply context boost to confidence
  static double _applyContextBoost(double confidence, EmotionConfig config, List<String> contexts) {
    double boost = 0.0;
    
    for (final context in contexts) {
      final contextKey = context.toLowerCase().replaceAll('context:', '');
      final contextBoost = config.contextBoost[contextKey];
      if (contextBoost != null) {
        boost = math.max(boost, contextBoost);
      }
    }
    
    return (confidence + boost).clamp(0.0, 1.0);
  }

  /// Apply intensity modifiers based on text patterns
  static double _applyIntensityModifier(double confidence, String lowerText) {
    // Intensity amplifiers
    final intensifiers = ['very', 'really', 'extremely', 'super', 'totally', 'completely',
                         'sangat', 'sekali', 'banget', 'benar-benar', 'sungguh', 'amat'];
    
    for (final intensifier in intensifiers) {
      if (lowerText.contains(intensifier)) {
        confidence = math.min(1.0, confidence * 1.3);
        break;
      }
    }
    
    // Diminishers
    final diminishers = ['slightly', 'somewhat', 'a bit', 'kinda', 'sort of',
                        'agak', 'sedikit', 'lumayan', 'cukup'];
    
    for (final diminisher in diminishers) {
      if (lowerText.contains(diminisher)) {
        confidence = confidence * 0.7;
        break;
      }
    }
    
    // Capital letters and exclamation marks
    final hasCapitals = lowerText != lowerText;
    final hasExclamation = lowerText.contains('!');
    
    if (hasCapitals || hasExclamation) {
      confidence = math.min(1.0, confidence * 1.2);
    }
    
    return confidence;
  }

  /// Detect negation patterns that might reverse emotion
  static double _applyNegationDetection(double confidence, String text, String emotion) {
    final negationWords = ['not', 'never', 'no', 'cannot', 'can\'t', 'won\'t', 'don\'t',
                          'tidak', 'bukan', 'tak', 'gak', 'nggak', 'enggak'];
    
    final lowerText = text.toLowerCase();
    final words = lowerText.split(RegExp(r'\W+'));
    
    for (int i = 0; i < words.length - 1; i++) {
      if (negationWords.contains(words[i])) {
        // Check if negation is close to emotion keywords
        final nextFewWords = words.skip(i + 1).take(3).join(' ');
        final config = emotionConfigs[emotion];
        
        if (config != null) {
          for (final keyword in config.keywords) {
            if (nextFewWords.contains(keyword.toLowerCase())) {
              return confidence * 0.3; // Reduce confidence significantly
            }
          }
        }
      }
    }
    
    return confidence;
  }

  /// Get emotional polarity (-1 to 1, negative to positive)
  static double calculateEmotionalPolarity(EmotionResult result) {
    if (result.emotions.isEmpty) return 0.0;
    
    const positiveEmotions = ['happy', 'confident', 'love', 'grateful', 'calm'];
    const negativeEmotions = ['sad', 'angry', 'anxious'];
    
    double polarity = 0.0;
    double totalWeight = 0.0;
    
    for (final emotion in result.emotions) {
      final weight = emotion.confidence;
      totalWeight += weight;
      
      if (positiveEmotions.contains(emotion.emotion)) {
        polarity += weight;
      } else if (negativeEmotions.contains(emotion.emotion)) {
        polarity -= weight;
      }
    }
    
    return totalWeight > 0 ? polarity / totalWeight : 0.0;
  }

  /// Generate emotion summary for Little Brain
  static String generateEmotionSummary(EmotionResult result) {
    if (result.emotions.isEmpty) {
      return 'Neutral emotional state detected.';
    }
    
    final primary = result.emotions.first;
    final polarity = calculateEmotionalPolarity(result);
    
    String summary = 'Primary emotion: ${primary.emotion} (${(primary.confidence * 100).toInt()}% confidence)';
    
    if (result.emotions.length > 1) {
      final secondary = result.emotions[1];
      summary += ', with ${secondary.emotion} undertones';
    }
    
    if (polarity > 0.3) {
      summary += '. Overall positive emotional state.';
    } else if (polarity < -0.3) {
      summary += '. Overall negative emotional state.';
    } else {
      summary += '. Emotionally balanced state.';
    }
    
    return summary;
  }
}

/// Configuration for each emotion type
class EmotionConfig {
  final List<String> keywords;
  final double intensity;
  final Map<String, double> contextBoost;
  
  const EmotionConfig({
    required this.keywords,
    required this.intensity,
    required this.contextBoost,
  });
}

/// Result of emotion detection
class EmotionResult {
  final List<DetectedEmotion> emotions;
  final String primaryEmotion;
  final double overallConfidence;
  final int emotionalComplexity;
  
  const EmotionResult({
    required this.emotions,
    required this.primaryEmotion,
    required this.overallConfidence,
    required this.emotionalComplexity,
  });
  
  bool get hasStrongEmotion => overallConfidence > 0.7;
  bool get hasComplexEmotions => emotionalComplexity > 2;
  bool get isNeutral => emotions.isEmpty || overallConfidence < 0.2;
}

/// Individual detected emotion with confidence
class DetectedEmotion {
  final String emotion;
  final double confidence;
  final int matchCount;
  
  const DetectedEmotion({
    required this.emotion,
    required this.confidence,
    required this.matchCount,
  });
}
