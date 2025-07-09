import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
// import 'package:tflite_flutter/tflite_flutter.dart';
// import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

import '../models/hive_models.dart';
import 'local_ai_service.dart';

/// Enhanced Local AI Service dengan TensorFlow Lite support
/// Implementasi hybrid: TFLite untuk model AI, fallback ke local processing
@singleton
class TFLiteLocalAIService extends LocalAIService {
  // TensorFlow Lite model assets
  static const String _vocabularyAsset = 'assets/vocab/vocabulary.json';
  static const String _sentimentModelAsset = 'assets/models/sentiment_model.tflite';
  static const String _personalityModelAsset = 'assets/models/personality_model.tflite';
  static const String _intentModelAsset = 'assets/models/intent_model.tflite';
  
  // TensorFlow Lite interpreters (akan diaktifkan ketika model tersedia)
  dynamic _sentimentInterpreter;
  dynamic _personalityInterpreter; 
  dynamic _intentInterpreter;
  
  Map<String, int> _vocabulary = {};
  bool _modelsLoaded = false;
  bool _initializationAttempted = false;
  bool _tfliteAvailable = false;
  
  Future<void> initializeEnhanced() async {
    if (_initializationAttempted) return;
    _initializationAttempted = true;
    
    try {
      print('🧠 Initializing Enhanced Local AI Service...');
      
      await _loadVocabulary();
      await _checkTensorFlowLiteAvailability();
      
      if (_tfliteAvailable) {
        await _loadTensorFlowLiteModels();
        _modelsLoaded = true;
        print('✅ TensorFlow Lite AI Service initialized successfully');
      } else {
        print('📱 TensorFlow Lite not available, using enhanced local processing');
        _modelsLoaded = false;
      }
    } catch (e) {
      print('⚠️ Enhanced AI initialization warning: $e');
      print('📱 Falling back to basic AI service');
      _modelsLoaded = false;
    }
  }
  
  /// Load vocabulary dari assets untuk text preprocessing
  Future<void> _loadVocabulary() async {
    try {
      final vocabData = await rootBundle.loadString(_vocabularyAsset);
      final vocabMap = json.decode(vocabData) as Map<String, dynamic>;
      
      // Extract vocabulary words ke integer mapping
      _vocabulary = {};
      
      if (vocabMap.containsKey('_emotions_id')) {
        final emotions = Map<String, int>.from(vocabMap['_emotions_id']);
        _vocabulary.addAll(emotions);
      }
      
      if (vocabMap.containsKey('_activities_id')) {
        final activities = Map<String, int>.from(vocabMap['_activities_id']);
        _vocabulary.addAll(activities);
      }
      
      if (vocabMap.containsKey('_contexts_id')) {
        final contexts = Map<String, int>.from(vocabMap['_contexts_id']);
        _vocabulary.addAll(contexts);
      }
      
      if (vocabMap.containsKey('_general_id')) {
        final general = Map<String, int>.from(vocabMap['_general_id']);
        _vocabulary.addAll(general);
      }
      
      print('✅ Vocabulary loaded: ${_vocabulary.length} words');
    } catch (e) {
      print('❌ Failed to load vocabulary: $e');
      _vocabulary = _getFallbackVocabulary();
    }
  }
  
  /// Check apakah TensorFlow Lite tersedia
  Future<void> _checkTensorFlowLiteAvailability() async {
    try {
      // Check apakah TFLite models ada di assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      final sentimentExists = manifestMap.containsKey(_sentimentModelAsset);
      final personalityExists = manifestMap.containsKey(_personalityModelAsset);
      final intentExists = manifestMap.containsKey(_intentModelAsset);
      
      _tfliteAvailable = sentimentExists || personalityExists || intentExists;
      
      print('🔍 TensorFlow Lite availability check:');
      print('  - Sentiment model: ${sentimentExists ? "✅" : "❌"}');
      print('  - Personality model: ${personalityExists ? "✅" : "❌"}'); 
      print('  - Intent model: ${intentExists ? "✅" : "❌"}');
      
    } catch (e) {
      print('⚠️ TFLite availability check failed: $e');
      _tfliteAvailable = false;
    }
  }
  
