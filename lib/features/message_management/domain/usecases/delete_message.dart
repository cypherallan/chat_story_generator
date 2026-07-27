import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/message_repository.dart';

class DeleteMessage implements UseCase<void, DeleteMessageParams> {
  final MessageRepository repository;

  DeleteMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(
    DeleteMessageParams params,
  ) async {
    return await repository.deleteMessage(
      params.projectId,
      params.messageId,
    );
  }
}

class DeleteMessageParams {
  final String projectId;
  final String messageId;

  const DeleteMessageParams({
    required this.projectId,
    required this.messageId,
  });
}
