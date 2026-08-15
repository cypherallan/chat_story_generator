import '../repositories/notification_repository.dart';

class DeleteNotification {
  final NotificationRepository repository;

  DeleteNotification(this.repository);

  Future<void> call(String notificationId) async {
    final result = await repository.deleteNotification(notificationId);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (_) {},
    );
  }
}
