import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class AddNotification {
  final NotificationRepository repository;

  AddNotification(this.repository);

  Future<Notification> call(Notification notification) async {
    final result = await repository.addNotification(notification);

    return result.fold(
      (failure) => throw Exception(failure.message),
      (notification) => notification,
    );
  }
}
