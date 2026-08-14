import '../entities/replay_notification.dart';
import '../repositories/replay_notification_repository.dart';

class UpdateReplayNotification {
  final ReplayNotificationRepository repository;

  UpdateReplayNotification(this.repository);

  Future<ReplayNotification> call(
    ReplayNotification notification,
  ) async {
    final result = await repository.updateNotification(notification);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (notification) => notification,
    );
  }
}
