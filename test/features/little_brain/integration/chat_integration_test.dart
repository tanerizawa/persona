// 🧠 Little Brain Chat Integration Test
// Test to validate end-to-end chat memory capture and AI context generation

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:persona_ai_assistant/features/little_brain/data/models/hive_models.dart';
import 'package:persona_ai_assistant/features/little_brain/data/repositories/little_brain_local_repository.dart';
import 'package:persona_ai_assistant/features/little_brain/data/services/local_ai_service.dart';
import 'package:persona_ai_assistant/features/little_brain/domain/usecases/little_brain_local_usecases.dart';
void main() {
  group('Chat Integration Tests', () {
    late LittleBrainLocalRepository repository;
    late LocalAIService localAI;
    late AddMemoryLocalUseCase addMemoryUseCase;
    late CreateAIContextLocalUseCase createContextUseCase;

    setUpAll(() async {
      // Initialize Hive for testing
      await Hive.initFlutter();
      Hive.registerAdapter(HiveMemoryAdapter());
      Hive.registerAdapter(HivePersonalityProfileAdapter());
      Hive.registerAdapter(HiveContextAdapter());
      Hive.registerAdapter(HiveSyncMetadataAdapter());
    });

    setUp(() async {
      // Clear test boxes
      await Hive.deleteBoxFromDisk('memories');
      await Hive.deleteBoxFromDisk('profiles');
      await Hive.deleteBoxFromDisk('contexts');
      
      localAI = LocalAIService();
      repository = LittleBrainLocalRepository(localAI);
      addMemoryUseCase = AddMemoryLocalUseCase(repository);
      createContextUseCase = CreateAIContextLocalUseCase(repository, localAI);
    });

    tearDown(() async {
      // Clean up
      await Hive.deleteBoxFromDisk('memories');
      await Hive.deleteBoxFromDisk('profiles');
      await Hive.deleteBoxFromDisk('contexts');
    });

    group('Memory Capture from Chat', () {
      test('should capture user message and analyze it locally', () async {
        // Arrange
        const userMessage = 'Saya sedang belajar machine learning dan sangat excited tentang deep learning!';
        const source = 'chat_user';

        // Act
        await addMemoryUseCase.call(userMessage, source, metadata: {
          'timestamp': DateTime.now().toIso8601String(),
          'message_length': userMessage.length,
          'conversation_id': 'test_conv_1',
        });

        // Assert
        final memories = await repository.getAllMemories();
        expect(memories.length, equals(1));
        
        final memory = memories.first;
        expect(memory.content, equals(userMessage));
        expect(memory.source, equals(source));
        expect(memory.tags, contains('machine'));
        expect(memory.tags, contains('learning'));
        expect(memory.contexts, contains('activity:study'));
        expect(memory.emotionalWeight, greaterThan(0.6)); // Should be positive
      });

      test('should build personality-aware AI context from memories', () async {
        // Arrange - Add multiple memories to build context
        await addMemoryUseCase.call(
          'Saya suka musik jazz dan bermain piano',
          'chat_user',
          metadata: {'type': 'hobby_interest'},
        );
        
        await addMemoryUseCase.call(
          'Hari ini saya merasa sangat senang karena berhasil menyelesaikan project',
          'chat_user',
          metadata: {'type': 'achievement'},
        );
        
        await addMemoryUseCase.call(
          'Kadang saya merasa cemas kalau deadline project semakin dekat',
          'chat_user',
          metadata: {'type': 'work_stress'},
        );

        // Act
        const currentInput = 'Bagaimana cara mengatasi stress saat bekerja?';
        final aiContext = await createContextUseCase.call(currentInput);

        // Assert
        expect(aiContext, isNotEmpty);
        expect(aiContext.toLowerCase(), contains('music')); // Should include interests
        expect(aiContext.toLowerCase(), contains('cemas')); // Should include emotional patterns
        expect(aiContext.toLowerCase(), contains('project')); // Should include work context
        
        // Context should be comprehensive enough for AI
        expect(aiContext.length, greaterThan(100));
        expect(aiContext, contains('USER CONTEXT'));
        expect(aiContext, contains('RECENT RELEVANT MEMORIES'));
      });

      test('should handle emotional progression in conversation', () async {
        // Arrange - Simulate emotional conversation progression
        final messages = [
          'Saya merasa sangat down hari ini',
          'Pekerjaan sangat menyebalkan dan bos saya tidak pengertian',
          'Tapi untungnya saya punya teman yang selalu mendukung',
          'Sekarang saya mulai merasa lebih baik dan optimis',
        ];

        // Act - Add messages in sequence
        for (int i = 0; i < messages.length; i++) {
          await addMemoryUseCase.call(
            messages[i],
            'chat_user',
            metadata: {'sequence': i, 'session_id': 'emotional_journey'},
          );
        }

        // Create context after emotional journey
        const currentInput = 'Terima kasih sudah mendengarkan keluh kesah saya';
        final aiContext = await createContextUseCase.call(currentInput);

        // Assert
        final memories = await repository.getAllMemories();
        expect(memories.length, equals(4));
        
        // Should track emotional progression
        final emotionalWeights = memories.map((m) => m.emotionalWeight).toList();
        expect(emotionalWeights.first, lessThan(0.4)); // Started negative
        expect(emotionalWeights.last, greaterThan(0.6)); // Ended positive
        
        // AI context should reflect emotional journey
        expect(aiContext.toLowerCase(), contains('down'));
        expect(aiContext.toLowerCase(), contains('optimis'));
        expect(aiContext.toLowerCase(), contains('teman'));
      });

      test('should generate relevant context for specific topics', () async {
        // Arrange - Add domain-specific memories
        await addMemoryUseCase.call(
          'Saya baru saja menyelesaikan kursus React Native',
          'chat_user',
          metadata: {'domain': 'programming'},
        );
        
        await addMemoryUseCase.call(
          'Flutter framework sangat menarik untuk mobile development',
          'chat_user',
          metadata: {'domain': 'programming'},
        );
        
        await addMemoryUseCase.call(
          'Saya senang memasak pasta dan makanan Italia',
          'chat_user',
          metadata: {'domain': 'cooking'},
        );

        // Act - Ask programming question
        const programmingQuestion = 'Apa perbedaan React Native dengan Flutter?';
        final programmingContext = await createContextUseCase.call(programmingQuestion);
        
        // Ask cooking question
        const cookingQuestion = 'Bisakah kamu rekomendasikan resep pasta yang enak?';
        final cookingContext = await createContextUseCase.call(cookingQuestion);

        // Assert
        // Programming context should prioritize programming memories
        expect(programmingContext.toLowerCase(), contains('react'));
        expect(programmingContext.toLowerCase(), contains('flutter'));
        
        // Cooking context should prioritize cooking memories
        expect(cookingContext.toLowerCase(), contains('pasta'));
        expect(cookingContext.toLowerCase(), contains('italia'));
        
        // Both contexts should be relevant to their domains
        expect(programmingContext.split('\n').length, greaterThan(5));
        expect(cookingContext.split('\n').length, greaterThan(5));
      });
    });

    group('Personality Model Updates', () {
      test('should update personality profile from chat interactions', () async {
        // Arrange - Add memories that indicate personality traits
        final personalityMessages = [
          'Saya suka bertemu orang baru dan berbicara dengan mereka', // Extraversion
          'Saya selalu merencanakan semuanya dengan detail', // Conscientiousness  
          'Saya terbuka dengan ide-ide baru dan suka bereksperimen', // Openness
          'Saya mudah khawatir kalau ada masalah', // Neuroticism
          'Saya selalu membantu teman yang sedang kesulitan', // Agreeableness
        ];

        // Act
        for (final message in personalityMessages) {
          await addMemoryUseCase.call(message, 'chat_user', metadata: {
            'type': 'personality_indicator',
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        // Assert
        final profile = await repository.getPersonalityProfile();
        expect(profile, isNotNull);
        
        // Check that personality traits are being updated
        expect(profile!.traits.keys, contains('extraversion'));
        expect(profile.traits.keys, contains('conscientiousness'));
        expect(profile.traits.keys, contains('openness'));
        expect(profile.traits.keys, contains('neuroticism'));
        expect(profile.traits.keys, contains('agreeableness'));
        
        // Memory count should reflect the interactions
        expect(profile.memoryCount, equals(personalityMessages.length));
        
        // Interests should be extracted
        expect(profile.interests, isNotEmpty);
        
        // Communication patterns should be analyzed
        expect(profile.communicationPatterns['total_messages'], greaterThan(0));
      });

      test('should maintain personality consistency over time', () async {
        // Arrange - Add consistent personality indicators
        final consistentMessages = [
          'Saya memang orangnya introvert, lebih suka sendirian',
          'Saya tidak suka keramaian dan lebih suka aktivitas sendiri',
          'Kadang saya merasa lelah setelah berinteraksi dengan banyak orang',
          'Saya lebih produktif kalau bekerja sendiri tanpa gangguan',
        ];

        // Act
        for (final message in consistentMessages) {
          await addMemoryUseCase.call(message, 'chat_user');
          
          // Check profile after each message
          final profile = await repository.getPersonalityProfile();
          if (profile != null) {
            // Extraversion should consistently be low
            expect(profile.traits['extraversion'], lessThan(0.5));
          }
        }

        // Assert final profile
        final finalProfile = await repository.getPersonalityProfile();
        expect(finalProfile, isNotNull);
        expect(finalProfile!.traits['extraversion'], lessThan(0.3)); // Strong introversion pattern
      });
    });

    group('Performance Tests', () {
      test('should handle large conversation efficiently', () async {
        // Arrange - Generate many messages
        final startTime = DateTime.now();
        const messageCount = 100;

        // Act
        for (int i = 0; i < messageCount; i++) {
          await addMemoryUseCase.call(
            'Message number $i with some content about topic ${i % 10}',
            'chat_user',
            metadata: {'index': i},
          );
        }

        final processingTime = DateTime.now().difference(startTime);
        
        // Generate context for recent conversation
        final contextStartTime = DateTime.now();
        final context = await createContextUseCase.call('What have we been talking about?');
        final contextTime = DateTime.now().difference(contextStartTime);

        // Assert
        expect(processingTime.inSeconds, lessThan(30)); // Should process quickly
        expect(contextTime.inMilliseconds, lessThan(500)); // Context generation should be fast
        expect(context, isNotEmpty);
        
        final memories = await repository.getAllMemories();
        expect(memories.length, equals(messageCount));
      });

      test('should prioritize recent and relevant memories', () async {
        // Arrange - Add memories with different timestamps and topics
        final oldMemory = 'Old conversation about cooking recipes';
        final recentMemory = 'Recent discussion about machine learning algorithms';
        
        // Add old memory first
        await addMemoryUseCase.call(oldMemory, 'chat_user', metadata: {
          'artificial_timestamp': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
        });
        
        // Add recent memory
        await addMemoryUseCase.call(recentMemory, 'chat_user', metadata: {
          'timestamp': DateTime.now().toIso8601String(),
        });

        // Act
        const mlQuestion = 'Tell me more about machine learning';
        final mlContext = await createContextUseCase.call(mlQuestion);

        // Assert
        // Recent, relevant memory should be prioritized
        expect(mlContext.toLowerCase(), contains('machine learning'));
        expect(mlContext.toLowerCase(), contains('algorithms'));
        
        // Should still work even with irrelevant old memory
        expect(mlContext, isNotEmpty);
      });
    });
  });
}
