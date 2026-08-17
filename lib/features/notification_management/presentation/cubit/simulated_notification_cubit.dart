import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/simulated_notification.dart';
import 'simulated_notification_state.dart';
import 'dart:async';
import '../../domain/entities/notification.dart' as notification_entity;

class SimulatedNotificationCubit extends Cubit<SimulatedNotificationState> {
  SimulatedNotificationCubit() : super(const SimulatedNotificationState());

  Timer? _hideTimer;

  void triggerSavedNotification(
    notification_entity.Notification notification,
  ) {
    if (isClosed) return;

    final simulatedNotification = SimulatedNotification(
      id: notification.id,
      projectId: notification.projectId,
      messageId: notification.messageId,
      senderId: notification.senderId,
      senderName: notification.senderName,
      senderAvatarPath: notification.senderAvatarPath,
      messageText: notification.messageText,
      imagePath: notification.imagePath,
      createdAt: DateTime.now(),
    );

    triggerNotification(simulatedNotification);
  }

  void triggerNotification(
    SimulatedNotification notification,
  ) {
    if (isClosed) return;

    _hideTimer?.cancel();

    emit(
      state.copyWith(
        notification: notification,
        visible: true,
      ),
    );

    _hideTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (isClosed) return;

        emit(
          state.copyWith(
            visible: false,
          ),
        );
      },
    );
  }

  void showNotification({
    required String projectId,
    required String messageId,
    required String senderId,
    required String senderName,
    String? senderAvatarPath,
    required String messageText,
    String? imagePath,
  }) {
    if (isClosed) return;

    final notification = SimulatedNotification(
      id: const Uuid().v4(),
      projectId: projectId,
      messageId: messageId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarPath: senderAvatarPath,
      messageText: messageText,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );

    triggerNotification(notification);
  }

  void hideNotification() {
    if (isClosed) return;

    _hideTimer?.cancel();
    _hideTimer = null;

    emit(
      state.copyWith(
        visible: false,
      ),
    );
  }

  void clear() {
    if (isClosed) return;

    _hideTimer?.cancel();
    _hideTimer = null;

    emit(const SimulatedNotificationState());
  }

  @override
  Future<void> close() {
    _hideTimer?.cancel();
    _hideTimer = null;

    return super.close();
  }
}
