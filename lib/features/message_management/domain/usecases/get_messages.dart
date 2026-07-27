import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/message.dart';
import '../repositories/message_repository.dart';

class GetMessages implements UseCase<List<Message>, String> {
  final MessageRepository repository;

  GetMessages(this.repository);

  @override
  Future<Either<Failure, List<Message>>> call(String projectId) async {
    return await repository.getMessages(projectId);
  }
}
