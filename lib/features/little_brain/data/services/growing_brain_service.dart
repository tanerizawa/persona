import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../models/hive_models.dart';

/// Service untuk mensimulasikan pertumbuhan "Little Brain" 
/// berdasarkan interaksi dan pembelajaran user
@singleton
class GrowingBrainService {
  static const String _brainStateBoxName = 'brain_neural_state';
  static const String _learningHistoryBoxName = 'learning_history';
  static const int _maxNeuronConnections = 1000;
  
  Box<Map<String, dynamic>>? _brainStateBox;
  Box<Map<String, dynamic>>? _learningHistoryBox;
  
  Future<void> init() async {
    _brainStateBox ??= await Hive.openBox<Map<String, dynamic>>(_brainStateBoxName);
    _learningHistoryBox ??= await Hive.openBox<Map<String, dynamic>>(_learningHistoryBoxName);
  }
  
  /// Simulate neural growth berdasarkan memory baru
  Future<void> growBrainFromMemory(HiveMemory memory) async {
    await init();
    
    try {
      final currentState = await getCurrentBrainState();
      
      // Analyze memory impact untuk neural growth
      final memoryImpact = await _analyzeMemoryImpact(memory);
      
      // Update neural connections berdasarkan impact
      final updatedState = _simulateNeuralGrowth(currentState, memoryImpact);
      
      // Save updated brain state
      await _saveBrainState(updatedState);
      
      // Log brain development milestone
      await _checkDevelopmentMilestones(updatedState, memory);
      
      print('🧠 Brain growth processed for memory: ${memory.id}');
    } catch (e) {
      print('❌ Brain growth error: $e');
    }
  }
  
  /// Get current brain development state
  Future<BrainDevelopmentState> getCurrentBrainState() async {
    await init();
    
    final stateData = _brainStateBox?.get('current_state') ?? _getInitialBrainState();
    return BrainDevelopmentState.fromMap(stateData);
  }
  
  Map<String, dynamic> _getInitialBrainState() {
    return {
      'stage': 'infant', // infant -> child -> adolescent -> adult -> mature
      'neural_connections': 50,
      'max_connections': _maxNeuronConnections,
      'learning_rate': 1.0,
      'memory_capacity': 100,
      'processing_speed': 0.5,
      'emotional_intelligence': 0.3,
      'pattern_recognition': 0.2,
      'contextual_awareness': 0.1,
      'personality_confidence': 0.1,
      'total_experiences': 0,
      'significant_memories': 0,
      'learned_patterns': <String, double>{},
      'emotional_memories': <String, int>{},
      'interaction_history': <Map<String, dynamic>>[],
      'development_milestones': <String>[],
      'created_at': DateTime.now().toIso8601String(),
      'last_growth_event': DateTime.now().toIso8601String(),
    };
  }
  
  /// Analyze impact dari memory terhadap brain development
  Future<MemoryImpact> _analyzeMemoryImpact(HiveMemory memory) async {
    // Calculate novelty score
    final noveltyScore = await _calculateNoveltyScore(memory);
    
    // Calculate complexity
    final complexityLevel = _calculateComplexityLevel(memory);
    
    // Calculate personal relevance
    final personalRelevance = await _calculatePersonalRelevance(memory);
    
    // Calculate learning potential
    final learningPotential = _calculateLearningPotential(memory);
    
    return MemoryImpact(
      emotionalIntensity: memory.emotionalWeight,
      noveltyScore: noveltyScore,
      complexityLevel: complexityLevel,
      personalRelevance: personalRelevance,
      socialContext: _analyzeSocialContext(memory),
      learningPotential: learningPotential,
    );
  }
  
