import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/message_model.dart';
import 'chat_local_datasource.dart';

@LazySingleton(as: ChatLocalDataSource)
class ChatLocalDataSourceImpl implements ChatLocalDataSource {
  static const String _conversationBoxName = 'conversation_history';
  
  @override
  Future<List<MessageModel>> getConversationHistory() async {
    try {
      final box = await Hive.openBox<List>(_conversationBoxName);
      final List<dynamic>? messagesData = box.get('messages');
      
      if (messagesData == null) return [];
      
      return messagesData
          .cast<Map<String, dynamic>>()
          .map((map) => MessageModel.fromJson(map))
          .toList();
    } catch (e) {
      throw CacheException('Failed to load conversation history: $e');
    }
  }

  @override
  Future<void> saveConversation(List<MessageModel> messages) async {
    try {
      final box = await Hive.openBox<List>(_conversationBoxName);
      final messagesData = messages.map((msg) => msg.toJson()).toList();
      await box.put('messages', messagesData);
    } catch (e) {
      throw CacheException('Failed to save conversation: $e');
    }
  }

  @override
  Future<void> clearConversation() async {
    try {
      final box = await Hive.openBox<List>(_conversationBoxName);
      await box.delete('messages');
    } catch (e) {
      throw CacheException('Failed to clear conversation: $e');
    }
  }
}
