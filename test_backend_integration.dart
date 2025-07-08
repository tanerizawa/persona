import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing Backend Authentication Integration...');
  
  const baseUrl = 'http://127.0.0.1:3000';
  
  // Test 1: Health Check
  print('\n1. Testing Backend Health Check...');
  try {
    final response = await http.get(Uri.parse('$baseUrl/health'));
    if (response.statusCode == 200) {
      print('✅ Backend is running');
    } else {
      print('❌ Backend health check failed: ${response.statusCode}');
      return;
    }
  } catch (e) {
    print('❌ Backend is not accessible: $e');
    return;
  }
  
  // Test 2: Register a new user
  print('\n2. Testing User Registration...');
  final registerData = {
    'email': 'test-${DateTime.now().millisecondsSinceEpoch}@example.com',
    'password': 'TestPass123!',
    'name': 'Test User',
  };
  
  try {
    final registerResponse = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(registerData),
    );
    
    if (registerResponse.statusCode == 201) {
      final registerResult = jsonDecode(registerResponse.body);
      print('✅ User registration successful');
      print('   - Access Token: ${registerResult['accessToken']?.substring(0, 20)}...');
      print('   - User ID: ${registerResult['user']['id']}');
      
      // Test 3: Login with the created user
      print('\n3. Testing User Login...');
      final loginData = {
        'email': registerData['email'],
        'password': registerData['password'],
      };
      
      final loginResponse = await http.post(
        Uri.parse('$baseUrl/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(loginData),
      );
      
      if (loginResponse.statusCode == 200) {
        final loginResult = jsonDecode(loginResponse.body);
        print('✅ User login successful');
        
        // Test 4: Get user profile with token
        print('\n4. Testing User Profile Retrieval...');
        final profileResponse = await http.get(
          Uri.parse('$baseUrl/api/auth/profile'),
          headers: {
            'Authorization': 'Bearer ${loginResult['accessToken']}',
            'Content-Type': 'application/json',
          },
        );
        
        if (profileResponse.statusCode == 200) {
          final profileResult = jsonDecode(profileResponse.body);
          print('✅ Profile retrieval successful');
          print('   - User Name: ${profileResult['name']}');
          print('   - User Email: ${profileResult['email']}');
        } else {
          print('❌ Profile retrieval failed: ${profileResponse.statusCode}');
          print('   Response: ${profileResponse.body}');
        }
        
        // Test 5: Test AI Chat endpoint
        print('\n5. Testing AI Chat Endpoint...');
        final chatResponse = await http.post(
          Uri.parse('$baseUrl/api/ai/chat'),
          headers: {
            'Authorization': 'Bearer ${loginResult['accessToken']}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': 'Hello, this is a test message.',
            'conversationId': 'test-conversation-${DateTime.now().millisecondsSinceEpoch}',
          }),
        );
        
        if (chatResponse.statusCode == 200) {
          final chatResult = jsonDecode(chatResponse.body);
          print('✅ AI Chat endpoint working');
          print('   - Response: ${chatResult['data']['text']?.substring(0, 100)}...');
        } else {
          print('❌ AI Chat endpoint failed: ${chatResponse.statusCode}');
          print('   Response: ${chatResponse.body}');
        }
        
      } else {
        print('❌ User login failed: ${loginResponse.statusCode}');
        print('   Response: ${loginResponse.body}');
      }
    } else {
      print('❌ User registration failed: ${registerResponse.statusCode}');
      print('   Response: ${registerResponse.body}');
    }
  } catch (e) {
    print('❌ Registration error: $e');
  }
  
  print('\n🏁 Backend Integration Test Complete');
}
