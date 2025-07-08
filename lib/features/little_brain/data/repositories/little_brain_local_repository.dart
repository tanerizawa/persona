import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/memory_entities.dart';
import '../../domain/repositories/little_brain_repository.dart';
import '../models/hive_models.dart';
import '../services/local_ai_service.dart';

@singleton
class LittleBrainLocalRepository implements LittleBrainRepository {
  final LocalAIService _localAI;
  Box<HiveMemory>? _memoryBox;
  Box<HivePersonalityProfile>? _profileBox;
  Box<HiveContext>? _contextBox;
  Box<HiveSyncMetadata>? _syncBox;

  LittleBrainLocalRepository(this._localAI);

  // Initialize Hive boxes
  Future<void> init() async {
    if (_memoryBox?.isOpen != true) {
      _memoryBox = await Hive.openBox<HiveMemory>('memories');
    }
    if (_profileBox?.isOpen != true) {
      _profileBox = await Hive.openBox<HivePersonalityProfile>('profiles');
    }
    if (_contextBox?.isOpen != true) {
      _contextBox = await Hive.openBox<HiveContext>('contexts');
      
      // Initialize default contexts if empty
      if (_contextBox!.isEmpty) {
        await _initializeDefaultContexts();
      }
    }
    if (_syncBox?.isOpen != true) {
      _syncBox = await Hive.openBox<HiveSyncMetadata>('sync_metadata');
    }
  }

  // Initialize default contexts
  Future<void> _initializeDefaultContexts() async {
    final defaultContexts = HiveContext.getDefaultContexts();
    for (final context in defaultContexts) {
      await _contextBox!.put(context.id, context);
    }
  }

  @override
  Future<void> addMemory(Memory memory) async {
    await init();
    
    // Process menggunakan local AI
    final contexts = await _localAI.extractContextsFromText(memory.content);
    final tags = await _localAI.generateTagsFromText(memory.content);
    final emotionalWeight = await _localAI.calculateEmotionalWeight(memory.content, contexts);

    final hiveMemory = HiveMemory(
      id: memory.id.isNotEmpty ? memory.id : const Uuid().v4(),
      content: memory.content,
      tags: tags,
      contexts: contexts,
      emotionalWeight: emotionalWeight,
      timestamp: memory.timestamp,
      source: memory.source,
      metadata: memory.metadata,
    );

    await _memoryBox!.put(hiveMemory.id, hiveMemory);
    
    // Update personality profile
    await _updatePersonalityProfile();
  }

  @override
  Future<List<Memory>> getRelevantMemories(String query, {int limit = 10}) async {
    await init();
    
    final allMemories = _memoryBox!.values.toList();
    if (allMemories.isEmpty) return [];

    // Simple relevance scoring berdasarkan keyword matching
    final queryWords = query.toLowerCase().split(RegExp(r'\W+'));
    final scoredMemories = <MapEntry<HiveMemory, double>>[];

    for (final memory in allMemories) {
      double score = 0.0;
      final memoryText = '${memory.content} ${memory.tags.join(' ')} ${memory.contexts.join(' ')}'.toLowerCase();
      
      // Keyword matching
      for (final word in queryWords) {
        if (word.length >= 3 && memoryText.contains(word)) {
          score += 1.0;
        }
      }
      
      // Context matching boost
      for (final context in memory.contexts) {
        for (final word in queryWords) {
          if (context.toLowerCase().contains(word)) {
            score += 0.5;
          }
        }
      }
      
      // Recent memories get slight boost
      final daysSinceCreated = DateTime.now().difference(memory.timestamp).inDays;
      score += (30 - daysSinceCreated.clamp(0, 30)) / 30 * 0.3;

      // Emotional relevance
      if (query.toLowerCase().contains(RegExp(r'happy|sad|angry|excited|calm'))) {
        if (memory.emotionalWeight > 0.7 && query.toLowerCase().contains(RegExp(r'happy|excited'))) {
          score += 0.5;
        } else if (memory.emotionalWeight < 0.3 && query.toLowerCase().contains(RegExp(r'sad|angry'))) {
          score += 0.5;
        }
      }

      if (score > 0) {
        scoredMemories.add(MapEntry(memory, score));
      }
    }

    // Sort by score dan ambil top results
    scoredMemories.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredMemories
        .take(limit)
        .map((entry) => _hiveToEntity(entry.key))
        .toList();
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    await init();
    
    final allMemories = _memoryBox!.values.toList();
    allMemories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return allMemories.map(_hiveToEntity).toList();
  }

  @override
  Future<PersonalityProfile?> getPersonalityProfile() async {
    await init();
    final hiveProfile = _profileBox!.get('local_user');
    if (hiveProfile == null) return null;

    return PersonalityProfile(
      userId: hiveProfile.userId,
      traits: hiveProfile.traits,
      interests: hiveProfile.interests,
      values: hiveProfile.values,
      communicationPatterns: hiveProfile.communicationPatterns,
      lastUpdated: hiveProfile.lastUpdated,
      memoryCount: hiveProfile.memoryCount,
    );
  }

