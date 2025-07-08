import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Future<MessageModel> sendMessage(
    String message,
    List<MessageModel> conversationHistory,
  );
}
