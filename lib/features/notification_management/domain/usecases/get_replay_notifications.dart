import '../entities/replay_notification.dart';
import '../repositories/replay_notification_repository.dart';

class GetReplayNotifications {
  final ReplayNotificationRepository repository;

  GetReplayNotifications(this.repository);

  Future<List<ReplayNotification>> call() async {
    final result = await repository.getNotifications();

    return result.fold(
      (failure) => throw Exception(failure.message),
      (notifications) => notifications,
    );
  }
}
