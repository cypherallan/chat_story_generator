import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/replay_notification.dart';
import '../../domain/repositories/replay_notification_repository.dart';
import '../datasources/replay_notification_firestore_data_source.dart';
import '../models/replay_notification_model.dart';

class ReplayNotificationRepositoryImpl implements ReplayNotificationRepository {
  final ReplayNotificationFirestoreDataSource firestoreDataSource;

  ReplayNotificationRepositoryImpl(
    this.firestoreDataSource,
  );

  @override
  Future<Either<Failure, List<ReplayNotification>>> getNotifications() async {
    try {
      final notifications = await firestoreDataSource.getNotifications();

      return Right(notifications);
    } catch (e) {
      return Left(
        CacheFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, ReplayNotification>> addNotification(
    ReplayNotification notification,
  ) async {
    try {
      final model = ReplayNotificationModel.fromEntity(notification);

      final result = await firestoreDataSource.addNotification(model);

      return Right(result);
    } catch (e) {
      return Left(
        CacheFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, ReplayNotification>> updateNotification(
    ReplayNotification notification,
  ) async {
    try {
      final model = ReplayNotificationModel.fromEntity(notification);

      final result = await firestoreDataSource.updateNotification(model);

      return Right(result);
    } catch (e) {
      return Left(
        CacheFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(
    String id,
  ) async {
    try {
      await firestoreDataSource.deleteNotification(id);

      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotifications(
    List<String> ids,
  ) async {
    try {
      await firestoreDataSource.deleteNotifications(ids);

      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure(e.toString()),
      );
    }
  }
}
