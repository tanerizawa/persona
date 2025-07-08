import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/services/crisis_intervention_service.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../injection_container.dart';

@singleton
class AiChatService {
  final Dio _dio;
  final CrisisInterventionService _crisisService;
  final _uuid = const Uuid();
  
  AiChatService(BackendApiService backendApiService) 
    : _dio = backendApiService.dio,
      _crisisService = getIt<CrisisInterventionService>();
  
  /// Sends a chat message to the backend AI endpoint
  Future<String> sendMessage({
    required String message,
    String? conversationId,
    String? model,
  }) async {
    try {
      // Check for crisis indicators before sending to AI
      final crisisMessage = await _crisisService.handleCrisisDetection(message, 'chat');
      
      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}/api/ai/chat',
        data: {
          'message': message,
          'conversationId': conversationId ?? _uuid.v4(),
          'model': model,
        },
      );
      
      final responseData = response.data;
      if (responseData['success'] == true && responseData['data'] != null) {
        String aiResponse = responseData['data']['text'] as String;
        
        // If crisis was detected, prepend intervention message
        if (crisisMessage != null) {
          aiResponse = '$crisisMessage\n\n---\n\n$aiResponse';
        }
        
        return aiResponse;
      } else {
        throw ServerException(responseData['error'] ?? 'Unknown error from backend');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw RateLimitException('Rate limit exceeded. Please try again later.');
      } else if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Authentication required. Please log in again.');
      }
      
      throw ServerException(
        e.response?.data?['error'] ?? 'Failed to communicate with AI service',
      );
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }
  
  /// Generate content using AI (quotes, journal prompts, etc.)
  Future<String> generateContent({
    required String contentType,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final response = await _dio.post(
        '${AppConstants.backendBaseUrl}/api/ai/content',
        data: {
          'contentType': contentType,
          'parameters': parameters ?? {},
        },
      );
      
      return response.data['data']['content'] as String;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        throw RateLimitException('Rate limit exceeded. Please try again later.');
      } else if (e.response?.statusCode == 401) {
        throw UnauthorizedException('Authentication required. Please log in again.');
      }
      
      throw ServerException(
        e.response?.data?['error'] ?? 'Failed to generate content',
      );
    } catch (e) {
      throw ServerException('An unexpected error occurred: $e');
    }
  }
}
