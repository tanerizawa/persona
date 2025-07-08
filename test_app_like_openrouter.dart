import 'dart:io';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  print('🔍 Testing OpenRouter API with app-like implementation...\n');
  
  // Load environment variables (simulate app behavior)
  try {
    await dotenv.load(fileName: '.env');
    print('✅ Environment loaded');
  } catch (e) {
    print('❌ Failed to load .env: $e');
    return;
  }
  
  final apiKey = dotenv.env['OPENROUTER_API_KEY'] ?? '';
  final model = dotenv.env['DEFAULT_MODEL'] ?? 'deepseek/deepseek-chat-v3-0324';
  
  if (apiKey.isEmpty) {
    print('❌ API key is empty');
    return;
  }
  
  print('🔑 API Key found: ${apiKey.substring(0, 10)}...');
  print('🤖 Model: $model');
  print('');
  
  // Test chat completion with exact same structure as app
  await testChatCompletion(apiKey, model);
}

Future<void> testChatCompletion(String apiKey, String model) async {
  print('🧪 Testing chat completion...');
  
  final httpClient = HttpClient();
  
  try {
    final uri = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    final request = await httpClient.postUrl(uri);
    
    // Set headers exactly like in the app
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Authorization', 'Bearer $apiKey');
    request.headers.set('HTTP-Referer', 'https://persona-ai.app');
    request.headers.set('X-Title', 'Persona AI Assistant');
    
    print('📋 Headers being sent:');
    request.headers.forEach((name, values) {
      if (name == 'authorization') {
        print('   $name: Bearer ${apiKey.substring(0, 10)}...');
      } else {
        print('   $name: ${values.join(", ")}');
      }
    });
    
    final body = {
      'model': model,
      'messages': [
        {'role': 'system', 'content': 'You are a helpful assistant.'},
        {'role': 'user', 'content': 'Say "Test successful" if you can read this.'}
      ],
      'max_tokens': 50,
      'temperature': 0.7,
    };
    
    print('📤 Request body:');
    print('   model: $model');
    print('   messages: ${body['messages']}');
    print('   max_tokens: ${body['max_tokens']}');
    print('   temperature: ${body['temperature']}');
    print('');
    
    request.add(utf8.encode(json.encode(body)));
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📥 Response:');
    print('   Status: ${response.statusCode}');
    print('   Body: $responseBody');
    print('');
    
    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      if (data['choices'] != null && data['choices'].isNotEmpty) {
        final content = data['choices'][0]['message']['content'];
        print('✅ Chat completion successful!');
        print('💬 Response: "$content"');
      } else {
        print('❌ No choices in response');
      }
    } else {
      print('❌ Request failed with status ${response.statusCode}');
      final errorData = json.decode(responseBody);
      print('🔍 Error details: $errorData');
    }
    
  } catch (e) {
    print('❌ Error during request: $e');
  } finally {
    httpClient.close();
  }
}
