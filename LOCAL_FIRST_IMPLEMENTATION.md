# IMPLEMENTATION GUIDE: LOCAL-FIRST LITTLE BRAIN

## 🧠 STEP-BY-STEP IMPLEMENTATION

### LANGKAH 1: ENHANCED HIVE MODELS

```dart
// lib/features/little_brain/data/models/local_models.dart
import 'package:hive/hive.dart';

part 'local_models.g.dart';

@HiveType(typeId: 10)
class LocalLittleBrainMemory extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String type; // personality_trait, preference, etc.
  
  @HiveField(2)
  final Map<String, dynamic> content;
  
  @HiveField(3)
  final List<String> tags;
  
  @HiveField(4)
  final double confidenceScore;
  
  @HiveField(5)
  final DateTime createdAt;
  
  @HiveField(6)
  final DateTime updatedAt;
  
  @HiveField(7)
  final List<double>? localEmbedding; // Simple embedding untuk similarity
  
  @HiveField(8)
  final bool needsSync;
  
  @HiveField(9)
  final String? sourceConversationId; // Reference ke conversation
  
  @HiveField(10)
  final Map<String, dynamic>? metadata;
  
  LocalLittleBrainMemory({
    required this.id,
    required this.type,
    required this.content,
    required this.tags,
    required this.confidenceScore,
    required this.createdAt,
    required this.updatedAt,
    this.localEmbedding,
    this.needsSync = false,
    this.sourceConversationId,
    this.metadata,
  });

  // Local methods untuk analysis
  bool get isHighConfidence => confidenceScore > 0.7;
  bool get isRecent => DateTime.now().difference(updatedAt).inDays < 30;
  
  // Similarity check dengan embedding sederhana
  double similarityTo(LocalLittleBrainMemory other) {
    if (localEmbedding == null || other.localEmbedding == null) return 0.0;
    return _cosineSimilarity(localEmbedding!, other.localEmbedding!);
  }
  
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length && i < b.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}

@HiveType(typeId: 11)
class LocalPersonalityModel extends HiveObject {
  @HiveField(0)
  final String userId;
  
  @HiveField(1)
  final Map<String, double> traits; // Big 5, MBTI traits, etc.
  
  @HiveField(2)
  final Map<String, dynamic> behavioralPatterns;
  
  @HiveField(3)
  final List<String> preferences;
  
  @HiveField(4)
  final DateTime lastUpdated;
  
  @HiveField(5)
  final int trainingDataCount;
  
  @HiveField(6)
  final double overallConfidence;
  
  @HiveField(7)
  final Map<String, List<String>> traitEvidence; // Evidence untuk setiap trait
  
  LocalPersonalityModel({
    required this.userId,
    required this.traits,
    required this.behavioralPatterns,
    required this.preferences,
    required this.lastUpdated,
    required this.trainingDataCount,
    required this.overallConfidence,
    required this.traitEvidence,
  });
  
  // Computed properties
  bool get isWellTrained => trainingDataCount >= 50 && overallConfidence > 0.7;
  
  List<String> get dominantTraits => traits.entries
      .where((e) => e.value > 0.6)
      .map((e) => e.key)
      .take(5)
      .toList();
  
  Map<String, String> get personalityInsights {
    final insights = <String, String>{};
    
    traits.forEach((trait, score) {
      if (score > 0.7) {
        insights[trait] = 'Tinggi (${(score * 100).toStringAsFixed(0)}%)';
      } else if (score > 0.3) {
        insights[trait] = 'Sedang (${(score * 100).toStringAsFixed(0)}%)';
      } else {
        insights[trait] = 'Rendah (${(score * 100).toStringAsFixed(0)}%)';
      }
    });
    
    return insights;
  }
}

@HiveType(typeId: 12)
class LocalConversation extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String? title;
  
  @HiveField(2)
  final List<LocalMessage> messages;
  
  @HiveField(3)
  final DateTime createdAt;
  
  @HiveField(4)
  final DateTime updatedAt;
  
  @HiveField(5)
  final Map<String, dynamic>? extractedContext;
  
  @HiveField(6)
  final bool needsSync;
  
  LocalConversation({
    required this.id,
    this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.extractedContext,
    this.needsSync = false,
  });
}

@HiveType(typeId: 13)
class LocalMessage extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String role; // 'user', 'assistant'
  
  @HiveField(2)
  final String content;
  
  @HiveField(3)
  final DateTime timestamp;
  
  @HiveField(4)
  final Map<String, dynamic>? extractedContext;
  
  @HiveField(5)
  final List<String>? generatedTags;
  
  LocalMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.extractedContext,
    this.generatedTags,
  });
}
```

