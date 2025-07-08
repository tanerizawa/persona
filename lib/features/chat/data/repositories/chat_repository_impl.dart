import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/services/chat_personality_service.dart';
import '../datasources/chat_local_datasource.dart';
import '../datasources/chat_remote_datasource.dart';
import '../models/message_model.dart';
import '../../../little_brain/domain/usecases/little_brain_local_usecases.dart';

@LazySingleton(as: ChatRepository)
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final ChatLocalDataSource localDataSource;
  final ChatPersonalityService _personalityService;
  final AddMemoryLocalUseCase _addMemoryUseCase;

  ChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required ChatPersonalityService personalityService,
    required AddMemoryLocalUseCase addMemoryUseCase,
  }) : _personalityService = personalityService,
       _addMemoryUseCase = addMemoryUseCase;

  @override
  Future<Either<Failure, Message>> sendMessage(
    String message,
    List<Message> conversationHistory,
  ) async {
    try {
      // Check for crisis before sending
      final crisisLevel = await _personalityService.detectCrisis(message);
      
      // Get personality context for enhanced responses
      final personalityContext = await _personalityService.buildPersonalityContext();
      
      // Add personality context to the conversation for better AI responses
      final enhancedHistory = [...conversationHistory];
      if (personalityContext.isNotEmpty) {
        final contextMessage = MessageModel(
          id: const Uuid().v4(),
          content: personalityContext,
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
      
      // Save the conversation locally
      final userMessage = MessageModel(
        id: const Uuid().v4(),
        content: message,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      
      final updatedHistory = [...conversationHistory, userMessage, response];
      await localDataSource.saveConversation(
        updatedHistory.map((m) => m is MessageModel ? m : MessageModel.fromEntity(m)).toList(),
      );
      
      // Capture memories from the conversation including crisis detection
      await _captureMemoriesFromChat(message, response.content);
      
      return Right(response);
    } on ServerException {
      return const Left(ServerFailure('Failed to send message'));
    } on CacheException {
      return const Left(CacheFailure('Failed to save conversation'));
    }
  }

  // Private method to capture memories from chat interactions
  Future<void> _captureMemoriesFromChat(String userMessage, String aiResponse) async {
    try {
      // Capture user message as memory if it contains meaningful information
      if (userMessage.length > 20) { // Basic filter for meaningful content
        await _addMemoryUseCase.call(
          userMessage,
          'chat_user',
          metadata: {
            'type': 'user_input',
            'timestamp': DateTime.now().toIso8601String(),
            'ai_response_preview': aiResponse.length > 100 
              ? '${aiResponse.substring(0, 100)}...' 
              : aiResponse,
            'personality_enhanced': 'true', // Indicates this chat used personality context
          },
        );
      }
      
      // Capture AI insights if the response contains valuable information
      if (aiResponse.length > 50) {
        await _addMemoryUseCase.call(
          aiResponse,
          'chat_ai',
          metadata: {
            'type': 'ai_insight',
            'timestamp': DateTime.now().toIso8601String(),
            'user_query': userMessage.length > 100 
              ? '${userMessage.substring(0, 100)}...' 
              : userMessage,
            'personality_enhanced': 'true', // Indicates this response used personality context
          },
        );
      }
    } catch (e) {
      // Log error but don't fail the chat operation
      // ignore: avoid_print
      print('Error capturing memories from chat: $e');
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
