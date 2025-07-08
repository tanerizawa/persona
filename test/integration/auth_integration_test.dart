import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  group('Backend Authentication Integration Tests', () {
    late Dio dio;
    
    setUpAll(() {
      dio = Dio(BaseOptions(
        baseUrl: 'http://localhost:3000/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ));
    });

    test('should register a new user successfully', () async {
      final email = 'test-integration-${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      try {
        final response = await dio.post('/auth/register', data: {
          'email': email,
          'password': 'TestPassword123',
          'name': 'Integration Test User',
          'deviceId': 'test-device-123',
        });
        
        expect(response.statusCode, equals(201));
        expect(response.data['success'], equals(true));
        expect(response.data['accessToken'], isNotNull);
        expect(response.data['refreshToken'], isNotNull);
        expect(response.data['user'], isNotNull);
        expect(response.data['user']['email'], equals(email));
        expect(response.data['user']['name'], equals('Integration Test User'));
        
        print('✅ Registration integration test passed');
      } on DioException catch (e) {
        print('❌ Registration integration test failed: ${e.response?.data}');
        fail('Registration failed: ${e.message}');
      }
    });

    test('should login with valid credentials', () async {
      // First register a user
      final email = 'test-login-${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      await dio.post('/auth/register', data: {
        'email': email,
        'password': 'TestPassword123',
        'name': 'Login Test User',
        'deviceId': 'test-device-456',
      });
      
      // Then try to login
      try {
        final response = await dio.post('/auth/login', data: {
          'email': email,
          'password': 'TestPassword123',
          'deviceId': 'test-device-456',
        });
        
        expect(response.statusCode, equals(200));
        expect(response.data['success'], equals(true));
        expect(response.data['accessToken'], isNotNull);
        expect(response.data['refreshToken'], isNotNull);
        expect(response.data['user'], isNotNull);
        expect(response.data['user']['email'], equals(email));
        
        print('✅ Login integration test passed');
      } on DioException catch (e) {
        print('❌ Login integration test failed: ${e.response?.data}');
        fail('Login failed: ${e.message}');
      }
    });

    test('should fail login with invalid credentials', () async {
      try {
        await dio.post('/auth/login', data: {
          'email': 'nonexistent@example.com',
          'password': 'wrongpassword',
          'deviceId': 'test-device-789',
        });
        
        fail('Login should have failed with invalid credentials');
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(401));
        expect(e.response?.data['success'], equals(false));
        print('✅ Invalid login test passed');
      }
    });

    test('should get user profile with valid token', () async {
      // First register and login
      final email = 'test-profile-${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      await dio.post('/auth/register', data: {
        'email': email,
        'password': 'TestPassword123',
        'name': 'Profile Test User',
        'deviceId': 'test-device-profile',
      });
      
      final loginResponse = await dio.post('/auth/login', data: {
        'email': email,
        'password': 'TestPassword123',
        'deviceId': 'test-device-profile',
      });
      
      final token = loginResponse.data['accessToken'];
      
      try {
        final response = await dio.get('/auth/profile', 
          options: Options(headers: {
            'Authorization': 'Bearer $token',
          }),
        );
        
        expect(response.statusCode, equals(200));
        expect(response.data['success'], equals(true));
        expect(response.data['user']['email'], equals(email));
        expect(response.data['user']['name'], equals('Profile Test User'));
        
        print('✅ Profile test passed');
      } on DioException catch (e) {
        print('❌ Profile test failed: ${e.response?.data}');
        fail('Profile request failed: ${e.message}');
      }
    });

    test('should fail to get profile without token', () async {
      try {
        await dio.get('/auth/profile');
        fail('Profile request should have failed without token');
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(401));
        expect(e.response?.data['success'], equals(false));
        print('✅ No token profile test passed');
      }
    });
  });
}