  @override
  Future<List<MemoryContext>> getAvailableContexts() async {
    await init();
    return _contextBox!.values.map((hc) => MemoryContext(
      id: hc.id,
      name: hc.name,
      type: hc.type,
      parameters: hc.parameters,
    )).toList();
  }

  @override
  Future<void> addContext(MemoryContext context) async {
    await init();
    
    final hiveContext = HiveContext(
      id: context.id.isNotEmpty ? context.id : const Uuid().v4(),
      name: context.name,
      type: context.type,
      parameters: context.parameters,
      createdAt: DateTime.now(),
      isUserDefined: true,
    );

    await _contextBox!.put(hiveContext.id, hiveContext);
  }

  @override
  Future<void> updateMemory(Memory memory) async {
    await init();
    
    final existingMemory = _memoryBox!.get(memory.id);
    if (existingMemory != null) {
      // Re-process with local AI for updated content
      final contexts = await _localAI.extractContextsFromText(memory.content);
      final tags = await _localAI.generateTagsFromText(memory.content);
      final emotionalWeight = await _localAI.calculateEmotionalWeight(memory.content, contexts);

      final updatedMemory = HiveMemory(
        id: memory.id,
        content: memory.content,
        tags: tags,
        contexts: contexts,
        emotionalWeight: emotionalWeight,
        timestamp: existingMemory.timestamp, // Keep original timestamp
        source: memory.source,
        metadata: memory.metadata,
      );

      await _memoryBox!.put(memory.id, updatedMemory);
      await _updatePersonalityProfile();
    }
  }

  @override
  Future<void> deleteMemory(String memoryId) async {
    await init();
    await _memoryBox!.delete(memoryId);
    await _updatePersonalityProfile();
  }

  @override
  Future<void> clearAllData() async {
    await init();
    await _memoryBox!.clear();
    await _profileBox!.clear();
    // Don't clear contexts as they contain default data
    // await _contextBox!.clear();
    await _syncBox!.clear();
  }

  // Update personality profile berdasarkan semua memories
  Future<void> _updatePersonalityProfile() async {
    final allMemories = _memoryBox!.values.toList();
    final traits = await _localAI.analyzePersonalityTraits(allMemories);
    
    final profile = HivePersonalityProfile(
      userId: 'local_user',
      traits: traits,
      interests: _extractInterests(allMemories),
      values: _extractValues(allMemories),
      communicationPatterns: _extractCommunicationPatterns(allMemories),
      lastUpdated: DateTime.now(),
      memoryCount: allMemories.length,
    );

    await _profileBox!.put('local_user', profile);
  }

  // Extract interests dari memory tags
  List<String> _extractInterests(List<HiveMemory> memories) {
    final interests = <String, int>{};
    
    for (final memory in memories) {
      for (final tag in memory.tags) {
        // Filter out common words and focus on meaningful interests
        if (tag.length >= 3 && !_isCommonWord(tag)) {
          interests[tag] = (interests[tag] ?? 0) + 1;
        }
      }
    }
    
    // Sort by frequency and take top interests
    final sortedInterests = interests.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedInterests
        .where((e) => e.value >= 2) // Minimal 2 kali muncul
        .take(15)
        .map((e) => e.key)
        .toList();
  }

  // Extract values dari positive emotional memories
  List<String> _extractValues(List<HiveMemory> memories) {
    final values = <String>{};
    final positiveMemories = memories.where((m) => m.emotionalWeight > 0.6);
    
    for (final memory in positiveMemories) {
      for (final context in memory.contexts) {
        if (context.startsWith('activity:')) {
          final activity = context.replaceFirst('activity:', '');
          values.add(activity);
        }
        if (context.startsWith('relationship:')) {
          final relationship = context.replaceFirst('relationship:', '');
          values.add(relationship);
        }
      }
      
      // Extract value-related keywords from content
      final content = memory.content.toLowerCase();
      if (content.contains(RegExp(r'family|keluarga'))) values.add('family');
      if (content.contains(RegExp(r'friend|teman|sahabat'))) values.add('friendship');
      if (content.contains(RegExp(r'health|sehat|kesehatan'))) values.add('health');
      if (content.contains(RegExp(r'learn|belajar|knowledge'))) values.add('learning');
      if (content.contains(RegExp(r'help|menolong|assist'))) values.add('helping_others');
      if (content.contains(RegExp(r'creative|seni|art'))) values.add('creativity');
      if (content.contains(RegExp(r'travel|jalan|adventure'))) values.add('adventure');
    }
    
    return values.take(8).toList();
  }

