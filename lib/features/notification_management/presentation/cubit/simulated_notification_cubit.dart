import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/notification.dart' as notification_entity;
import '../../domain/entities/simulated_notification.dart';
import 'simulated_notification_state.dart';

enum NotificationInteraction {
  none,
  tapped,
  swiped,
  expired,
}

class SimulatedNotificationCubit extends Cubit<SimulatedNotificationState> {
  SimulatedNotificationCubit() : super(const SimulatedNotificationState());

  Timer? _hideTimer;

  // Records what happened to the notification in the normal conversation.
  NotificationInteraction _interaction = NotificationInteraction.none;
  SimulatedNotification? _recordedNotification;

  NotificationInteraction get interaction => _interaction;
  SimulatedNotification? get recordedNotification => _recordedNotification;

  SimulatedNotification? get currentNotification => state.notification;

  bool get hasRecordedInteraction =>
      _interaction != NotificationInteraction.none;

  // ---------------------------------------------------------------------------
  // RECORDED NOTIFICATION ACTIONS
  // ---------------------------------------------------------------------------

  void recordTap() {
    if (isClosed) return;

    _interaction = NotificationInteraction.tapped;

    hideNotification();
  }

  void recordSwipe() {
    if (isClosed) return;

    _interaction = NotificationInteraction.swiped;

    hideNotification();
  }

  void recordExpired() {
    if (isClosed) return;

    _interaction = NotificationInteraction.expired;

    hideNotification();
  }

  // ---------------------------------------------------------------------------
  // TRIGGER SAVED NOTIFICATION
  // ---------------------------------------------------------------------------

  void triggerSavedNotification(
    notification_entity.Notification notification, {
    int? triggerMessageIndex,
  }) {
    if (isClosed) return;

    final simulatedNotification = SimulatedNotification(
      id: notification.id,
      projectId: notification.projectId,
      messageId: notification.messageId,
      triggerMessageIndex: triggerMessageIndex,
      senderId: notification.senderId,
      senderName: notification.senderName,
      senderAvatarPath: notification.senderAvatarPath,
      messageText: notification.messageText,
      imagePath: notification.imagePath,
      createdAt: DateTime.now(),
    );

    triggerNotification(simulatedNotification);
  }

  // ---------------------------------------------------------------------------
  // SHOW NOTIFICATION
  // ---------------------------------------------------------------------------

  void triggerNotification(
    SimulatedNotification notification,
  ) {
    if (isClosed) return;

    _hideTimer?.cancel();
    _hideTimer = null;

    // A new notification starts a new recorded replay event.
    _interaction = NotificationInteraction.none;
    _recordedNotification = notification;

    emit(
      state.copyWith(
        notification: notification,
        visible: true,
      ),
    );

    // If the user does nothing for 5 seconds,
    // record that the notification expired.
    _hideTimer = Timer(
      const Duration(seconds: 5),
      () {
        if (isClosed) return;

        recordExpired();
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CREATE UNSAVED / DIRECT NOTIFICATION
  // ---------------------------------------------------------------------------

  void showNotification({
    required String projectId,
    required String messageId,
    int? triggerMessageIndex,
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
      triggerMessageIndex: triggerMessageIndex,
      senderId: senderId,
      senderName: senderName,
      senderAvatarPath: senderAvatarPath,
      messageText: messageText,
      imagePath: imagePath,
      createdAt: DateTime.now(),
    );

    triggerNotification(notification);
  }

  // ---------------------------------------------------------------------------
  // HIDE NOTIFICATION
  // ---------------------------------------------------------------------------

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

  void hideNotificationPreserveInteraction() {
    if (isClosed) return;

    _hideTimer?.cancel();
    _hideTimer = null;

    emit(
      state.copyWith(
        visible: false,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CLEAR
  // ---------------------------------------------------------------------------

  void clear() {
    if (isClosed) return;

    _hideTimer?.cancel();
    _hideTimer = null;

    emit(
      const SimulatedNotificationState(),
    );
  }

  // ---------------------------------------------------------------------------
  // CLOSE
  // ---------------------------------------------------------------------------

  @override
  Future<void> close() {
    _hideTimer?.cancel();
    _hideTimer = null;

    return super.close();
  }
}
