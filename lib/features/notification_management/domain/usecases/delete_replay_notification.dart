import '../repositories/replay_notification_repository.dart';

class DeleteReplayNotification {
  final ReplayNotificationRepository repository;

  DeleteReplayNotification(this.repository);

  Future<void> call(String id) async {
    final result = await repository.deleteNotification(id);

    result.fold(
      (failure) => throw Exception(failure.message),
      (_) {},
    );
  }
}