  // Extract communication patterns
  Map<String, int> _extractCommunicationPatterns(List<HiveMemory> memories) {
    if (memories.isEmpty) {
      return {
        'total_messages': 0,
        'avg_length': 0,
        'emotional_variance': 0,
        'context_diversity': 0,
      };
    }

    final totalLength = memories.fold(0, (sum, m) => sum + m.content.length);
    final avgLength = totalLength ~/ memories.length;

    // Calculate emotional variance
    final emotionalWeights = memories.map((m) => m.emotionalWeight).toList();
    final avgWeight = emotionalWeights.reduce((a, b) => a + b) / emotionalWeights.length;
    final variance = emotionalWeights
        .map((w) => (w - avgWeight) * (w - avgWeight))
        .reduce((a, b) => a + b) / emotionalWeights.length;

    // Count unique contexts
    final uniqueContexts = memories
        .expand((m) => m.contexts)
        .toSet()
        .length;

    return {
      'total_messages': memories.length,
      'avg_length': avgLength,
      'emotional_variance': (variance * 100).round(),
      'context_diversity': uniqueContexts,
    };
  }

  // Helper method to check common words
  bool _isCommonWord(String word) {
    const commonWords = {
      'dan', 'atau', 'yang', 'ini', 'itu', 'dengan', 'untuk', 'dari', 'ke',
      'di', 'pada', 'saya', 'kamu', 'dia', 'kita', 'the', 'and', 'or', 'is',
      'are', 'was', 'were', 'have', 'has', 'had', 'will', 'would', 'could',
      'should', 'can', 'may', 'must', 'do', 'did', 'does', 'a', 'an', 'at',
      'by', 'for', 'from', 'in', 'into', 'of', 'on', 'to', 'with'
    };
    return commonWords.contains(word.toLowerCase());
  }

  // Convert Hive model to entity
  Memory _hiveToEntity(HiveMemory hiveMemory) {
    return Memory(
      id: hiveMemory.id,
      content: hiveMemory.content,
      tags: hiveMemory.tags,
      contexts: hiveMemory.contexts, // Keep as List<String>
      emotionalWeight: hiveMemory.emotionalWeight,
      timestamp: hiveMemory.timestamp,
      source: hiveMemory.source,
      type: hiveMemory.type,
      importance: hiveMemory.importance,
      metadata: hiveMemory.metadata,
    );
  }

  // Get memory statistics for debugging/monitoring
  @override
  Future<Map<String, dynamic>> getMemoryStatistics() async {
    await init();
    
    final allMemories = _memoryBox!.values.toList();
    if (allMemories.isEmpty) {
      return {
        'total_memories': 0,
        'avg_emotional_weight': 0.5,
        'most_common_contexts': [],
        'most_common_tags': [],
      };
    }

    // Calculate statistics
    final avgEmotionalWeight = allMemories
        .map((m) => m.emotionalWeight)
        .reduce((a, b) => a + b) / allMemories.length;

    // Get most common contexts
    final contextFreq = <String, int>{};
    for (final memory in allMemories) {
      for (final context in memory.contexts) {
        contextFreq[context] = (contextFreq[context] ?? 0) + 1;
      }
    }

    // Get most common tags
    final tagFreq = <String, int>{};
    for (final memory in allMemories) {
      for (final tag in memory.tags) {
        tagFreq[tag] = (tagFreq[tag] ?? 0) + 1;
      }
    }

    final sortedContexts = contextFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final sortedTags = tagFreq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'total_memories': allMemories.length,
      'avg_emotional_weight': avgEmotionalWeight,
      'most_common_contexts': sortedContexts.take(10).map((e) => '${e.key} (${e.value})').toList(),
      'most_common_tags': sortedTags.take(10).map((e) => '${e.key} (${e.value})').toList(),
      'memory_sources': allMemories.map((m) => m.source).toSet().toList(),
    };
  }

  // Search memories by source
  @override
  Future<List<Memory>> getMemoriesBySource(String source) async {
    await init();
    
    final memories = _memoryBox!.values
        .where((m) => m.source == source)
        .toList();
    
    memories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return memories.map(_hiveToEntity).toList();
  }

  // Get memories within date range
  @override
  Future<List<Memory>> getMemoriesInRange(DateTime start, DateTime end) async {
    await init();
    
    final memories = _memoryBox!.values
        .where((m) => m.timestamp.isAfter(start) && m.timestamp.isBefore(end))
        .toList();
    
    memories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return memories.map(_hiveToEntity).toList();
  }

  // Search memories by type
  @override
  Future<List<Memory>> getMemoriesByType(String type) async {
    await init();
    
    final memories = _memoryBox!.values
        .where((m) => m.type == type)
        .toList();
    
    memories.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    return memories.map(_hiveToEntity).toList();
  }
}
