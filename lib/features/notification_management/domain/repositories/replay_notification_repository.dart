import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/replay_notification.dart';

abstract class ReplayNotificationRepository {
  Future<Either<Failure, List<ReplayNotification>>> getNotifications();

  Future<Either<Failure, ReplayNotification>> addNotification(
    ReplayNotification notification,
  );

  Future<Either<Failure, ReplayNotification>> updateNotification(
    ReplayNotification notification,
  );

  Future<Either<Failure, void>> deleteNotification(
    String id,
  );

  Future<Either<Failure, void>> deleteNotifications(
    List<String> ids,
  );
}
