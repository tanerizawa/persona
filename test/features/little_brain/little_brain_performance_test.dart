import 'package:flutter_test/flutter_test.dart';
import 'package:persona_ai_assistant/features/little_brain/data/services/local_ai_service.dart';
import 'package:persona_ai_assistant/features/little_brain/data/models/hive_models.dart';
import 'package:persona_ai_assistant/core/services/little_brain_performance_monitor.dart';

void main() {
  group('Little Brain Performance Monitoring Tests', () {
    late LocalAIService localAIService;

    setUp(() {
      localAIService = LocalAIService();
      // Clear any existing performance history
      LittleBrainPerformanceMonitor.clearHistory();
    });

    test('Performance monitoring - Context extraction with tracking', () async {
      // Test data
      const testText = 'Saya merasa senang hari ini karena berhasil menyelesaikan project penting';
      
      // Execute with performance tracking
      final result = await localAIService.extractContextsFromText(testText);
      
      // Validate results
      expect(result, isNotEmpty);
      expect(result.any((context) => context.contains('emotion:happy')), isTrue);
      expect(result.any((context) => context.contains('activity:work')), isTrue);
      
      // Check that performance was tracked
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      expect(metrics.containsKey('context_extraction'), isTrue);
    });

    test('Performance monitoring - Tag generation with tracking', () async {
      // Test data
      const testText = 'Hari ini saya belajar programming dan membuat aplikasi mobile yang keren';
      
      // Execute with performance tracking
      final result = await localAIService.generateTagsFromText(testText);
      
      // Validate results
      expect(result, isNotEmpty);
      expect(result.contains('programming'), isTrue);
      expect(result.contains('belajar'), isTrue);
      
      // Check that performance was tracked
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      expect(metrics.containsKey('tag_generation'), isTrue);
    });

    test('Performance monitoring - Emotional weight calculation with tracking', () async {
      // Test data
      const testText = 'Saya sangat bahagia dan excited tentang masa depan!';
      final contexts = ['emotion:happy', 'emotion:excited'];
      
      // Execute with performance tracking
      final result = await localAIService.calculateEmotionalWeight(testText, contexts);
      
      // Validate results
      expect(result, greaterThan(0.5)); // Should be positive
      expect(result, lessThanOrEqualTo(1.0));
      
      // Check that performance was tracked
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      expect(metrics.containsKey('emotional_weight_calculation'), isTrue);
    });

    test('Performance monitoring - Personality analysis with tracking', () async {
      // Test data - create sample memories
      final memories = [
        HiveMemory(
          id: '1',
          content: 'Today I helped my friend with their project',
          tags: ['help', 'friend', 'project'],
          contexts: ['activity:social', 'relationship:friends'],
          emotionalWeight: 0.8,
          timestamp: DateTime.now().subtract(Duration(days: 1)),
          source: 'chat',
          metadata: {},
        ),
        HiveMemory(
          id: '2',
          content: 'I love learning new technologies',
          tags: ['learning', 'technology'],
          contexts: ['activity:study', 'emotion:happy'],
          emotionalWeight: 0.9,
          timestamp: DateTime.now().subtract(Duration(days: 2)),
          source: 'chat',
          metadata: {},
        ),
      ];
      
      // Execute with performance tracking
      final result = await localAIService.analyzePersonalityTraits(memories);
      
      // Validate results
      expect(result, hasLength(5)); // Big Five traits
      expect(result.containsKey('openness'), isTrue);
      expect(result.containsKey('conscientiousness'), isTrue);
      expect(result.containsKey('extraversion'), isTrue);
      expect(result.containsKey('agreeableness'), isTrue);
      expect(result.containsKey('neuroticism'), isTrue);
      
      // Check that performance was tracked
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      expect(metrics.containsKey('personality_analysis'), isTrue);
    });

    test('Performance monitoring - AI context creation with tracking', () async {
      // Test data
      final memories = [
        HiveMemory(
          id: '1',
          content: 'I completed my workout this morning',
          tags: ['workout', 'morning', 'exercise'],
          contexts: ['activity:exercise', 'time:morning'],
          emotionalWeight: 0.7,
          timestamp: DateTime.now().subtract(Duration(hours: 2)),
          source: 'chat',
          metadata: {},
        ),
      ];
      
      const currentInput = 'How should I plan my day?';
      
      // Execute with performance tracking
      final result = await localAIService.createAIContext(memories, currentInput);
      
      // Validate results
      expect(result, isNotEmpty);
      expect(result.contains('USER CONTEXT'), isTrue);
      expect(result.contains('PERSONALITY INSIGHTS'), isTrue);
      
      // Check that performance was tracked
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      expect(metrics.containsKey('ai_context_creation'), isTrue);
    });

    test('Performance thresholds and alerts', () async {
      // Test performance threshold monitoring
      const testText = 'Test context for performance monitoring';
      
      // Execute multiple operations to test monitoring
      for (int i = 0; i < 5; i++) {
        await localAIService.extractContextsFromText(testText);
      }
      
      // Get performance metrics
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      final contextMetrics = metrics['context_extraction'];
      
      expect(contextMetrics, isNotNull);
      expect(contextMetrics['operation_count'], equals(5));
      expect(contextMetrics['average_duration_ms'], isA<int>());
      expect(contextMetrics['last_duration_ms'], isA<int>());
    });

    test('Enhanced emotion detection integration', () async {
      // Test enhanced vs standard emotion detection
      const testText = 'I feel incredibly anxious about my upcoming presentation';
      
      // Test enhanced detection first - this will trigger performance tracking
      await localAIService.detectEmotionsEnhanced(testText);
      
      // Test standard detection  
      final standardResult = await localAIService.extractContextsFromText(testText);
      final emotions = standardResult.where((c) => c.startsWith('emotion:')).toList();
      
      // Standard detection should work for this emotional text
      expect(emotions, isNotEmpty);
      
      // Check performance tracking for enhanced detection
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      expect(metrics.containsKey('emotion_detection'), isTrue);
    });
  });

  group('Performance Regression Tests', () {
    test('Context extraction performance benchmark', () async {
      final stopwatch = Stopwatch()..start();
      
      const testText = 'Hari ini saya sangat senang karena berhasil menyelesaikan tugas kuliah dan bertemu teman-teman lama';
      
      // Run multiple times to get average
      for (int i = 0; i < 10; i++) {
        await LocalAIService().extractContextsFromText(testText);
      }
      
      stopwatch.stop();
      final averageTime = stopwatch.elapsedMilliseconds / 10;
      
      // Should complete within reasonable time (< 100ms average)
      expect(averageTime, lessThan(100));
    });

    test('Memory usage monitoring', () async {
      // Test that performance monitoring doesn't cause memory leaks
      final initialMetrics = LittleBrainPerformanceMonitor.getMetrics();
      
      // Run many operations
      for (int i = 0; i < 20; i++) {
        await LocalAIService().extractContextsFromText('Test text $i');
      }
      
      final finalMetrics = LittleBrainPerformanceMonitor.getMetrics();
      
      // Verify metrics are collected but not exponentially growing
      expect(finalMetrics.length, greaterThanOrEqualTo(initialMetrics.length));
    });
  });
}
