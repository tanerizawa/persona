import 'package:injectable/injectable.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../domain/entities/message.dart';
import '../models/message_model.dart';
import 'chat_remote_datasource.dart';

class BackendChatRequest {
  final String message;
  final String? conversationId;
  final String? model;

  BackendChatRequest({required this.message, this.conversationId, this.model});

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'conversationId': conversationId,
      'model': model,
    };
  }
}

class BackendChatResponse {
  final bool success;
  final BackendChatResponseData? data;
  final String? error;

  BackendChatResponse({required this.success, this.data, this.error});

  factory BackendChatResponse.fromJson(Map<String, dynamic> json) {
    return BackendChatResponse(
      success: json['success'] as bool,
      data: json['data'] != null
          ? BackendChatResponseData.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
      error: json['error'] as String?,
    );
  }
}

class BackendChatResponseData {
  final String text;
  final String conversationId;
  final String model;

  BackendChatResponseData({
    required this.text,
    required this.conversationId,
    required this.model,
  });

  factory BackendChatResponseData.fromJson(Map<String, dynamic> json) {
    return BackendChatResponseData(
      text: json['text'] as String,
      conversationId: json['conversationId'] as String,
      model: json['model'] as String,
    );
  }
}

@LazySingleton(as: ChatRemoteDataSource)
class BackendChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final BackendApiService _backendApiService;
  final Uuid _uuid;

  BackendChatRemoteDataSourceImpl({
    required BackendApiService backendApiService,
    required Uuid uuid,
  }) : _backendApiService = backendApiService,
       _uuid = uuid;

  @override
  Future<MessageModel> sendMessage(
    String message,
    List<MessageModel> conversationHistory,
  ) async {
    try {
      // Get existing conversation ID or create a new one
      String? conversationId;
      if (conversationHistory.isNotEmpty) {
        conversationId = conversationHistory.first.conversationId;
      }

      final request = BackendChatRequest(
        message: message,
        conversationId: conversationId,
        model: AppConstants.defaultAiModel,
      );

      final response = await _backendApiService.dio.post(
        '${AppConstants.backendBaseUrl}/api/ai/chat',
        data: request.toJson(),
      );

      final chatResponse = BackendChatResponse.fromJson(response.data);

      if (!chatResponse.success || chatResponse.data == null) {
        throw ServerException(
          chatResponse.error ?? 'Unknown error from backend',
        );
      }

      // Create a message model from the response
      return MessageModel(
        id: _uuid.v4(),
        content: chatResponse.data!.text,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        conversationId: chatResponse.data!.conversationId,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw ServerException('Rate limit exceeded. Please try again later.');
      } else if (e.response?.statusCode == 401) {
        throw ServerException('Authentication required. Please log in again.');
      }
      throw ServerException(
        e.response?.data?['error'] ??
            'Failed to communicate with AI service: ${e.message}',
      );
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<MessageModel>> syncConversationFromServer() async {
    try {
      final response = await _backendApiService.dio.get(
        '${AppConstants.backendBaseUrl}/api/chat/sync',
      );

      final List<dynamic> messages = response.data['messages'] ?? [];
      return messages.map((json) => MessageModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['error'] ??
            'Failed to sync conversation from server: ${e.message}',
      );
    } catch (e) {
      throw ServerException('An unexpected error occurred during sync: $e');
    }
  }

  @override
  Future<void> syncConversationToServer(List<MessageModel> messages) async {
    try {
      await _backendApiService.dio.post(
        '${AppConstants.backendBaseUrl}/api/chat/sync',
        data: {'messages': messages.map((m) => m.toJson()).toList()},
      );
    } on DioException catch (e) {
      throw ServerException(
        e.response?.data?['error'] ??
            'Failed to sync conversation to server: ${e.message}',
      );
    } catch (e) {
      throw ServerException('An unexpected error occurred during sync: $e');
    }
  }
}