### LANGKAH 2: LOCAL AI SERVICE

```dart
// lib/features/little_brain/data/services/local_ai_service.dart
class LocalAIService {
  static const String _aiCacheBox = 'ai_response_cache';
  static const String _embeddingCacheBox = 'embedding_cache';
  
  // Simple local embedding menggunakan TF-IDF concept
  List<double> generateSimpleEmbedding(String text) {
    final words = text.toLowerCase().split(RegExp(r'\W+'));
    final embedding = List<double>.filled(100, 0.0); // 100-dimensional
    
    // Simple word frequency based embedding
    final wordFreq = <String, int>{};
    for (final word in words) {
      wordFreq[word] = (wordFreq[word] ?? 0) + 1;
    }
    
    // Map words to embedding dimensions (simplified)
    wordFreq.forEach((word, freq) {
      final hash = word.hashCode.abs() % 100;
      embedding[hash] += freq / words.length;
    });
    
    return embedding;
  }
  
  // Local pattern analysis
  Future<Map<String, dynamic>> analyzePatterns(String userInput) async {
    final memoryBox = await Hive.openBox<LocalLittleBrainMemory>('memories');
    final memories = memoryBox.values.toList();
    
    // Emotion detection (simple keyword based)
    final emotions = _detectEmotions(userInput);
    
    // Pattern recognition
    final patterns = _findSimilarMemories(userInput, memories);
    
    // Confidence calculation
    final confidence = _calculateConfidence(userInput, memories);
    
    return {
      'detected_emotions': emotions,
      'similar_memories': patterns,
      'confidence_score': confidence,
      'suggested_tags': _generateTags(userInput, emotions),
      'personality_updates': _suggestPersonalityUpdates(userInput, emotions),
    };
  }
  
  List<String> _detectEmotions(String text) {
    final emotionKeywords = {
      'happy': ['senang', 'gembira', 'bahagia', 'suka', 'excited'],
      'sad': ['sedih', 'kecewa', 'galau', 'down', 'hancur'],
      'angry': ['marah', 'kesal', 'jengkel', 'bete', 'dongkol'],
      'anxious': ['cemas', 'khawatir', 'takut', 'nervous', 'gelisah'],
      'confident': ['yakin', 'percaya diri', 'optimis', 'mantap'],
      'grateful': ['syukur', 'terima kasih', 'grateful', 'beruntung'],
    };
    
    final detectedEmotions = <String>[];
    final lowerText = text.toLowerCase();
    
    emotionKeywords.forEach((emotion, keywords) {
      if (keywords.any((keyword) => lowerText.contains(keyword))) {
        detectedEmotions.add(emotion);
      }
    });
    
    return detectedEmotions;
  }
  
  List<LocalLittleBrainMemory> _findSimilarMemories(
    String input, 
    List<LocalLittleBrainMemory> memories
  ) {
    final inputEmbedding = generateSimpleEmbedding(input);
    final similarities = <MapEntry<LocalLittleBrainMemory, double>>[];
    
    for (final memory in memories) {
      if (memory.localEmbedding != null) {
        final similarity = _cosineSimilarity(inputEmbedding, memory.localEmbedding!);
        if (similarity > 0.3) { // Threshold
          similarities.add(MapEntry(memory, similarity));
        }
      }
    }
    
    similarities.sort((a, b) => b.value.compareTo(a.value));
    return similarities.take(5).map((e) => e.key).toList();
  }
  
  double _calculateConfidence(String input, List<LocalLittleBrainMemory> memories) {
    if (memories.isEmpty) return 0.1;
    
    final recentMemories = memories.where((m) => m.isRecent).length;
    final highConfidenceMemories = memories.where((m) => m.isHighConfidence).length;
    
    final recencyScore = (recentMemories / memories.length) * 0.5;
    final confidenceScore = (highConfidenceMemories / memories.length) * 0.5;
    
    return (recencyScore + confidenceScore).clamp(0.1, 1.0);
  }
  
  List<String> _generateTags(String input, List<String> emotions) {
    final tags = <String>[];
    
    // Add emotion tags
    tags.addAll(emotions);
    
    // Simple keyword extraction
    final words = input.toLowerCase().split(RegExp(r'\W+'));
    final importantWords = words.where((word) => 
      word.length > 3 && 
      !['yang', 'adalah', 'dengan', 'untuk', 'dari', 'akan', 'pada'].contains(word)
    ).take(5);
    
    tags.addAll(importantWords);
    
    return tags.toSet().toList(); // Remove duplicates
  }
  
  Map<String, double> _suggestPersonalityUpdates(String input, List<String> emotions) {
    final updates = <String, double>{};
    
    // Simple trait inference based on emotions and content
    if (emotions.contains('happy') || emotions.contains('grateful')) {
      updates['optimism'] = 0.1;
      updates['positive_affect'] = 0.1;
    }
    
    if (emotions.contains('anxious') || emotions.contains('sad')) {
      updates['neuroticism'] = 0.1;
      updates['emotional_stability'] = -0.05;
    }
    
    // Content-based trait inference
    final lowerInput = input.toLowerCase();
    if (lowerInput.contains('help') || lowerInput.contains('tolong')) {
      updates['agreeableness'] = 0.05;
    }
    
    if (lowerInput.contains('plan') || lowerInput.contains('rencana')) {
      updates['conscientiousness'] = 0.05;
    }
    
    return updates;
  }
  
  double _cosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    
    for (int i = 0; i < a.length && i < b.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }
}
```

