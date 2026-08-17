import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/message_repository.dart';

class UpdateMessage implements UseCase<Message, Message> {
  final MessageRepository repository;

  UpdateMessage(this.repository);

  @override
  Future<Either<Failure, Message>> call(Message message) async {
    return await repository.updateMessage(message);
  }
}
