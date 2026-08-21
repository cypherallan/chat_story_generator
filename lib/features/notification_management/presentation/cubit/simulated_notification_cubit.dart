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

class RecordedNotificationEvent {
  final String sourceProjectId;
  final int sourceTriggerIndex;
  final SimulatedNotification notification;
  final NotificationInteraction interaction;
  final int
      targetVisibleCount; // how many messages the target chat had when opened

  const RecordedNotificationEvent({
    required this.sourceProjectId,
    required this.sourceTriggerIndex,
    required this.notification,
    required this.interaction,
    required this.targetVisibleCount,
  });

  RecordedNotificationEvent copyWith({
    String? sourceProjectId,
    int? sourceTriggerIndex,
    SimulatedNotification? notification,
    NotificationInteraction? interaction,
    int? targetVisibleCount,
  }) {
    return RecordedNotificationEvent(
      sourceProjectId: sourceProjectId ?? this.sourceProjectId,
      sourceTriggerIndex: sourceTriggerIndex ?? this.sourceTriggerIndex,
      notification: notification ?? this.notification,
      interaction: interaction ?? this.interaction,
      targetVisibleCount: targetVisibleCount ?? this.targetVisibleCount,
    );
  }
}

class SimulatedNotificationCubit extends Cubit<SimulatedNotificationState> {
  SimulatedNotificationCubit() : super(const SimulatedNotificationState());

  Timer? _hideTimer;

// Records what happened to the notification in the normal conversation.
  NotificationInteraction _interaction = NotificationInteraction.none;
  SimulatedNotification? _recordedNotification;

// ---------- NEW: multi-event recording ----------
  final List<RecordedNotificationEvent> _recordedEvents = [];
  String? _pendingSourceProjectId;
  int? _pendingSourceTriggerIndex;
// -----------------------------------------------

  NotificationInteraction get interaction => _interaction;
  SimulatedNotification? get recordedNotification => _recordedNotification;

  SimulatedNotification? get currentNotification => state.notification;

  bool get hasRecordedInteraction =>
      _interaction != NotificationInteraction.none;

// ---------- NEW getters ----------
  List<RecordedNotificationEvent> get recordedEvents =>
      List.unmodifiable(_recordedEvents);

  void clearRecordedEvents() {
    _recordedEvents.clear();
    _pendingSourceProjectId = null;
    _pendingSourceTriggerIndex = null;
  }
// ---------------------------------;

  // ---------------------------------------------------------------------------
  // RECORDED NOTIFICATION ACTIONS
  // ---------------------------------------------------------------------------

  void recordTap({int targetVisibleCount = 0}) {
    if (isClosed) return;

    _interaction = NotificationInteraction.tapped;
    _completePendingEvent(targetVisibleCount);
    hideNotification();
  }

  void recordSwipe({int targetVisibleCount = 0}) {
    if (isClosed) return;

    _interaction = NotificationInteraction.swiped;
    _completePendingEvent(targetVisibleCount);
    hideNotification();
  }

  void recordExpired({int targetVisibleCount = 0}) {
    if (isClosed) return;

    _interaction = NotificationInteraction.expired;
    _completePendingEvent(targetVisibleCount);
    hideNotification();
  }

  void _completePendingEvent(int targetVisibleCount) {
    if (_pendingSourceProjectId == null ||
        _pendingSourceTriggerIndex == null ||
        _recordedNotification == null) {
      return;
    }

    _recordedEvents.add(
      RecordedNotificationEvent(
        sourceProjectId: _pendingSourceProjectId!,
        sourceTriggerIndex: _pendingSourceTriggerIndex!,
        notification: _recordedNotification!,
        interaction: _interaction,
        targetVisibleCount: targetVisibleCount,
      ),
    );

    // Clear pending so the next notification starts fresh
    _pendingSourceProjectId = null;
    _pendingSourceTriggerIndex = null;
  }

  // ---------------------------------------------------------------------------
  // TRIGGER SAVED NOTIFICATION
  // ---------------------------------------------------------------------------

  void triggerSavedNotification(
    notification_entity.Notification notification, {
    int? triggerMessageIndex,
    String? sourceProjectId, // NEW
    int? sourceTriggerIndex, // NEW
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

    // Remember the source context for later completion of the event
    _pendingSourceProjectId = sourceProjectId;
    _pendingSourceTriggerIndex = sourceTriggerIndex;

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

    _interaction = NotificationInteraction.none;
    _recordedNotification = null;
    _pendingSourceProjectId = null;
    _pendingSourceTriggerIndex = null;
    // NOTE: we deliberately do NOT clear _recordedEvents here
    // so that the playback page can still read them.

    emit(const SimulatedNotificationState());
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
