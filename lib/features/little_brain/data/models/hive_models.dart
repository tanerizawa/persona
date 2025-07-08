import 'package:hive/hive.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 0)
class HiveMemory extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String content;
  
  @HiveField(2)
  List<String> tags;
  
  @HiveField(3)
  List<String> contexts;
  
  @HiveField(4)
  double emotionalWeight;
  
  @HiveField(5)
  DateTime timestamp;
  
  @HiveField(6)
  String source; // 'chat', 'growth', 'psychology'
  
  @HiveField(7)
  Map<String, dynamic> metadata;

  @HiveField(8)
  String? type; // Added type field
  
  @HiveField(9)
  double? importance; // Added importance field

  HiveMemory({
    required this.id,
    required this.content,
    required this.tags,
    required this.contexts,
    required this.emotionalWeight,
    required this.timestamp,
    required this.source,
    required this.metadata,
    this.type,
    this.importance,
  });

  // Helper method untuk konversi dari Memory entity
  factory HiveMemory.fromEntity(dynamic memory) {
    return HiveMemory(
      id: memory.id,
      content: memory.content is String ? memory.content : memory.content.toString(),
      tags: List<String>.from(memory.tags ?? []),
      contexts: memory.contexts?.map<String>((c) => c.toString()).toList() ?? [],
      emotionalWeight: memory.emotionalWeight?.toDouble() ?? 0.5,
      timestamp: memory.timestamp ?? DateTime.now(),
      source: memory.source ?? 'unknown',
      metadata: Map<String, dynamic>.from(memory.metadata ?? {}),
      type: memory.type,
      importance: memory.importance,
    );
  }
}

@HiveType(typeId: 1)
class HivePersonalityProfile extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  Map<String, double> traits; // Big Five, MBTI scores
  
  @HiveField(2)
  List<String> interests;
  
  @HiveField(3)
  List<String> values;
  
  @HiveField(4)
  Map<String, int> communicationPatterns;
  
  @HiveField(5)
  DateTime lastUpdated;
  
  @HiveField(6)
  int memoryCount;

  HivePersonalityProfile({
    required this.userId,
    required this.traits,
    required this.interests,
    required this.values,
    required this.communicationPatterns,
    required this.lastUpdated,
    required this.memoryCount,
  });

  // Default profile untuk user baru
  factory HivePersonalityProfile.defaultProfile(String userId) {
    return HivePersonalityProfile(
      userId: userId,
      traits: {
        'openness': 0.5,
        'conscientiousness': 0.5,
        'extraversion': 0.5,
        'agreeableness': 0.5,
        'neuroticism': 0.5,
      },
      interests: [],
      values: [],
      communicationPatterns: {
        'total_messages': 0,
        'avg_length': 0,
        'emotional_variance': 0,
        'context_diversity': 0,
      },
      lastUpdated: DateTime.now(),
      memoryCount: 0,
    );
  }
}

@HiveType(typeId: 2)
class HiveContext extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String name;
  
  @HiveField(2)
  String type; // 'emotion', 'activity', 'relationship', 'goal'
  
  @HiveField(3)
  Map<String, dynamic> parameters;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  bool isUserDefined;

  HiveContext({
    required this.id,
    required this.name,
    required this.type,
    required this.parameters,
    required this.createdAt,
    required this.isUserDefined,
  });

  // Predefined contexts yang tersedia
  static List<HiveContext> getDefaultContexts() {
    final now = DateTime.now();
    return [
      // Emotional contexts
      HiveContext(
        id: 'emotion:happy',
        name: 'Bahagia',
        type: 'emotion',
        parameters: {'weight': 0.8},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'emotion:sad',
        name: 'Sedih',
        type: 'emotion',
        parameters: {'weight': 0.2},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'emotion:anxious',
        name: 'Cemas',
        type: 'emotion',
        parameters: {'weight': 0.1},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'emotion:excited',
        name: 'Antusias',
        type: 'emotion',
        parameters: {'weight': 0.9},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'emotion:calm',
        name: 'Tenang',
        type: 'emotion',
        parameters: {'weight': 0.6},
        createdAt: now,
        isUserDefined: false,
      ),
      
      // Activity contexts
      HiveContext(
        id: 'activity:work',
        name: 'Bekerja',
        type: 'activity',
        parameters: {'category': 'professional'},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'activity:study',
        name: 'Belajar',
        type: 'activity',
        parameters: {'category': 'educational'},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'activity:exercise',
        name: 'Olahraga',
        type: 'activity',
        parameters: {'category': 'physical'},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'activity:social',
        name: 'Bersosialisasi',
        type: 'activity',
        parameters: {'category': 'social'},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'activity:hobby',
        name: 'Hobi',
        type: 'activity',
        parameters: {'category': 'recreational'},
        createdAt: now,
        isUserDefined: false,
      ),
      
      // Time contexts
      HiveContext(
        id: 'time:morning',
        name: 'Pagi',
        type: 'time',
        parameters: {'period': 'morning'},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'time:afternoon',
        name: 'Siang',
        type: 'time',
        parameters: {'period': 'afternoon'},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'time:evening',
        name: 'Sore',
        type: 'time',
        parameters: {'period': 'evening'},
        createdAt: now,
        isUserDefined: false,
      ),
      HiveContext(
        id: 'time:night',
        name: 'Malam',
        type: 'time',
        parameters: {'period': 'night'},
        createdAt: now,
        isUserDefined: false,
      ),
    ];
  }
}

@HiveType(typeId: 3)
class HiveSyncMetadata extends HiveObject {
  @HiveField(0)
  String userId;
  
  @HiveField(1)
  DateTime lastSyncTime;
  
  @HiveField(2)
  String checksum;
  
  @HiveField(3)
  int memoryCount;
  
  @HiveField(4)
  bool syncPending;
  
  @HiveField(5)
  Map<String, dynamic> deviceInfo;

  HiveSyncMetadata({
    required this.userId,
    required this.lastSyncTime,
    required this.checksum,
    required this.memoryCount,
    required this.syncPending,
    required this.deviceInfo,
  });

  factory HiveSyncMetadata.initial(String userId) {
    return HiveSyncMetadata(
      userId: userId,
      lastSyncTime: DateTime.now(),
      checksum: '',
      memoryCount: 0,
      syncPending: false,
      deviceInfo: {
        'platform': 'flutter',
        'version': '1.0.0',
      },
    );
  }
}
