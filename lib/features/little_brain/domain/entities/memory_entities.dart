// Simple entities untuk Local-First Little Brain
import 'package:equatable/equatable.dart';

// Memory entity untuk local processing
class Memory extends Equatable {
  final String id;
  final dynamic content; // Changed to dynamic to support both String and Map
  final List<String> tags;
  final List<String> contexts;
  final double emotionalWeight;
  final DateTime timestamp;
  final String source;
  final String? type; // Added type field
  final double? importance; // Added importance field
  final Map<String, dynamic> metadata;

  const Memory({
    required this.id,
    required this.content,
    required this.tags,
    required this.contexts,
    required this.emotionalWeight,
    required this.timestamp,
    required this.source,
    this.type,
    this.importance,
    required this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        content,
        tags,
        contexts,
        emotionalWeight,
        timestamp,
        source,
        type,
        importance,
        metadata,
      ];

  Memory copyWith({
    String? id,
    dynamic content,
    List<String>? tags,
    List<String>? contexts,
    double? emotionalWeight,
    DateTime? timestamp,
    String? source,
    String? type,
    double? importance,
    Map<String, dynamic>? metadata,
  }) {
    return Memory(
      id: id ?? this.id,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      contexts: contexts ?? this.contexts,
      emotionalWeight: emotionalWeight ?? this.emotionalWeight,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      type: type ?? this.type,
      importance: importance ?? this.importance,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Personality profile entity
class PersonalityProfile extends Equatable {
  final String userId;
  final Map<String, double> traits;
  final List<String> interests;
  final List<String> values;
  final Map<String, int> communicationPatterns;
  final DateTime lastUpdated;
  final int memoryCount;

  const PersonalityProfile({
    required this.userId,
    required this.traits,
    required this.interests,
    required this.values,
    required this.communicationPatterns,
    required this.lastUpdated,
    required this.memoryCount,
  });

  @override
  List<Object?> get props => [
        userId,
        traits,
        interests,
        values,
        communicationPatterns,
        lastUpdated,
        memoryCount,
      ];

  PersonalityProfile copyWith({
    String? userId,
    Map<String, double>? traits,
    List<String>? interests,
    List<String>? values,
    Map<String, int>? communicationPatterns,
    DateTime? lastUpdated,
    int? memoryCount,
  }) {
    return PersonalityProfile(
      userId: userId ?? this.userId,
      traits: traits ?? this.traits,
      interests: interests ?? this.interests,
      values: values ?? this.values,
      communicationPatterns: communicationPatterns ?? this.communicationPatterns,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      memoryCount: memoryCount ?? this.memoryCount,
    );
  }
}

// Simple memory context
class MemoryContext extends Equatable {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> parameters;

  const MemoryContext({
    required this.id,
    required this.name,
    required this.type,
    required this.parameters,
  });

  @override
  List<Object?> get props => [id, name, type, parameters];

  MemoryContext copyWith({
    String? id,
    String? name,
    String? type,
    Map<String, dynamic>? parameters,
  }) {
    return MemoryContext(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      parameters: parameters ?? this.parameters,
    );
  }
}
