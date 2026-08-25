import '../repositories/notification_repository.dart';

class GetRecordedNotificationEvents {
  final NotificationRepository repository;

  GetRecordedNotificationEvents(this.repository);

  Future<List<Map<String, dynamic>>> call(
    String projectId,
  ) async {
    final result = await repository.getRecordedNotificationEvents(
      projectId,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (events) => events,
    );
  }
}
