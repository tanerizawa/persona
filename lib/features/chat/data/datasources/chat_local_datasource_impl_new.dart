// ignore_for_file: avoid_print

import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/performance_service.dart';
import '../../../../core/services/secure_storage_service.dart';
import '../models/message_model.dart';
import 'chat_local_datasource.dart';

@LazySingleton(as: ChatLocalDataSource)
class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const String _conversationBoxName = 'conversation_history';
  
  final PerformanceService _performance = PerformanceService();
  final SecureStorageService _secureStorage = SecureStorageService.instance;
  
  @override
  Future<List<MessageModel>> getConversationHistory() async {
    return await _performance.executeWithTracking(
      'chat_local_get_history',
      () async {
        try {
          // Get current user ID to filter messages
          final currentUserId = await _secureStorage.getUserId();
          if (currentUserId == null) {
            print('🔍 No user logged in, returning empty chat history');
            return <MessageModel>[];
          }
          
          print('🔍 Loading chat history for user: ${currentUserId.substring(0, 8)}...');
          
          final box = await Hive.openBox<List>(_conversationBoxName);
          final List<dynamic>? messagesData = box.get('messages');
          
          if (messagesData == null || messagesData.isEmpty) {
            print('📭 No local messages found');
            return <MessageModel>[];
          }
          
          // Filter messages for current user only
          final userMessages = <MessageModel>[];
          for (final item in messagesData) {
            try {
              MessageModel? message;
              if (item is Map<String, dynamic>) {
                message = MessageModel.fromJson(item);
              } else if (item is Map) {
                final Map<String, dynamic> convertedMap = Map<String, dynamic>.from(item);
                message = MessageModel.fromJson(convertedMap);
              }
              
              // Only include messages for current user
              if (message != null && message.userId == currentUserId) {
                userMessages.add(message);
              }
            } catch (e) {
              print('⚠️ Skipping corrupted message: $e');
              continue;
            }
          }
          
          // Sort by timestamp and limit to recent messages
          userMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          const maxMessages = 30;
          final recentMessages = userMessages.length > maxMessages 
              ? userMessages.sublist(userMessages.length - maxMessages)
              : userMessages;
          
          print('💬 Loaded ${recentMessages.length} messages for current user');
          return recentMessages;
          
        } catch (e) {
          print('❌ Error loading chat history: $e');
          return <MessageModel>[];
        }
      },
    );
  }

  @override
  Future<void> saveConversation(List<MessageModel> messages) async {
    await _performance.executeWithTracking(
      'chat_local_save_conversation',
      () async {
        try {
          // Get current user ID
          final currentUserId = await _secureStorage.getUserId();
          if (currentUserId == null) {
            print('⚠️ No user logged in, cannot save messages');
            return;
          }
          
          print('💾 Saving ${messages.length} messages for user: ${currentUserId.substring(0, 8)}...');
          
          final box = await Hive.openBox<List>(_conversationBoxName);
          
          // Get existing messages from all users
          final List<dynamic> existingData = box.get('messages') ?? [];
          final allMessages = <MessageModel>[];
          
          // Load existing messages from other users
          for (final item in existingData) {
            try {
              MessageModel? message;
              if (item is Map<String, dynamic>) {
                message = MessageModel.fromJson(item);
              } else if (item is Map) {
                final Map<String, dynamic> convertedMap = Map<String, dynamic>.from(item);
                message = MessageModel.fromJson(convertedMap);
              }
              
              // Keep messages from other users
              if (message != null && message.userId != currentUserId) {
                allMessages.add(message);
              }
            } catch (e) {
              print('⚠️ Skipping corrupted existing message: $e');
              continue;
            }
          }
          
          // Add new messages for current user (ensure they have userId)
          final userMessages = messages.map((msg) => MessageModel(
            id: msg.id,
            content: msg.content,
            role: msg.role,
            timestamp: msg.timestamp,
            isLoading: msg.isLoading,
            conversationId: msg.conversationId,
            userId: currentUserId, // Ensure userId is set
          )).toList();
          
          allMessages.addAll(userMessages);
          
          // Optimize: Only keep last 100 messages per user to prevent storage bloat
          const maxStoredMessages = 100;
          if (allMessages.length > maxStoredMessages) {
            allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
            final recentMessages = allMessages.sublist(allMessages.length - maxStoredMessages);
            allMessages.clear();
            allMessages.addAll(recentMessages);
          }
          
          final messagesData = allMessages.map((msg) => msg.toJson()).toList();
          await box.put('messages', messagesData);
          
          print('✅ Saved conversation with ${userMessages.length} new messages');
        } catch (e) {
          print('❌ Error saving conversation: $e');
          throw CacheException('Failed to save conversation: $e');
        }
      },
    );
  }

  @override
  Future<void> clearConversation() async {
    await _performance.executeWithTracking(
      'chat_local_clear_conversation',
      () async {
        try {
          // Get current user ID
          final currentUserId = await _secureStorage.getUserId();
          if (currentUserId == null) {
            print('⚠️ No user logged in, cannot clear messages');
            return;
          }
          
          print('🗑️ Clearing chat history for user: ${currentUserId.substring(0, 8)}...');
          
          final box = await Hive.openBox<List>(_conversationBoxName);
          final List<dynamic> existingData = box.get('messages') ?? [];
          final otherUserMessages = <MessageModel>[];
          
          // Keep messages from other users
          for (final item in existingData) {
            try {
              MessageModel? message;
              if (item is Map<String, dynamic>) {
                message = MessageModel.fromJson(item);
              } else if (item is Map) {
                final Map<String, dynamic> convertedMap = Map<String, dynamic>.from(item);
                message = MessageModel.fromJson(convertedMap);
              }
              
              // Keep messages from other users only
              if (message != null && message.userId != currentUserId) {
                otherUserMessages.add(message);
              }
            } catch (e) {
              print('⚠️ Skipping corrupted message during clear: $e');
              continue;
            }
          }
          
          // Save only other users' messages
          final messagesData = otherUserMessages.map((msg) => msg.toJson()).toList();
          await box.put('messages', messagesData);
          
          print('✅ Cleared chat history for current user');
        } catch (e) {
          print('❌ Error clearing conversation: $e');
          throw CacheException('Failed to clear conversation: $e');
        }
      },
    );
  }
}
