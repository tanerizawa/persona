import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/services/chat_personality_service.dart';
import '../../domain/services/chat_message_optimizer.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/message_model.dart';
import '../../../little_brain/domain/usecases/little_brain_local_usecases.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;
  final ChatPersonalityService _personalityService;
  final ChatMessageOptimizer _messageOptimizer;
  final AddMemoryLocalUseCase _addMemoryUseCase;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required ChatPersonalityService personalityService,
    required ChatMessageOptimizer messageOptimizer,
    required AddMemoryLocalUseCase addMemoryUseCase,
  }) : _personalityService = personalityService,
       _messageOptimizer = messageOptimizer,
       _addMemoryUseCase = addMemoryUseCase;

  @override
  Future<Either<Failure, Message>> sendMessage(
    String message,
    List<Message> conversationHistory,
  ) async {
    try {
      // Check for crisis before sending
      final crisisLevel = await _personalityService.detectCrisis(message);
      
      // Use smart prompt builder for efficient context
      final smartPrompt = await _personalityService.buildSmartPersonalityContext(
        message, 
        conversationId: 'chat_${DateTime.now().millisecondsSinceEpoch}'
      );
      
      // Create minimal enhanced history with smart prompt
      final enhancedHistory = [...conversationHistory];
      if (smartPrompt.isNotEmpty) {
        final contextMessage = MessageModel(
          id: const Uuid().v4(),
          content: smartPrompt,
          role: MessageRole.system,
          timestamp: DateTime.now(),
        );
        enhancedHistory.insert(0, contextMessage);
      }
      
      // Add crisis context if needed
      if (crisisLevel.level != CrisisLevel.none) {
        final crisisContextMessage = MessageModel(
          id: const Uuid().v4(),
          content: 'CRISIS DETECTION: ${crisisLevel.immediateAction}',
          role: MessageRole.system,
          timestamp: DateTime.now(),
        );
        enhancedHistory.insert(0, crisisContextMessage);
      }
      
      final response = await remoteDataSource.sendMessage(
        message,
        enhancedHistory.map((m) => MessageModel.fromEntity(m)).toList(),
      );
      
      // Optimize AI response for better bubble display
      final optimizedBubbles = _messageOptimizer.optimizeAIResponse(response.content);
      
      // For iMessage style: join bubbles with <span> separator (matches prompt instructions)
      final optimizedContent = optimizedBubbles.join(' <span> ');
      
      // Create optimized response
      final optimizedResponse = MessageModel(
        id: response.id,
        content: optimizedContent,
        role: response.role,
        timestamp: response.timestamp,
      );
      
      // Save the conversation locally
      final userMessage = MessageModel(
        id: const Uuid().v4(),
        content: message,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      
      final updatedHistory = [...conversationHistory, userMessage, optimizedResponse];
      await localDataSource.saveConversation(
        updatedHistory.map((m) => m is MessageModel ? m : MessageModel.fromEntity(m)).toList(),
      );
      
      // Capture memories from the conversation (async, fire-and-forget)
      _captureMemoriesFromChat(message, optimizedResponse.content).ignore();
      
      return Right(optimizedResponse);
    } on ServerException {
      return const Left(ServerFailure('Failed to send message'));
    } on CacheException {
      return const Left(CacheFailure('Failed to save conversation'));
    }
  }

  // Optimized memory capture: more selective and efficient
  Future<void> _captureMemoriesFromChat(String userMessage, String aiResponse) async {
    try {
      // More stringent filters to reduce unnecessary captures
      if (userMessage.length < 15 || aiResponse.length < 30) return;
      
      // Skip capturing for simple acknowledgments or short responses
      final skipPatterns = ['ok', 'ya', 'oke', 'thanks', 'terima kasih'];
      if (skipPatterns.any((pattern) => userMessage.toLowerCase().contains(pattern))) {
        return;
      }
      
      // Only capture truly meaningful conversations
      if (userMessage.length > 30 && !userMessage.toLowerCase().startsWith('hai')) {
        // Fire and forget - don't await to avoid blocking chat
        _addMemoryUseCase.call(
          userMessage,
          'chat_user',
          metadata: {
            'type': 'user_input',
            'timestamp': DateTime.now().toIso8601String(),
            'length': userMessage.length,
          },
        ).catchError((_) {
          // Silently ignore memory errors
        });
      }
    } catch (e) {
      // Silently fail - memory capture should never block chat
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getConversationHistory() async {
    try {
      final messages = await localDataSource.getConversationHistory();
      return Right(messages);
    } on CacheException {
      return const Left(CacheFailure('Failed to load conversation history'));
    }
  }

  @override
  Future<Either<Failure, void>> saveConversation(List<Message> messages) async {
    try {
      final messageModels = messages.map((m) => MessageModel.fromEntity(m)).toList();
      await localDataSource.saveConversation(messageModels);
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure('Failed to save conversation'));
    }
  }

  @override
  Future<Either<Failure, void>> clearConversation() async {
    try {
      await localDataSource.clearConversation();
      return const Right(null);
    } on CacheException {
      return const Left(CacheFailure('Failed to clear conversation'));
    }
  }
}