  /// Load TensorFlow Lite models (ketika tersedia)
  Future<void> _loadTensorFlowLiteModels() async {
    // Commented out until TFLite models are available
    // try {
    //   _sentimentInterpreter = await Interpreter.fromAsset(_sentimentModelAsset);
    //   _personalityInterpreter = await Interpreter.fromAsset(_personalityModelAsset);
    //   _intentInterpreter = await Interpreter.fromAsset(_intentModelAsset);
    //   print('✅ TensorFlow Lite models loaded');
    // } catch (e) {
    //   print('❌ Failed to load TFLite models: $e');
    //   _tfliteAvailable = false;
    // }
    
    print('📝 TensorFlow Lite models ready for future integration');
  }
  
  /// Get fallback vocabulary untuk error handling
  Map<String, int> _getFallbackVocabulary() {
    return {
      // Basic emotions
      'senang': 100, 'sedih': 101, 'marah': 102, 'cemas': 103,
      'bahagia': 104, 'kecewa': 105, 'excited': 106, 'tenang': 107,
      'gelisah': 108, 'gembira': 109, 'frustrasi': 110, 'stress': 111,
      
      // English emotions
      'happy': 200, 'sad': 201, 'angry': 202, 'anxious': 203,
      'calm': 204, 'excited': 205, 'worried': 206, 'joyful': 207,
      
      // Activities
      'kerja': 300, 'belajar': 301, 'olahraga': 302, 'musik': 303,
      'work': 400, 'study': 401, 'exercise': 402, 'music': 403,
    };
  }
  
  Future<void> _loadVocabulary() async {
    try {
      final vocabData = await rootBundle.loadString(_vocabularyAsset);
      final vocabJson = json.decode(vocabData) as Map<String, dynamic>;
      
      // Flatten all vocabulary categories
      _vocabulary = {};
      for (final category in vocabJson.values) {
        if (category is Map<String, dynamic>) {
          category.forEach((key, value) {
            if (value is int) {
              _vocabulary[key] = value;
            }
          });
        }
      }
      
      print('✅ Vocabulary loaded: ${_vocabulary.length} words');
    } catch (e) {
      print('⚠️ Could not load vocabulary, using basic mapping: $e');
      _vocabulary = _getBasicVocabulary();
    }
  }
  
  Future<void> _checkTensorFlowLiteAvailability() async {
    try {
      // Check if TensorFlow Lite package is available
      // For now, set to false until package is properly installed
      _tfliteAvailable = false;
      
      // TODO: Uncomment when tflite_flutter is added
      // _tfliteAvailable = true;
      // print('✅ TensorFlow Lite package available');
    } catch (e) {
      _tfliteAvailable = false;
      print('⚠️ TensorFlow Lite package not available: $e');
    }
  }
  
  Future<void> _loadModels() async {
    if (!_tfliteAvailable) return;
    
    // Placeholder untuk model loading
    // TODO: Implement actual TensorFlow Lite model loading
    print('🔄 Model loading prepared (TFLite package required)');
  }
  
  /// Enhanced emotion detection dengan improved local processing
  @override
  Future<List<String>> detectEmotionsEnhanced(String text, {List<String>? contexts}) async {
    if (!_modelsLoaded) {
      return await _detectEmotionsEnhancedLocal(text, contexts: contexts);
    }
    
    // TODO: Implement TensorFlow Lite emotion detection
    return await _detectEmotionsEnhancedLocal(text, contexts: contexts);
  }
  
