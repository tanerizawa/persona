import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

@injectable
class SendMessageUseCase {
  final ChatRepository repository;

  SendMessageUseCase(this.repository);

  Future<Either<Failure, Message>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      params.message,
      params.conversationHistory,
    );
  }
}

class SendMessageParams {
  final String message;
  final List<Message> conversationHistory;

  SendMessageParams({
    required this.message,
    required this.conversationHistory,
  });
}
