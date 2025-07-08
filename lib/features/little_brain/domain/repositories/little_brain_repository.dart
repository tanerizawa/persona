// Repository interface untuk Local-First Little Brain
import '../entities/memory_entities.dart';

abstract class LittleBrainRepository {
  // Memory operations
  Future<void> addMemory(Memory memory);
  Future<List<Memory>> getRelevantMemories(String query, {int limit = 10});
  Future<List<Memory>> getAllMemories();
  Future<void> updateMemory(Memory memory);
  Future<void> deleteMemory(String memoryId);
  
  // Memory filtering
  Future<List<Memory>> getMemoriesByType(String type);
  Future<List<Memory>> getMemoriesBySource(String source);
  Future<List<Memory>> getMemoriesInRange(DateTime start, DateTime end);
  
  // Personality operations
  Future<PersonalityProfile?> getPersonalityProfile();
  
  // Context operations
  Future<List<MemoryContext>> getAvailableContexts();
  Future<void> addContext(MemoryContext context);
  
  // Data management
  Future<void> clearAllData();
  
  // Statistics
  Future<Map<String, dynamic>> getMemoryStatistics();
}