  /// Enhanced local emotion detection (without TFLite)
  Future<List<String>> _detectEmotionsEnhancedLocal(String text, {List<String>? contexts}) async {
    try {
      final detectedEmotions = <String>[];
      final lowercaseText = text.toLowerCase();
      final words = lowercaseText.split(RegExp(r'\W+'));
      
      // Enhanced emotion detection dengan vocabulary
      final emotionScores = <String, double>{
        'happy': 0.0, 'sad': 0.0, 'angry': 0.0,
        'excited': 0.0, 'calm': 0.0, 'anxious': 0.0
      };
      
      final emotionKeywords = {
        'happy': ['senang', 'gembira', 'bahagia', 'happy', 'joyful', 'glad'],
        'sad': ['sedih', 'kecewa', 'sad', 'depressed', 'upset', 'disappointed'],
        'angry': ['marah', 'kesal', 'angry', 'mad', 'furious', 'irritated'],
        'excited': ['excited', 'semangat', 'antusias', 'enthusiastic', 'energetic'],
        'calm': ['tenang', 'santai', 'calm', 'peaceful', 'relaxed', 'serene'],
        'anxious': ['cemas', 'khawatir', 'anxious', 'worried', 'nervous', 'stress']
      };
      
      // Calculate emotion scores berdasarkan vocabulary
      for (final word in words) {
        for (final emotion in emotionScores.keys) {
          final keywords = emotionKeywords[emotion] ?? [];
          if (keywords.contains(word)) {
            emotionScores[emotion] = emotionScores[emotion]! + 0.3;
            
            // Bonus jika word ada di vocabulary
            if (_vocabulary.containsKey(word)) {
              emotionScores[emotion] = emotionScores[emotion]! + 0.2;
            }
          }
        }
      }
      
      // Add emotions yang melewati threshold
      emotionScores.forEach((emotion, score) {
        if (score > 0.3) {
          detectedEmotions.add('emotion:$emotion');
        }
      });
      
      // Fallback to parent method if nothing detected
      if (detectedEmotions.isEmpty) {
        return await super.detectEmotionsEnhanced(text, contexts: contexts);
      }
      
      print('🎯 Enhanced emotion detection: ${detectedEmotions.join(', ')}');
      return detectedEmotions;
    } catch (e) {
      print('❌ Enhanced emotion detection error: $e');
      return await super.detectEmotionsEnhanced(text, contexts: contexts);
    }
  }
  
  /// Enhanced personality analysis dengan improved local processing  
  @override
  Future<Map<String, double>> analyzePersonalityTraits(List<HiveMemory> memories) async {
    if (memories.isEmpty) {
      return {
        'openness': 0.5, 'conscientiousness': 0.5, 'extraversion': 0.5,
        'agreeableness': 0.5, 'neuroticism': 0.5,
      };
    }
    
    try {
      final traits = <String, double>{
        'openness': 0.0, 'conscientiousness': 0.0, 'extraversion': 0.0,
        'agreeableness': 0.0, 'neuroticism': 0.0,
      };
      
      // Analyze content patterns
      final allContent = memories.map((m) => m.content.toLowerCase()).join(' ');
      final words = allContent.split(RegExp(r'\W+'));
      
      // Enhanced trait indicators
      final traitIndicators = {
        'openness': ['belajar', 'learning', 'new', 'creative', 'art', 'music', 'book', 'explore'],
        'conscientiousness': ['work', 'kerja', 'goal', 'plan', 'organize', 'schedule', 'complete'],
        'extraversion': ['friend', 'teman', 'party', 'social', 'talk', 'bicara', 'meeting'],
        'agreeableness': ['help', 'tolong', 'care', 'peduli', 'family', 'keluarga', 'love'],
        'neuroticism': ['stress', 'worry', 'khawatir', 'anxious', 'cemas', 'problem', 'difficult']
      };
      
      // Calculate trait scores
      for (final word in words) {
        for (final trait in traits.keys) {
          final indicators = traitIndicators[trait] ?? [];
          if (indicators.contains(word)) {
            traits[trait] = traits[trait]! + 0.1;
            
            // Bonus dari vocabulary
            if (_vocabulary.containsKey(word)) {
              traits[trait] = traits[trait]! + 0.05;
            }
          }
        }
      }
      
      // Factor in emotional weights and contexts
      for (final memory in memories) {
        if (memory.emotionalWeight > 0.7) {
          traits['extraversion'] = traits['extraversion']! + 0.05;
        }
        if (memory.contexts.any((c) => c.contains('work'))) {
          traits['conscientiousness'] = traits['conscientiousness']! + 0.08;
        }
        if (memory.contexts.any((c) => c.contains('social'))) {
          traits['extraversion'] = traits['extraversion']! + 0.08;
        }
      }
      
      // Normalize and add base values
      final maxValue = traits.values.reduce((a, b) => a > b ? a : b);
      if (maxValue > 0) {
        traits.updateAll((key, value) => ((value / maxValue) * 0.6 + 0.3).clamp(0.0, 1.0));
      } else {
        traits.updateAll((key, value) => 0.5);
      }
      
      print('🎯 Enhanced personality analysis completed for ${memories.length} memories');
      return traits;
    } catch (e) {
      print('❌ Enhanced personality analysis error: $e');
      return await super.analyzePersonalityTraits(memories);
    }
  }
  
