import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class UpdateNotification {
  final NotificationRepository repository;

  UpdateNotification(this.repository);

  Future<Notification> call(Notification notification) async {
    final result = await repository.updateNotification(notification);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (notification) => notification,
    );
  }
}
