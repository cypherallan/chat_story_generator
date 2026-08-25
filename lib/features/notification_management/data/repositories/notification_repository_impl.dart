import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification.dart';
import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_firestore_data_source.dart';
import '../models/notification_model.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationFirestoreDataSource dataSource;

  NotificationRepositoryImpl(this.dataSource);

  @override
  Future<Either<Failure, List<Notification>>> getNotifications() async {
    try {
      final notifications = await dataSource.getNotifications();

      return Right(notifications);
    } catch (e) {
      return Left(
        FirebaseFailure(
          e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Notification>> addNotification(
    Notification notification,
  ) async {
    try {
      final saved = await dataSource.addNotification(
        NotificationModel.fromEntity(notification),
      );

      return Right(saved);
    } catch (e) {
      return Left(
        FirebaseFailure(
          e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, Notification>> updateNotification(
    Notification notification,
  ) async {
    try {
      final model = NotificationModel.fromEntity(notification);

      await dataSource.updateNotification(model);

      return Right(model);
    } catch (e) {
      return Left(
        FirebaseFailure(
          e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteNotification(
    String notificationId,
  ) async {
    try {
      await dataSource.deleteNotification(notificationId);

      return const Right(null);
    } catch (e) {
      return Left(
        FirebaseFailure(
          e.toString(),
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // RECORDED REPLAY NOTIFICATION EVENTS
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>>
      getRecordedNotificationEvents(
    String projectId,
  ) async {
    try {
      final events = await dataSource.getRecordedNotificationEvents(
        projectId,
      );

      return Right(events);
    } catch (e) {
      return Left(
        FirebaseFailure(
          e.toString(),
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveRecordedNotificationEvents(
    String projectId,
    List<Map<String, dynamic>> events,
  ) async {
    try {
      await dataSource.saveRecordedNotificationEvents(
        projectId,
        events,
      );

      return const Right(null);
    } catch (e) {
      return Left(
        FirebaseFailure(
          e.toString(),
        ),
      );
    }
  }
}
