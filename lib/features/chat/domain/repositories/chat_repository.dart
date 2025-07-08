import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message.dart';

abstract class ChatRepository {
  Future<Either<Failure, Message>> sendMessage(
    String message,
    List<Message> conversationHistory,
  );
  
  Future<Either<Failure, List<Message>>> getConversationHistory();
  
  Future<Either<Failure, void>> saveConversation(List<Message> messages);
  
  Future<Either<Failure, void>> clearConversation();
}
