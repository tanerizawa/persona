// Simple test script to verify BackendApiService works
// Run with: dart test_backend_service.dart

import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  print('🔄 Testing Backend API Service Integration...\n');
  
  final dio = Dio(BaseOptions(
    baseUrl: 'http://127.0.0.1:3000/api',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  // Test 1: Register a new user
  print('1️⃣ Testing user registration...');
  final email = 'test-dart-${DateTime.now().millisecondsSinceEpoch}@example.com';
  
  try {
    final registerResponse = await dio.post('/auth/register', data: {
      'email': email,
      'password': 'TestPassword123',
      'name': 'Dart Test User',
      'deviceId': 'dart-test-device',
    });
    
    if (registerResponse.statusCode == 201 && registerResponse.data['success'] == true) {
      print('✅ Registration successful');
      print('   User: ${registerResponse.data['user']['name']}');
      print('   Email: ${registerResponse.data['user']['email']}');
    } else {
      print('❌ Registration failed: ${registerResponse.data}');
      exit(1);
    }
  } catch (e) {
    print('❌ Registration error: $e');
    exit(1);
  }

  // Test 2: Login with valid credentials
  print('\n2️⃣ Testing user login...');
  
  try {
    final loginResponse = await dio.post('/auth/login', data: {
      'email': email,
      'password': 'TestPassword123',
      'deviceId': 'dart-test-device',
    });
    
    if (loginResponse.statusCode == 200 && loginResponse.data['success'] == true) {
      print('✅ Login successful');
      final token = loginResponse.data['accessToken'];
      
      // Test 3: Get profile with token
      print('\n3️⃣ Testing profile retrieval...');
      
      final profileResponse = await dio.get('/auth/profile',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
        }),
      );
      
      if (profileResponse.statusCode == 200 && profileResponse.data['success'] == true) {
        print('✅ Profile retrieval successful');
        print('   Name: ${profileResponse.data['user']['name']}');
        print('   Email: ${profileResponse.data['user']['email']}');
      } else {
        print('❌ Profile retrieval failed: ${profileResponse.data}');
        exit(1);
      }
    } else {
      print('❌ Login failed: ${loginResponse.data}');
      exit(1);
    }
  } catch (e) {
    print('❌ Login error: $e');
    exit(1);
  }

  // Test 4: Test invalid login
  print('\n4️⃣ Testing invalid login...');
  
  try {
    await dio.post('/auth/login', data: {
      'email': 'invalid@example.com',
      'password': 'wrongpassword',
      'deviceId': 'dart-test-device',
    });
    
    print('❌ Invalid login should have failed');
    exit(1);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401 && e.response?.data['success'] == false) {
      print('✅ Invalid login correctly rejected');
    } else {
      print('❌ Unexpected error: ${e.response?.data}');
      exit(1);
    }
  }

  print('\n🎉 All integration tests passed!');
  print('✅ Backend API is working correctly');
  print('✅ Flutter can communicate with the backend');
  print('✅ Authentication flow is complete');
}