  /// Simulate neural growth berdasarkan memory impact
  BrainDevelopmentState _simulateNeuralGrowth(
    BrainDevelopmentState currentState,
    MemoryImpact impact,
  ) {
    final updatedState = currentState.copyWith();
    
    // Increase neural connections based on novelty and complexity
    if (impact.noveltyScore > 0.7 && impact.complexityLevel > 0.5) {
      final growthAmount = (impact.noveltyScore * impact.complexityLevel * 10).round();
      final newConnections = (updatedState.neuralConnections + growthAmount)
          .clamp(0, _maxNeuronConnections);
      updatedState.neuralConnections = newConnections;
    }
    
    // Update cognitive abilities
    updatedState.patternRecognition = (updatedState.patternRecognition + 
        (impact.learningPotential * 0.01)).clamp(0.0, 1.0);
    
    updatedState.emotionalIntelligence = (updatedState.emotionalIntelligence + 
        (impact.emotionalIntensity * 0.005)).clamp(0.0, 1.0);
    
    updatedState.contextualAwareness = (updatedState.contextualAwareness + 
        (impact.personalRelevance * 0.008)).clamp(0.0, 1.0);
    
    // Update processing speed berdasarkan neural connections
    final connectionRatio = updatedState.neuralConnections / _maxNeuronConnections;
    updatedState.processingSpeed = (connectionRatio * 0.8 + 0.2).clamp(0.0, 1.0);
    
    // Update personality confidence
    if (impact.personalRelevance > 0.6) {
      updatedState.personalityConfidence = (updatedState.personalityConfidence + 0.01)
          .clamp(0.0, 1.0);
    }
    
    // Update learned patterns
    for (final context in impact.contexts) {
      final currentValue = updatedState.learnedPatterns[context] ?? 0.0;
      updatedState.learnedPatterns[context] = (currentValue + 0.1).clamp(0.0, 1.0);
    }
    
    // Update emotional memories count
    if (impact.emotionalIntensity > 0.7) {
      final emotionType = _getMainEmotion(impact);
      final currentCount = updatedState.emotionalMemories[emotionType] ?? 0;
      updatedState.emotionalMemories[emotionType] = currentCount + 1;
    }
    
    // Update development stage
    updatedState.stage = _calculateDevelopmentStage(updatedState);
    
    // Update totals
    updatedState.totalExperiences += 1;
    if (impact.emotionalIntensity > 0.8 || impact.noveltyScore > 0.8) {
      updatedState.significantMemories += 1;
    }
    
    updatedState.lastGrowthEvent = DateTime.now();
    
    return updatedState;
  }
  
  String _calculateDevelopmentStage(BrainDevelopmentState state) {
    final connectionRatio = state.neuralConnections / _maxNeuronConnections;
    final avgCognitive = (state.patternRecognition + 
                         state.emotionalIntelligence + 
                         state.contextualAwareness) / 3;
    
    if (state.totalExperiences < 50 || connectionRatio < 0.1) {
      return 'infant';
    } else if (state.totalExperiences < 200 || connectionRatio < 0.3) {
      return 'child';
    } else if (state.totalExperiences < 500 || avgCognitive < 0.6) {
      return 'adolescent';
    } else if (state.totalExperiences < 1000 || avgCognitive < 0.8) {
      return 'adult';
    } else {
      return 'mature';
    }
  }
  
  Future<double> _calculateNoveltyScore(HiveMemory memory) async {
    // Simplified novelty calculation
    // Check similarity dengan existing memories
    final currentState = await getCurrentBrainState();
    
    int similarPatterns = 0;
    for (final pattern in currentState.learnedPatterns.keys) {
      if (memory.contexts.contains(pattern) || memory.tags.any((tag) => pattern.contains(tag))) {
        similarPatterns++;
      }
    }
    
    // Novelty = 1.0 - (similarity ratio)
    final maxPatterns = currentState.learnedPatterns.length;
    if (maxPatterns == 0) return 1.0;
    
    return (1.0 - (similarPatterns / maxPatterns)).clamp(0.0, 1.0);
  }
  
  double _calculateComplexityLevel(HiveMemory memory) {
    // Calculate complexity berdasarkan berbagai faktor
    double complexity = 0.0;
    
    // Content length factor
    complexity += (memory.content.length / 1000).clamp(0.0, 0.3);
    
    // Context diversity factor
    complexity += (memory.contexts.length / 10).clamp(0.0, 0.3);
    
    // Tag diversity factor
    complexity += (memory.tags.length / 10).clamp(0.0, 0.2);
    
    // Emotional weight factor
    complexity += (memory.emotionalWeight * 0.2);
    
    return complexity.clamp(0.0, 1.0);
  }
  