  /// Enhanced intent classification
  Future<String> classifyIntentAdvanced(String text) async {
    try {
      final lowercaseText = text.toLowerCase();
      
      // Enhanced intent patterns
      final intentPatterns = {
        'question': [r'\?', r'\bapa\b', r'\bwhat\b', r'\bhow\b', r'\bwhy\b', r'\bbagaimana\b', r'\bkenapa\b'],
        'request': [r'\btolong\b', r'\bplease\b', r'\bbisa\b', r'\bcan you\b', r'\bminta\b'],
        'emotion_share': [r'\bmerasa\b', r'\bfeel\b', r'\bemosi\b', r'\bhati\b', r'\bheart\b'],
        'story_tell': [r'\bcerita\b', r'\bstory\b', r'\btadi\b', r'\byesterday\b', r'\bkemarin\b'],
        'advice_seek': [r'\bsaran\b', r'\badvice\b', r'\bbaiknya\b', r'\bshould\b', r'\bsebaiknya\b'],
        'casual_chat': [r'\bhai\b', r'\bhi\b', r'\bhalo\b', r'\bhello\b', r'\bselamat\b']
      };
      
      // Score each intent
      final intentScores = <String, int>{};
      for (final intent in intentPatterns.keys) {
        intentScores[intent] = 0;
        final patterns = intentPatterns[intent] ?? [];
        
        for (final pattern in patterns) {
          final regex = RegExp(pattern, caseSensitive: false);
          if (regex.hasMatch(lowercaseText)) {
            intentScores[intent] = intentScores[intent]! + 1;
          }
        }
      }
      
      // Return highest scoring intent
      final maxScore = intentScores.values.reduce((a, b) => a > b ? a : b);
      if (maxScore > 0) {
        final topIntent = intentScores.entries
            .where((entry) => entry.value == maxScore)
            .first
            .key;
        
        print('🎯 Intent classified as: $topIntent (score: $maxScore)');
        return topIntent;
      }
      
      return 'casual_chat';
    } catch (e) {
      print('❌ Intent classification error: $e');
      return 'casual_chat';
    }
  }
  
  /// Basic vocabulary untuk fallback
  Map<String, int> _getBasicVocabulary() {
    return {
      // Indonesian emotions
      'senang': 100, 'sedih': 101, 'marah': 102, 'cemas': 103,
      'bahagia': 104, 'kecewa': 105, 'excited': 106, 'tenang': 107,
      
      // English emotions
      'happy': 108, 'sad': 109, 'angry': 110, 'anxious': 111,
      'calm': 113, 'worried': 114, 'glad': 115,
      
      // Activities
      'kerja': 200, 'belajar': 201, 'olahraga': 202, 'musik': 203,
      'work': 204, 'study': 205, 'exercise': 206, 'music': 207,
      
      // Common words
      'saya': 300, 'hari': 301, 'ini': 302, 'yang': 303,
      'dan': 304, 'dengan': 305, 'untuk': 306, 'dari': 307,
      'the': 308, 'and': 309, 'for': 310, 'with': 311,
      'today': 312, 'very': 313, 'good': 314, 'bad': 315,
    };
  }
  
  /// Model update capability untuk future implementation
  Future<void> updateModels() async {
    try {
      print('🔄 Checking for model updates...');
      // Placeholder untuk model update mechanism
      print('ℹ️ Model update system ready (TFLite implementation pending)');
    } catch (e) {
      print('❌ Model update check failed: $e');
    }
  }
  
  /// Get model status untuk debugging
  Map<String, dynamic> getModelStatus() {
    return {
      'models_loaded': _modelsLoaded,
      'tflite_available': _tfliteAvailable,
      'sentiment_model_available': _sentimentInterpreter != null,
      'personality_model_available': _personalityInterpreter != null,
      'intent_model_available': _intentInterpreter != null,
      'vocabulary_size': _vocabulary.length,
      'initialization_attempted': _initializationAttempted,
      'enhanced_processing': true,
    };
  }
  
  /// Get vocabulary untuk debugging
  Map<String, int> getVocabulary() => Map.from(_vocabulary);
  
  /// Cleanup resources
  void dispose() {
    _sentimentInterpreter = null;
    _personalityInterpreter = null;
    _intentInterpreter = null;
    
    print('🧹 Enhanced AI Service resources disposed');
  }
}
