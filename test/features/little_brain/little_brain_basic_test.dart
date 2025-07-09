import 'package:flutter_test/flutter_test.dart';
import 'package:persona_ai_assistant/features/little_brain/data/services/local_ai_service.dart';
import 'package:persona_ai_assistant/core/services/little_brain_performance_monitor.dart';

void main() {
  group('Little Brain Basic Integration Tests', () {
    test('Performance monitoring integration works', () async {
      // Clear any existing data
      LittleBrainPerformanceMonitor.clearHistory();
      
      final service = LocalAIService();
      
      // Test basic context extraction with monitoring
      const testText = 'Saya senang hari ini';
      final result = await service.extractContextsFromText(testText);
      
      // Should get some contexts
      expect(result, isNotEmpty);
      
      // Performance should be tracked
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      expect(metrics.containsKey('context_extraction'), isTrue);
      
      final contextMetrics = metrics['context_extraction'];
      expect(contextMetrics['operation_count'], equals(1));
    });
    
    test('Tag generation with monitoring works', () async {
      LittleBrainPerformanceMonitor.clearHistory();
      
      final service = LocalAIService();
      
      const testText = 'programming flutter mobile app development';
      final result = await service.generateTagsFromText(testText);
      
      expect(result, isNotEmpty);
      
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      expect(metrics.containsKey('tag_generation'), isTrue);
    });
    
    test('Emotional weight calculation with monitoring works', () async {
      LittleBrainPerformanceMonitor.clearHistory();
      
      final service = LocalAIService();
      
      const testText = 'I am very happy today!';
      final contexts = ['emotion:happy'];
      final result = await service.calculateEmotionalWeight(testText, contexts);
      
      expect(result, greaterThan(0.5)); // Should be positive
      
      final metrics = LittleBrainPerformanceMonitor.getMetrics();
      expect(metrics.containsKey('emotional_weight_calculation'), isTrue);
    });
  });
}
