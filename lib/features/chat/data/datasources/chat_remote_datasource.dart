import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<MessageModel> sendMessage(
    String message,
    List<MessageModel> conversationHistory,
  );
  
  /// Sync conversation from server for current user
  Future<List<MessageModel>> syncConversationFromServer();
  
  /// Sync conversation to server
  Future<void> syncConversationToServer(List<MessageModel> messages);
}