### LANGKAH 3: LOCAL LITTLE BRAIN REPOSITORY

```dart
// lib/features/little_brain/data/repositories/local_little_brain_repository.dart
class LocalLittleBrainRepository implements LittleBrainRepository {
  static const String _memoriesBox = 'little_brain_memories';
  static const String _personalityBox = 'personality_model';
  static const String _conversationsBox = 'conversations';
  
  final LocalAIService _localAI = LocalAIService();
  
  @override
  Future<Either<Failure, List<LittleBrainMemory>>> getUserMemories(
    String userId, {MemoryType? type}
  ) async {
    try {
      final box = await Hive.openBox<LocalLittleBrainMemory>(_memoriesBox);
      var memories = box.values.toList();
      
      if (type != null) {
        memories = memories.where((m) => m.type == type.name).toList();
      }
      
      // Convert ke domain entities
      final domainMemories = memories.map((local) => LittleBrainMemory(
        id: local.id,
        userId: userId,
        type: MemoryType.values.firstWhere((t) => t.name == local.type),
        content: local.content,
        tags: local.tags,
        embedding: local.localEmbedding ?? [],
        confidenceScore: local.confidenceScore,
        createdAt: local.createdAt,
        updatedAt: local.updatedAt,
        version: 1,
      )).toList();
      
      return Right(domainMemories);
    } catch (e) {
      return Left(CacheFailure('Failed to get local memories: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, LittleBrainMemory>> createMemory(LittleBrainMemory memory) async {
    try {
      final box = await Hive.openBox<LocalLittleBrainMemory>(_memoriesBox);
      
      // Generate local embedding
      final contentText = memory.content.toString();
      final embedding = _localAI.generateSimpleEmbedding(contentText);
      
      final localMemory = LocalLittleBrainMemory(
        id: memory.id,
        type: memory.type.name,
        content: memory.content,
        tags: memory.tags,
        confidenceScore: memory.confidenceScore,
        createdAt: memory.createdAt,
        updatedAt: memory.updatedAt,
        localEmbedding: embedding,
        needsSync: true, // Mark for sync
      );
      
      await box.put(memory.id, localMemory);
      
      // Update personality model based on new memory
      await _updatePersonalityModel(memory.userId, memory);
      
      return Right(memory);
    } catch (e) {
      return Left(CacheFailure('Failed to create memory: ${e.toString()}'));
    }
  }
  
  @override
  Future<Either<Failure, PersonalityModel>> getPersonalityModel(String userId) async {
    try {
      final box = await Hive.openBox<LocalPersonalityModel>(_personalityBox);
      final localModel = box.get(userId);
      
      if (localModel == null) {
        // Create initial personality model
        return await _createInitialPersonalityModel(userId);
      }
      
      final domainModel = PersonalityModel(
        id: userId,
        userId: userId,
        modelVersion: '1.0',
        personalityMatrix: localModel.traits,
        confidenceScores: {'overall': localModel.overallConfidence},
        lastUpdated: localModel.lastUpdated,
        trainingDataCount: localModel.trainingDataCount,
        traits: localModel.dominantTraits,
        behavioralPatterns: localModel.behavioralPatterns,
      );
      
      return Right(domainModel);
    } catch (e) {
      return Left(CacheFailure('Failed to get personality model: ${e.toString()}'));
    }
  }
  
  Future<Either<Failure, PersonalityModel>> _createInitialPersonalityModel(String userId) async {
    try {
      final initialModel = LocalPersonalityModel(
        userId: userId,
        traits: {
          'openness': 0.5,
          'conscientiousness': 0.5,
          'extraversion': 0.5,
          'agreeableness': 0.5,
          'neuroticism': 0.5,
        },
        behavioralPatterns: {},
        preferences: [],
        lastUpdated: DateTime.now(),
        trainingDataCount: 0,
        overallConfidence: 0.1,
        traitEvidence: {},
      );
      
      final box = await Hive.openBox<LocalPersonalityModel>(_personalityBox);
      await box.put(userId, initialModel);
      
      return await getPersonalityModel(userId);
    } catch (e) {
      return Left(CacheFailure('Failed to create initial personality model: ${e.toString()}'));
    }
  }
  
  Future<void> _updatePersonalityModel(String userId, LittleBrainMemory memory) async {
    try {
      final box = await Hive.openBox<LocalPersonalityModel>(_personalityBox);
      final currentModel = box.get(userId);
      
      if (currentModel == null) return;
      
      // Simple personality update based on memory content
      final updates = _localAI._suggestPersonalityUpdates(
        memory.content.toString(), 
        memory.tags
      );
      
      final updatedTraits = Map<String, double>.from(currentModel.traits);
      updates.forEach((trait, delta) {
        updatedTraits[trait] = (updatedTraits[trait] ?? 0.5) + delta;
        updatedTraits[trait] = updatedTraits[trait]!.clamp(0.0, 1.0);
      });
      
      final updatedModel = LocalPersonalityModel(
        userId: userId,
        traits: updatedTraits,
        behavioralPatterns: currentModel.behavioralPatterns,
        preferences: currentModel.preferences,
        lastUpdated: DateTime.now(),
        trainingDataCount: currentModel.trainingDataCount + 1,
        overallConfidence: (currentModel.overallConfidence + 0.01).clamp(0.0, 1.0),
        traitEvidence: currentModel.traitEvidence,
      );
      
      await box.put(userId, updatedModel);
    } catch (e) {
      print('Failed to update personality model: $e');
    }
  }
  
  // Process user input locally
  Future<Either<Failure, Map<String, dynamic>>> processUserInput(
    String userId, 
    String input
  ) async {
    try {
      // Analyze locally first
      final localAnalysis = await _localAI.analyzePatterns(input);
      
      // Create memory if confidence is high enough
      if (localAnalysis['confidence_score'] > 0.5) {
        final memory = LittleBrainMemory(
          id: const Uuid().v4(),
          userId: userId,
          type: MemoryType.communicationStyle, // Default type
          content: {
            'input': input,
            'analysis': localAnalysis,
          },
          tags: localAnalysis['suggested_tags'],
          embedding: _localAI.generateSimpleEmbedding(input),
          confidenceScore: localAnalysis['confidence_score'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          version: 1,
        );
        
        await createMemory(memory);
      }
      
      return Right(localAnalysis);
    } catch (e) {
      return Left(CacheFailure('Failed to process input: ${e.toString()}'));
    }
  }
}
```

