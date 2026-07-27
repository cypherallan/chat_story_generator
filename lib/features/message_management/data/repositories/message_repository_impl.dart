import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_firestore_data_source.dart';
import '../models/message_model.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageFirestoreDataSource firestoreDataSource;

  MessageRepositoryImpl(
    this.firestoreDataSource,
  );

  @override
  Future<Either<Failure, List<Message>>> getMessages(
    String projectId,
  ) async {
    try {
      final messages = await firestoreDataSource.getMessages(projectId);

      return Right(messages);
    } catch (e) {
      return Left(
        CacheFailure(
          e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Message>> addMessage(
    Message message,
  ) async {
    try {
      final model = MessageModel.fromEntity(message);

      final result = await firestoreDataSource.addMessage(model);

      return Right(result);
    } catch (e) {
      return Left(
        CacheFailure(
          e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Message>> updateMessage(
    Message message,
  ) async {
    try {
      final model = MessageModel.fromEntity(message);

      await firestoreDataSource.updateMessage(model);

      return Right(message);
    } catch (e) {
      return Left(
        CacheFailure(
          e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage(
    String projectId,
    String messageId,
  ) async {
    try {
      await firestoreDataSource.deleteMessage(
        projectId,
        messageId,
      );

      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure(
          e.toString(),
        ),
      );
    }
  }
}
