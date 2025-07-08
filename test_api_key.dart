import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Load environment variables
  await dotenv.load();
  
  final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
  
  print('🔍 Testing OpenRouter API key...');
  print('📝 API Key: ${apiKey.substring(0, 10)}...');
  
  final dio = Dio();
  
  try {
    final response = await dio.get(
      'https://openrouter.ai/api/v1/models',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://persona-ai.app',
          'X-Title': 'Persona AI Assistant',
        },
      ),
    );
    
    print('✅ API Key is valid!');
    print('📊 Available models: ${response.data.length} models found');
  } catch (e) {
    print('❌ API Key validation failed: $e');
    if (e is DioException) {
      print('📝 Response data: ${e.response?.data}');
    }
  }
}