### LANGKAH 4: INTEGRATION KE EXISTING SYSTEM

```dart
// lib/core/injection/injection.dart - Update DI
@module
abstract class RegisterModule {
  // ...existing code...
  
  @singleton
  LocalLittleBrainRepository localLittleBrainRepository() {
    return LocalLittleBrainRepository();
  }
  
  @singleton
  LocalAIService localAIService() {
    return LocalAIService();
  }
}

// lib/features/little_brain/presentation/bloc/little_brain_bloc.dart - Update BLoC
class LittleBrainBloc extends Bloc<LittleBrainEvent, LittleBrainState> {
  final LocalLittleBrainRepository _localRepository;
  
  LittleBrainBloc({required LocalLittleBrainRepository localRepository})
      : _localRepository = localRepository,
        super(LittleBrainInitial()) {
    on<LoadLittleBrainData>(_onLoadLittleBrainData);
    on<CreateMemoryEvent>(_onCreateMemory);
    on<ProcessUserInputEvent>(_onProcessUserInput);
  }
  
  Future<void> _onProcessUserInput(
    ProcessUserInputEvent event,
    Emitter<LittleBrainState> emit,
  ) async {
    emit(LittleBrainLoading());
    
    final result = await _localRepository.processUserInput(
      event.userId,
      event.input,
    );
    
    result.fold(
      (failure) => emit(LittleBrainError(message: failure.message)),
      (analysis) => emit(LittleBrainInputProcessed(analysis: analysis)),
    );
  }
}
```

**Hasil: Little Brain yang berjalan 100% lokal dengan sync minimal ke server!** 🧠✨

Mau lanjut implement langkah selanjutnya?
