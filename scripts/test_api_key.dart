import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Simple script to test OpenRouter API key validity
void main() async {
  print('🔑 Testing OpenRouter API Key...');
  
  // Load environment variables
  try {
    await dotenv.load();
  } catch (e) {
    print('❌ Failed to load .env file: $e');
    print('💡 Make sure you have a .env file in the project root');
    exit(1);
  }
  
  final apiKey = dotenv.env['OPENROUTER_API_KEY'];
  
  if (apiKey == null || apiKey.isEmpty) {
    print('❌ No OpenRouter API key found in .env file');
    print('💡 Add OPENROUTER_API_KEY=your-key-here to your .env file');
    exit(1);
  }
  
  if (apiKey == 'your-openrouter-api-key-here') {
    print('❌ Please replace the placeholder API key with your actual OpenRouter API key');
    print('💡 Get your API key from: https://openrouter.ai/keys');
    print('💡 Update OPENROUTER_API_KEY in your .env file');
    exit(1);
  }
  
  if (!apiKey.startsWith('sk-or-v1-')) {
    print('❌ Invalid API key format. OpenRouter keys should start with "sk-or-v1-"');
    print('💡 Make sure you copied the correct key from https://openrouter.ai/keys');
    exit(1);
  }
  
  print('✅ API key format looks correct: ${apiKey.substring(0, 15)}...');
  
  // Test the API key with a simple request
  final dio = Dio();
  
  try {
    print('🔍 Testing API key with OpenRouter...');
    
    final response = await dio.get(
      'https://openrouter.ai/api/v1/models',
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiKey',
          'HTTP-Referer': 'https://persona-ai.app',
          'X-Title': 'Persona Assistant',
        },
      ),
    );
    
    if (response.statusCode == 200) {
      print('✅ API key is valid and working!');
      print('🎉 You can now use the app with AI features');
      
      // Show available models
      final models = response.data as List;
      print('📋 Available models: ${models.length}');
      
      // Show some popular models
      final popularModels = models.where((model) => 
        model['id'].toString().contains('gpt') || 
        model['id'].toString().contains('claude') ||
        model['id'].toString().contains('deepseek')
      ).take(3).toList();
      
      if (popularModels.isNotEmpty) {
        print('🔥 Popular available models:');
        for (final model in popularModels) {
          print('   - ${model['id']}');
        }
      }
    } else {
      print('❌ Unexpected response: ${response.statusCode}');
    }
    
  } catch (e) {
    if (e is DioException) {
      if (e.response?.statusCode == 401) {
        print('❌ API key is invalid or expired');
        print('💡 Check your API key at: https://openrouter.ai/keys');
        print('💡 Make sure you have credits in your OpenRouter account');
      } else if (e.response?.statusCode == 429) {
        print('❌ Rate limit exceeded');
        print('💡 Wait a moment and try again');
      } else {
        print('❌ API request failed: ${e.response?.statusCode} ${e.response?.statusMessage}');
        print('💡 Response: ${e.response?.data}');
      }
    } else {
      print('❌ Network error: $e');
      print('💡 Check your internet connection');
    }
    exit(1);
  }
  
  print('');
  print('🎯 Next steps:');
  print('1. Run: flutter run');
  print('2. Try the AI features in the app');
  print('3. If you see errors, check the console for details');
}
