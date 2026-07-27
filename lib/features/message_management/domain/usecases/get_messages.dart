import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/message.dart';
import '../repositories/message_repository.dart';

class GetMessages {
  final MessageRepository repository;

  GetMessages(this.repository);

  Stream<Either<Failure, List<Message>>> call(
    String projectId,
  ) {
    return repository.getMessages(projectId);
  }
}
