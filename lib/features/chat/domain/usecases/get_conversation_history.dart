import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

@injectable
class GetConversationHistoryUseCase {
  final ChatRepository repository;

  GetConversationHistoryUseCase(this.repository);

  Future<Either<Failure, List<Message>>> call() async {
    return await repository.getConversationHistory();
  }
}
