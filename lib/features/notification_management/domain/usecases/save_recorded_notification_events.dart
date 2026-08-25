import '../repositories/notification_repository.dart';

class SaveRecordedNotificationEvents {
  final NotificationRepository repository;

  SaveRecordedNotificationEvents(this.repository);

  Future<void> call(
    String projectId,
    List<Map<String, dynamic>> events,
  ) async {
    final result = await repository.saveRecordedNotificationEvents(
      projectId,
      events,
    );

    result.fold(
      (failure) => throw Exception(failure.message),
      (_) {},
    );
  }
}