  Future<double> _calculatePersonalRelevance(HiveMemory memory) async {
    // Calculate relevance berdasarkan user's personality dan history
    double relevance = 0.5; // Base relevance
    
    // High emotional weight = more relevant
    relevance += memory.emotionalWeight * 0.3;
    
    // Frequent contexts = more relevant
    final currentState = await getCurrentBrainState();
    for (final context in memory.contexts) {
      final patternStrength = currentState.learnedPatterns[context] ?? 0.0;
      relevance += patternStrength * 0.1;
    }
    
    return relevance.clamp(0.0, 1.0);
  }
  
  double _calculateLearningPotential(HiveMemory memory) {
    // Learning potential berdasarkan novelty dan complexity
    double potential = 0.0;
    
    // More tags = more learning opportunities
    potential += (memory.tags.length / 15).clamp(0.0, 0.4);
    
    // More contexts = more learning
    potential += (memory.contexts.length / 10).clamp(0.0, 0.3);
    
    // Emotional intensity enhances learning
    potential += memory.emotionalWeight * 0.3;
    
    return potential.clamp(0.0, 1.0);
  }
  
  double _analyzeSocialContext(HiveMemory memory) {
    // Analyze social aspects dari memory
    final socialIndicators = ['friend', 'family', 'social', 'teman', 'keluarga', 'meeting'];
    
    int socialScore = 0;
    for (final indicator in socialIndicators) {
      if (memory.content.toLowerCase().contains(indicator) ||
          memory.tags.any((tag) => tag.toLowerCase().contains(indicator)) ||
          memory.contexts.any((ctx) => ctx.toLowerCase().contains(indicator))) {
        socialScore++;
      }
    }
    
    return (socialScore / socialIndicators.length).clamp(0.0, 1.0);
  }
  
  String _getMainEmotion(MemoryImpact impact) {
    // Simplified emotion detection from impact
    if (impact.emotionalIntensity > 0.8) return 'positive';
    if (impact.emotionalIntensity < 0.3) return 'negative';
    return 'neutral';
  }
  
  Future<void> _saveBrainState(BrainDevelopmentState state) async {
    await _brainStateBox?.put('current_state', state.toMap());
  }
  
  Future<void> _checkDevelopmentMilestones(
    BrainDevelopmentState state, 
    HiveMemory triggerMemory
  ) async {
    final milestones = <String>[];
    
    // Neural connection milestones
    if (state.neuralConnections >= 100 && 
        !state.developmentMilestones.contains('neural_100')) {
      milestones.add('neural_100');
    }
    
    if (state.neuralConnections >= 500 && 
        !state.developmentMilestones.contains('neural_500')) {
      milestones.add('neural_500');
    }
    
    // Cognitive ability milestones
    if (state.patternRecognition >= 0.5 && 
        !state.developmentMilestones.contains('pattern_recognition_50')) {
      milestones.add('pattern_recognition_50');
    }
    
    if (state.emotionalIntelligence >= 0.7 && 
        !state.developmentMilestones.contains('emotional_intelligence_70')) {
      milestones.add('emotional_intelligence_70');
    }
    
    // Experience milestones
    if (state.totalExperiences >= 100 && 
        !state.developmentMilestones.contains('experiences_100')) {
      milestones.add('experiences_100');
    }
    
    // Stage transitions
    if (state.stage != state.previousStage) {
      milestones.add('stage_${state.stage}');
    }
    
    // Log new milestones
    if (milestones.isNotEmpty) {
      await _logMilestones(milestones, triggerMemory);
      state.developmentMilestones.addAll(milestones);
    }
  }
  
  Future<void> _logMilestones(List<String> milestones, HiveMemory triggerMemory) async {
    for (final milestone in milestones) {
      final milestoneData = {
        'milestone': milestone,
        'timestamp': DateTime.now().toIso8601String(),
        'trigger_memory_id': triggerMemory.id,
        'trigger_content': triggerMemory.content.length > 100 
            ? '${triggerMemory.content.substring(0, 100)}...'
            : triggerMemory.content,
      };
      
      await _learningHistoryBox?.add(milestoneData);
      print('🎯 Brain milestone achieved: $milestone');
    }
  }
  
