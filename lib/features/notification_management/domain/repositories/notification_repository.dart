import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/notification.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<Notification>>> getNotifications();

  Future<Either<Failure, Notification>> addNotification(
    Notification notification,
  );

  Future<Either<Failure, Notification>> updateNotification(
    Notification notification,
  );

  Future<Either<Failure, void>> deleteNotification(
    String notificationId,
  );
}
