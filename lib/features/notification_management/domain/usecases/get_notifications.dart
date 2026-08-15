import '../entities/notification.dart';
import '../repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  Future<List<Notification>> call() async {
    final result = await repository.getNotifications();

    return result.fold(
      (failure) => throw Exception(failure.message),
      (notifications) => notifications,
    );
  }
}
