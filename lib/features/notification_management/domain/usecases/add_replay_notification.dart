import '../entities/replay_notification.dart';
import '../repositories/replay_notification_repository.dart';

class AddReplayNotification {
  final ReplayNotificationRepository repository;

  AddReplayNotification(this.repository);

  Future<ReplayNotification> call(
    ReplayNotification notification,
  ) async {
    final result = await repository.addNotification(notification);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (notification) => notification,
    );
  }
}
