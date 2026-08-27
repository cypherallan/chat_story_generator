import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/notification.dart';
import '../../domain/usecases/add_notification.dart';
import '../../domain/usecases/delete_notification.dart';
import '../../domain/usecases/get_notifications.dart';
import '../../domain/usecases/update_notification.dart';
import 'simulated_notification_cubit.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final GetNotifications getNotifications;
  final AddNotification addNotification;
  final UpdateNotification updateNotificationUseCase;
  final DeleteNotification deleteNotification;
  final SimulatedNotificationCubit simulatedNotificationCubit;

  NotificationCubit({
    required this.getNotifications,
    required this.addNotification,
    required this.updateNotificationUseCase,
    required this.deleteNotification,
    required this.simulatedNotificationCubit,
  }) : super(const NotificationState());

  Future<void> loadNotifications() async {
    if (isClosed) return;
    emit(state.copyWith(loading: true, clearError: true));
    try {
      final notifications = await getNotifications();
      if (isClosed) return;
      // NEWEST FIRST
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(state.copyWith(notifications: notifications, loading: false));
    } catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<bool> createNotification({
    required String projectId,
    required String messageId,
    int? triggerMessageIndex,
    required String senderId,
    required String senderName,
    String? senderAvatarPath,
    required String messageText,
    String? imagePath,
  }) async {
    final notification = Notification(
      id: const Uuid().v4(),
      projectId: projectId,
      messageId: messageId,
      triggerMessageIndex: triggerMessageIndex,
      senderId: senderId,
      senderName: senderName,
      senderAvatarPath: senderAvatarPath,
      messageText: messageText,
      imagePath: imagePath,
      createdAt: DateTime.now(), // <-- NEW
    );
    try {
      final saved = await addNotification(notification);
      if (isClosed) return false;
      final updated = [...state.notifications, saved]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      emit(state.copyWith(notifications: updated, clearError: true));
      return true;
    } catch (e) {
      if (isClosed) return false;

      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );

      return false;
    }
  }

  Future<void> triggerNotification(
    Notification notification,
  ) async {
    if (isClosed) return;

    simulatedNotificationCubit.showNotification(
      projectId: notification.projectId,
      messageId: notification.messageId,
      triggerMessageIndex: notification.triggerMessageIndex,
      senderId: notification.senderId,
      senderName: notification.senderName,
      senderAvatarPath: notification.senderAvatarPath,
      messageText: notification.messageText,
      imagePath: notification.imagePath,
    );
  }

  Future<void> updateNotification(
    Notification notification,
  ) async {
    try {
      final saved = await updateNotificationUseCase(notification);

      if (isClosed) return;

      final updatedList = state.notifications.map((item) {
        if (item.id == saved.id) {
          return saved;
        }

        return item;
      }).toList();

      emit(
        state.copyWith(
          notifications: updatedList,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> removeNotification(String id) async {
    try {
      await deleteNotification(id);

      if (isClosed) return;

      final updatedList = state.notifications
          .where((notification) => notification.id != id)
          .toList();

      emit(
        state.copyWith(
          notifications: updatedList,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          error: e.toString(),
        ),
      );
    }
  }
}
