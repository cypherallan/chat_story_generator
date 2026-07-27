import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/message.dart';

abstract class MessageRepository {
  Stream<Either<Failure, List<Message>>> getMessages(
    String projectId,
  );

  Future<Either<Failure, Message>> addMessage(
    Message message,
  );

  Future<Either<Failure, Message>> updateMessage(
    Message message,
  );

  Future<Either<Failure, void>> deleteMessage(
    String projectId,
    String messageId,
  );
}
