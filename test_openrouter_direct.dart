import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  final apiKey = dotenv.env['OPENROUTER_API_KEY'];
  final model = dotenv.env['AI_MODEL'];
  
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ OPENROUTER_API_KEY not found in .env file');
    exit(1);
  }
  
  if (model == null || model.isEmpty) {
    print('❌ AI_MODEL not found in .env file');
    exit(1);
  }
  
  print('🔑 API Key: ${apiKey.substring(0, 10)}...');
  print('🤖 Model: $model');
  
  // Create Dio client with proper headers
  final dio = Dio();
  
  // Add interceptor to log requests
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        print('🌐 Making request to: ${options.uri}');
        print('📝 Headers: ${options.headers}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('✅ Response status: ${response.statusCode}');
        print('📦 Response data: ${response.data}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('❌ Error: ${error.response?.statusCode} - ${error.response?.data}');
        handler.next(error);
      },
    ),
  );
  
  try {
    print('\n🧪 Testing OpenRouter API...');
    
    final response = await dio.post(
      'https://openrouter.ai/api/v1/chat/completions',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://persona-ai.app',
          'X-Title': 'Persona AI Assistant',
          'Content-Type': 'application/json',
        },
      ),
      data: {
        'model': model,
        'messages': [
          {
            'role': 'user',
            'content': 'Hello! Can you say "Hello from OpenRouter!" ?'
          }
        ],
        'max_tokens': 50,
      },
    );
    
    print('🎉 SUCCESS! OpenRouter API responded:');
    final content = response.data['choices'][0]['message']['content'];
    print('💬 AI Response: $content');
    
  } catch (e) {
    print('❌ FAILED: $e');
    exit(1);
  }
}
