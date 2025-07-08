import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';
import 'package:dio/dio.dart';
import '../../../../core/api/openrouter_api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/message.dart';
import '../models/message_model.dart';
import 'chat_remote_datasource.dart';

@LazySingleton(as: ChatRemoteDataSource)
class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final OpenRouterApiService apiService;
  final Uuid uuid;

  ChatRemoteDataSourceImpl({
    required this.apiService,
    required this.uuid,
  });

  @override
  Future<MessageModel> sendMessage(
    String message,
    List<MessageModel> conversationHistory,
  ) async {
    try {
      // Convert conversation history to OpenRouter format
      final messages = [
        ChatMessage(
          role: 'system',
          content: 'You are Persona, a helpful AI assistant that understands and adapts to user personalities. Be empathetic, supportive, and provide personalized responses.',
        ),
        ...conversationHistory.map((msg) => ChatMessage(
          role: _roleToString(msg.role),
          content: msg.content,
        )),
        ChatMessage(
          role: 'user',
          content: message,
        ),
      ];

      final request = ChatCompletionRequest(
        model: AppConstants.defaultAiModel,
        messages: messages,
        maxTokens: 1000,
        temperature: 0.7,
      );

      final response = await apiService.createChatCompletion(request);
      
      if (response.choices.isEmpty) {
        throw ServerException('No response from AI service');
      }

      final assistantMessage = response.choices.first.message;
      
      return MessageModel(
        id: uuid.v4(),
        content: assistantMessage.content,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
    } on DioException catch (e) {
      // Handle specific API errors
      if (e.response?.statusCode == 401) {
        // API key invalid - return helpful fallback message
        return MessageModel(
          id: uuid.v4(),
          content: _getApiKeyErrorMessage(),
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        );
      } else if (e.response?.statusCode == 429) {
        // Rate limit exceeded
        return MessageModel(
          id: uuid.v4(),
          content: "I'm experiencing high traffic right now. Please try again in a moment.",
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
        );
      }
      throw ServerException('Failed to get AI response: ${e.toString()}');
    } catch (e) {
      // For any other error, provide a fallback response
      return MessageModel(
        id: uuid.v4(),
        content: _getFallbackMessage(message),
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
    }
  }

  String _getApiKeyErrorMessage() {
    return '''I notice that the OpenRouter API key isn't configured properly. 

To enable AI-powered conversations, please:
1. Get an API key from https://openrouter.ai/keys
2. Update the configuration in the app

In the meantime, I'm still here to help you with:
• Mood tracking and analytics
• Psychology tests and insights  
• Personal growth planning
• Local data management

Would you like to explore any of these features?''';
  }

  String _getFallbackMessage(String userMessage) {
    // Simple pattern matching for basic responses
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('hello') || lowerMessage.contains('hi') || lowerMessage.contains('halo')) {
      return "Hello! I'm having some connection issues right now, but I'm still here to help you with mood tracking, psychology insights, and personal growth. What would you like to explore?";
    }
    
    if (lowerMessage.contains('help') || lowerMessage.contains('bantuan')) {
      return "I'm currently running in offline mode, but I can still help you with local features like mood tracking, viewing your psychology test results, or planning your personal growth. What specific area would you like assistance with?";
    }
    
    if (lowerMessage.contains('mood') || lowerMessage.contains('feeling')) {
      return "I'd love to help you track your mood! You can use the Growth tab to log how you're feeling and see patterns over time. This helps build a better understanding of your emotional wellbeing.";
    }
    
    return "I'm currently experiencing some connectivity issues, but I'm still here to support you with local features. You can explore mood tracking, psychology insights, or personal growth planning. How can I assist you today?";
  }

  String _roleToString(MessageRole role) {
    switch (role) {
      case MessageRole.user:
        return 'user';
      case MessageRole.assistant:
        return 'assistant';
      case MessageRole.system:
        return 'system';
    }
  }
}
