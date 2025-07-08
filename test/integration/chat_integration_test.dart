import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';

void main() {
  group('Chat Backend Integration Tests', () {
    late Dio dio;
    String? authToken;
    
    setUpAll(() async {
      dio = Dio(BaseOptions(
        baseUrl: 'http://127.0.0.1:3000/api',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ));
      
      // Register and login to get auth token
      final email = 'test-chat-integration-${DateTime.now().millisecondsSinceEpoch}@example.com';
      
      await dio.post('/auth/register', data: {
        'email': email,
        'password': 'TestPassword123',
        'name': 'Chat Integration Test User',
        'deviceId': 'chat-integration-device',
      });
      
      final loginResponse = await dio.post('/auth/login', data: {
        'email': email,
        'password': 'TestPassword123',
        'deviceId': 'chat-integration-device',
      });
      
      authToken = loginResponse.data['accessToken'];
    });

    test('should send a chat message and get AI response', () async {
      try {
        final response = await dio.post('/chat/send',
          data: {
            'content': 'Hello! Can you help me understand my personality better?',
          },
          options: Options(headers: {
            'Authorization': 'Bearer $authToken',
          }),
        );
        
        expect(response.statusCode, equals(200));
        expect(response.data['success'], equals(true));
        expect(response.data['conversation'], isNotNull);
        expect(response.data['conversation']['id'], isNotNull);
        expect(response.data['conversation']['messages'], isA<List>());
        expect(response.data['conversation']['messages'].length, equals(2));
        
        // Check user message
        final userMessage = response.data['conversation']['messages'][0];
        expect(userMessage['role'], equals('user'));
        expect(userMessage['content'], equals('Hello! Can you help me understand my personality better?'));
        
        // Check AI response
        final aiMessage = response.data['conversation']['messages'][1];
        expect(aiMessage['role'], equals('assistant'));
        expect(aiMessage['content'], isA<String>());
        expect(aiMessage['content'].toString().isNotEmpty, isTrue);
        
        print('✅ Chat send message test passed');
      } catch (e) {
        print('❌ Chat send message test failed: $e');
        fail('Chat send message failed: $e');
      }
    });

    test('should continue conversation with context', () async {
      // First message
      final firstResponse = await dio.post('/chat/send',
        data: {
          'content': 'What is my name?',
        },
        options: Options(headers: {
          'Authorization': 'Bearer $authToken',
        }),
      );
      
      final conversationId = firstResponse.data['conversation']['id'];
      
      // Second message in same conversation
      try {
        final response = await dio.post('/chat/send',
          data: {
            'content': 'Can you remember what I just asked?',
            'conversationId': conversationId,
          },
          options: Options(headers: {
            'Authorization': 'Bearer $authToken',
          }),
        );
        
        expect(response.statusCode, equals(200));
        expect(response.data['success'], equals(true));
        expect(response.data['conversation']['id'], equals(conversationId));
        
        print('✅ Chat conversation context test passed');
      } catch (e) {
        print('❌ Chat conversation context test failed: $e');
        fail('Chat conversation context failed: $e');
      }
    });

    test('should get user conversations list', () async {
      try {
        final response = await dio.get('/chat/conversations',
          options: Options(headers: {
            'Authorization': 'Bearer $authToken',
          }),
        );
        
        expect(response.statusCode, equals(200));
        expect(response.data['success'], equals(true));
        expect(response.data['conversations'], isA<List>());
        expect(response.data['conversations'].length, greaterThan(0));
        
        // Check conversation structure
        final conversation = response.data['conversations'][0];
        expect(conversation['id'], isNotNull);
        expect(conversation['title'], isNotNull);
        expect(conversation['createdAt'], isNotNull);
        expect(conversation['updatedAt'], isNotNull);
        
        print('✅ Get conversations test passed');
      } catch (e) {
        print('❌ Get conversations test failed: $e');
        fail('Get conversations failed: $e');
      }
    });

    test('should get conversation history', () async {
      // Get conversations first to get an ID
      final conversationsResponse = await dio.get('/chat/conversations',
        options: Options(headers: {
          'Authorization': 'Bearer $authToken',
        }),
      );
      
      final conversationId = conversationsResponse.data['conversations'][0]['id'];
      
      try {
        final response = await dio.get('/chat/conversations/$conversationId',
          options: Options(headers: {
            'Authorization': 'Bearer $authToken',
          }),
        );
        
        expect(response.statusCode, equals(200));
        expect(response.data['success'], equals(true));
        expect(response.data['conversation'], isNotNull);
        expect(response.data['conversation']['messages'], isA<List>());
        
        print('✅ Get conversation history test passed');
      } catch (e) {
        print('❌ Get conversation history test failed: $e');
        fail('Get conversation history failed: $e');
      }
    });

    test('should delete conversation', () async {
      // Create a conversation first
      final createResponse = await dio.post('/chat/send',
        data: {
          'content': 'This conversation will be deleted',
        },
        options: Options(headers: {
          'Authorization': 'Bearer $authToken',
        }),
      );
      
      final conversationId = createResponse.data['conversation']['id'];
      
      try {
        final response = await dio.delete('/chat/conversations/$conversationId',
          options: Options(headers: {
            'Authorization': 'Bearer $authToken',
          }),
        );
        
        expect(response.statusCode, equals(200));
        expect(response.data['success'], equals(true));
        
        print('✅ Delete conversation test passed');
      } catch (e) {
        print('❌ Delete conversation test failed: $e');
        fail('Delete conversation failed: $e');
      }
    });

    test('should fail without authentication', () async {
      try {
        await dio.post('/chat/send', data: {
          'content': 'This should fail without auth',
        });
        
        fail('Should have failed without authentication');
      } on DioException catch (e) {
        expect(e.response?.statusCode, equals(401));
        expect(e.response?.data['success'], equals(false));
        print('✅ Authentication required test passed');
      }
    });
  });
}
