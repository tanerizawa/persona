import '../models/message_model.dart';

abstract class ChatLocalDataSource {
  Future<List<MessageModel>> getConversationHistory();
  Future<void> saveConversation(List<MessageModel> messages);
  Future<void> clearConversation();
}
