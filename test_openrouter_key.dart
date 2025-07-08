#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  print('🔍 Testing OpenRouter API Key...\n');
  
  // Read API key from .env file
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('❌ .env file not found!');
    return;
  }
  
  final envContent = await envFile.readAsString();
  final lines = envContent.split('\n');
  String? apiKey;
  
  for (final line in lines) {
    if (line.startsWith('OPENROUTER_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }
  
  if (apiKey == null || apiKey.isEmpty || apiKey == 'your-openrouter-api-key-here') {
    print('❌ No valid API key found in .env file!');
    print('Please set OPENROUTER_API_KEY in your .env file');
    return;
  }
  
  print('✅ Found API key: ${apiKey.substring(0, 10)}...');
  
  // Test 1: Check if we can access models
  print('\n🧪 Test 1: Checking available models...');
  try {
    final modelsResponse = await http.get(
      Uri.parse('https://openrouter.ai/api/v1/models'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    );
    
    if (modelsResponse.statusCode == 200) {
      final models = jsonDecode(modelsResponse.body);
      print('✅ Models API works! Found ${models['data']?.length ?? 0} models');
    } else {
      print('❌ Models API failed: ${modelsResponse.statusCode}');
      print('Response: ${modelsResponse.body}');
      return;
    }
  } catch (e) {
    print('❌ Error accessing models: $e');
    return;
  }
  
  // Test 2: Try a simple chat completion
  print('\n🧪 Test 2: Testing chat completion...');
  try {
    final chatResponse = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://persona-ai.app',
        'X-Title': 'Persona AI Assistant',
      },
      body: jsonEncode({
        'model': 'deepseek/deepseek-chat-v3-0324',  // Using your configured model
        'messages': [
          {'role': 'user', 'content': 'Hello, this is a test. Just reply with "Test successful"'}
        ],
        'max_tokens': 10,
      }),
    );
    
    if (chatResponse.statusCode == 200) {
      final response = jsonDecode(chatResponse.body);
      final message = response['choices'][0]['message']['content'];
      print('✅ Chat completion works!');
      print('Response: $message');
    } else {
      print('❌ Chat completion failed: ${chatResponse.statusCode}');
      print('Response: ${chatResponse.body}');
      
      if (chatResponse.statusCode == 401) {
        print('\n🔑 Authentication failed. Possible issues:');
        print('   - API key is invalid or expired');
        print('   - API key doesn\'t have sufficient permissions');
        print('   - Account doesn\'t have credits');
      } else if (chatResponse.statusCode == 402) {
        print('\n💳 Payment required. Your account needs credits.');
        print('   - Add credits at: https://openrouter.ai/credits');
      }
    }
  } catch (e) {
    print('❌ Error in chat completion: $e');
  }
  
  print('\n📋 Summary:');
  print('   - If both tests pass: Your API key is working correctly');
  print('   - If models work but chat fails: Check your account credits');
  print('   - If both fail: Get a new API key from https://openrouter.ai/keys');
  print('\n💡 Need help? Check: https://openrouter.ai/docs');
}