  /// Get brain insights untuk UI
  Future<BrainInsights> getBrainInsights() async {
    final state = await getCurrentBrainState();
    
    return BrainInsights(
      developmentStage: state.stage,
      developmentProgress: _calculateDevelopmentProgress(state),
      neuralConnections: state.neuralConnections,
      maxConnections: _maxNeuronConnections,
      cognitiveAbilities: {
        'pattern_recognition': state.patternRecognition,
        'emotional_intelligence': state.emotionalIntelligence,
        'contextual_awareness': state.contextualAwareness,
        'processing_speed': state.processingSpeed,
      },
      learningMetrics: {
        'total_experiences': state.totalExperiences,
        'significant_memories': state.significantMemories,
        'learned_patterns': state.learnedPatterns.length,
        'emotional_memories': state.emotionalMemories.values
            .fold<int>(0, (sum, count) => sum + count),
      },
      milestones: state.developmentMilestones,
      lastGrowthEvent: state.lastGrowthEvent,
    );
  }
  
  double _calculateDevelopmentProgress(BrainDevelopmentState state) {
    final stages = ['infant', 'child', 'adolescent', 'adult', 'mature'];
    final currentStageIndex = stages.indexOf(state.stage);
    final baseProgress = currentStageIndex / stages.length;
    
    // Calculate progress within current stage
    final stageProgress = _calculateStageProgress(state);
    
    return (baseProgress + (stageProgress / stages.length)).clamp(0.0, 1.0);
  }
  
  double _calculateStageProgress(BrainDevelopmentState state) {
    // Calculate progress dalam current stage berdasarkan metrics
    final connectionProgress = state.neuralConnections / _maxNeuronConnections;
    final cognitiveProgress = (state.patternRecognition + 
                             state.emotionalIntelligence + 
                             state.contextualAwareness) / 3;
    final experienceProgress = (state.totalExperiences / 1000).clamp(0.0, 1.0);
    
    return (connectionProgress + cognitiveProgress + experienceProgress) / 3;
  }
  
  /// Reset brain state (untuk development/testing)
  Future<void> resetBrainState() async {
    await init();
    await _brainStateBox?.clear();
    await _learningHistoryBox?.clear();
    print('🧠 Brain state reset completed');
  }
  
  /// Get development history
  Future<List<Map<String, dynamic>>> getDevelopmentHistory() async {
    await init();
    return _learningHistoryBox?.values.toList() ?? [];
  }
}

/// Data class untuk memory impact analysis
class MemoryImpact {
  final double emotionalIntensity;
  final double noveltyScore;
  final double complexityLevel;
  final double personalRelevance;
  final double socialContext;
  final double learningPotential;
  final List<String> contexts;
  
  MemoryImpact({
    required this.emotionalIntensity,
    required this.noveltyScore,
    required this.complexityLevel,
    required this.personalRelevance,
    required this.socialContext,
    required this.learningPotential,
    this.contexts = const [],
  });
}

/// Data class untuk brain development state
class BrainDevelopmentState {
  String stage;
  String? previousStage;
  int neuralConnections;
  int maxConnections;
  double learningRate;
  int memoryCapacity;
  double processingSpeed;
  double emotionalIntelligence;
  double patternRecognition;
  double contextualAwareness;
  double personalityConfidence;
  int totalExperiences;
  int significantMemories;
  Map<String, double> learnedPatterns;
  Map<String, int> emotionalMemories;
  List<Map<String, dynamic>> interactionHistory;
  List<String> developmentMilestones;
  DateTime createdAt;
  DateTime lastGrowthEvent;
  
  BrainDevelopmentState({
    required this.stage,
    this.previousStage,
    required this.neuralConnections,
    required this.maxConnections,
    required this.learningRate,
    required this.memoryCapacity,
    required this.processingSpeed,
    required this.emotionalIntelligence,
    required this.patternRecognition,
    required this.contextualAwareness,
    required this.personalityConfidence,
    required this.totalExperiences,
    required this.significantMemories,
    required this.learnedPatterns,
    required this.emotionalMemories,
    required this.interactionHistory,
    required this.developmentMilestones,
    required this.createdAt,
    required this.lastGrowthEvent,
  });
  
  factory BrainDevelopmentState.fromMap(Map<String, dynamic> map) {
    return BrainDevelopmentState(
      stage: map['stage'] ?? 'infant',
      previousStage: map['previous_stage'],
      neuralConnections: map['neural_connections'] ?? 50,
      maxConnections: map['max_connections'] ?? 1000,
      learningRate: map['learning_rate']?.toDouble() ?? 1.0,
      memoryCapacity: map['memory_capacity'] ?? 100,
      processingSpeed: map['processing_speed']?.toDouble() ?? 0.5,
      emotionalIntelligence: map['emotional_intelligence']?.toDouble() ?? 0.3,
      patternRecognition: map['pattern_recognition']?.toDouble() ?? 0.2,
      contextualAwareness: map['contextual_awareness']?.toDouble() ?? 0.1,
      personalityConfidence: map['personality_confidence']?.toDouble() ?? 0.1,
      totalExperiences: map['total_experiences'] ?? 0,
      significantMemories: map['significant_memories'] ?? 0,
      learnedPatterns: Map<String, double>.from(map['learned_patterns'] ?? {}),
      emotionalMemories: Map<String, int>.from(map['emotional_memories'] ?? {}),
      interactionHistory: List<Map<String, dynamic>>.from(map['interaction_history'] ?? []),
      developmentMilestones: List<String>.from(map['development_milestones'] ?? []),
      createdAt: DateTime.parse(map['created_at'] ?? DateTime.now().toIso8601String()),
      lastGrowthEvent: DateTime.parse(map['last_growth_event'] ?? DateTime.now().toIso8601String()),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'stage': stage,
      'previous_stage': previousStage,
      'neural_connections': neuralConnections,
      'max_connections': maxConnections,
      'learning_rate': learningRate,
      'memory_capacity': memoryCapacity,
      'processing_speed': processingSpeed,
      'emotional_intelligence': emotionalIntelligence,
      'pattern_recognition': patternRecognition,
      'contextual_awareness': contextualAwareness,
      'personality_confidence': personalityConfidence,
      'total_experiences': totalExperiences,
      'significant_memories': significantMemories,
      'learned_patterns': learnedPatterns,
      'emotional_memories': emotionalMemories,
      'interaction_history': interactionHistory,
      'development_milestones': developmentMilestones,
      'created_at': createdAt.toIso8601String(),
      'last_growth_event': lastGrowthEvent.toIso8601String(),
    };
  }
  
  BrainDevelopmentState copyWith() {
    return BrainDevelopmentState(
      stage: stage,
      previousStage: stage, // Current becomes previous
      neuralConnections: neuralConnections,
      maxConnections: maxConnections,
      learningRate: learningRate,
      memoryCapacity: memoryCapacity,
      processingSpeed: processingSpeed,
      emotionalIntelligence: emotionalIntelligence,
      patternRecognition: patternRecognition,
      contextualAwareness: contextualAwareness,
      personalityConfidence: personalityConfidence,
      totalExperiences: totalExperiences,
      significantMemories: significantMemories,
      learnedPatterns: Map.from(learnedPatterns),
      emotionalMemories: Map.from(emotionalMemories),
      interactionHistory: List.from(interactionHistory),
      developmentMilestones: List.from(developmentMilestones),
      createdAt: createdAt,
      lastGrowthEvent: lastGrowthEvent,
    );
  }
}

/// Data class untuk brain insights
class BrainInsights {
  final String developmentStage;
  final double developmentProgress;
  final int neuralConnections;
  final int maxConnections;
  final Map<String, double> cognitiveAbilities;
  final Map<String, int> learningMetrics;
  final List<String> milestones;
  final DateTime lastGrowthEvent;
  
  BrainInsights({
    required this.developmentStage,
    required this.developmentProgress,
    required this.neuralConnections,
    required this.maxConnections,
    required this.cognitiveAbilities,
    required this.learningMetrics,
    required this.milestones,
    required this.lastGrowthEvent,
  });
}
