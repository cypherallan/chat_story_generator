import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/notification.dart' as notification_entity;
import '../../domain/entities/simulated_notification.dart';
import 'simulated_notification_state.dart';
import '../../domain/usecases/save_recorded_notification_events.dart';
import '../../domain/usecases/get_recorded_notification_events.dart';

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
  final int targetVisibleCount;
  final int? returnDelayMs; // NEW: real time you took to press back in A/C

  const RecordedNotificationEvent({
    required this.sourceProjectId,
    required this.sourceTriggerIndex,
    required this.notification,
    required this.interaction,
    required this.targetVisibleCount,
    this.returnDelayMs, // NEW
  });

  RecordedNotificationEvent copyWith({
    String? sourceProjectId,
    int? sourceTriggerIndex,
    SimulatedNotification? notification,
    NotificationInteraction? interaction,
    int? targetVisibleCount,
    int? returnDelayMs,
  }) {
    return RecordedNotificationEvent(
      sourceProjectId: sourceProjectId ?? this.sourceProjectId,
      sourceTriggerIndex: sourceTriggerIndex ?? this.sourceTriggerIndex,
      notification: notification ?? this.notification,
      interaction: interaction ?? this.interaction,
      targetVisibleCount: targetVisibleCount ?? this.targetVisibleCount,
      returnDelayMs: returnDelayMs ?? this.returnDelayMs,
    );
  }
}

class SimulatedNotificationCubit extends Cubit<SimulatedNotificationState> {
  SimulatedNotificationCubit({
    required this.saveRecordedNotificationEvents,
    required this.getRecordedNotificationEvents,
  }) : super(const SimulatedNotificationState());

  final SaveRecordedNotificationEvents saveRecordedNotificationEvents;
  final GetRecordedNotificationEvents getRecordedNotificationEvents;

  Future<void> loadRecordedEvents(String projectId) async {
    if (isClosed) return;

    try {
      final savedEvents = await getRecordedNotificationEvents(projectId);

      if (isClosed) return;

      _recordedEvents.removeWhere(
        (event) => event.sourceProjectId == projectId,
      );

      for (final data in savedEvents) {
        final notificationData =
            Map<String, dynamic>.from(data['notification'] as Map);

        final notification = SimulatedNotification(
          id: notificationData['id'] ?? '',
          projectId: notificationData['projectId'] ?? '',
          messageId: notificationData['messageId'] ?? '',
          triggerMessageIndex: notificationData['triggerMessageIndex'],
          senderId: notificationData['senderId'] ?? '',
          senderName: notificationData['senderName'] ?? '',
          senderAvatarPath: notificationData['senderAvatarPath'],
          messageText: notificationData['messageText'] ?? '',
          imagePath: notificationData['imagePath'],
          createdAt: DateTime.parse(
            notificationData['createdAt'],
          ),
        );

        _recordedEvents.add(
          RecordedNotificationEvent(
            sourceProjectId: data['sourceProjectId'] ?? projectId,
            sourceTriggerIndex: data['sourceTriggerIndex'] ?? 0,
            notification: notification,
            interaction: NotificationInteraction.values.firstWhere(
              (value) => value.name == data['interaction'],
              orElse: () => NotificationInteraction.none,
            ),
            targetVisibleCount: data['targetVisibleCount'] ?? 0,
            returnDelayMs: data['returnDelayMs'] as int?, // NEW
          ),
        );
      }
    } catch (_) {
      // Keep existing in-memory events if loading fails.
    }
  }

  Timer? _hideTimer;

// Records what happened to the notification in the normal conversation.
  NotificationInteraction _interaction = NotificationInteraction.none;
  SimulatedNotification? _recordedNotification;

// ---------- NEW: multi-event recording ----------
  final List<RecordedNotificationEvent> _recordedEvents = [];
  String? _pendingSourceProjectId;
  int? _pendingSourceTriggerIndex;
  DateTime? _notificationOpenedAt;
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
    print(
        '[SimNotif] recordTap targetCount=$targetVisibleCount pendingSrc=$_pendingSourceProjectId pendingIdx=$_pendingSourceTriggerIndex notif=${_recordedNotification?.messageId}');
    if (isClosed) return;

    _interaction = NotificationInteraction.tapped;
    _completePendingEvent(targetVisibleCount);
    hideNotification();
  }

  void recordSwipe({int targetVisibleCount = 0}) {
    print(
        '[SimNotif] recordSwipe targetCount=$targetVisibleCount pendingSrc=$_pendingSourceProjectId pendingIdx=$_pendingSourceTriggerIndex notif=${_recordedNotification?.messageId}');
    if (isClosed) return;

    _interaction = NotificationInteraction.swiped;
    _completePendingEvent(targetVisibleCount);
    hideNotification();
  }

  void recordExpired({int targetVisibleCount = 0}) {
    print(
        '[SimNotif] recordExpired targetCount=$targetVisibleCount pendingSrc=$_pendingSourceProjectId pendingIdx=$_pendingSourceTriggerIndex notif=${_recordedNotification?.messageId}');
    if (isClosed) return;

    _interaction = NotificationInteraction.expired;
    _completePendingEvent(targetVisibleCount);
    hideNotification();
  }

  Future<void> _completePendingEvent(int targetVisibleCount) async {
    print(
        '[SimNotif] _completePendingEvent try src=$_pendingSourceProjectId srcIdx=$_pendingSourceTriggerIndex notifId=${_recordedNotification?.messageId} interaction=$_interaction target=$targetVisibleCount totalBefore=${_recordedEvents.length}');
    if (_pendingSourceProjectId == null ||
        _pendingSourceTriggerIndex == null ||
        _recordedNotification == null) {
      return;
    }

    // prevent double tap race - same msgId already saved
    if (_recordedEvents.any(
        (e) => e.notification.messageId == _recordedNotification!.messageId)) {
      print(
          '[SimNotif] _completePendingEvent SKIP duplicate msgId=${_recordedNotification!.messageId}');
      _pendingSourceProjectId = null;
      _pendingSourceTriggerIndex = null;
      return;
    }

    final event = RecordedNotificationEvent(
      sourceProjectId: _pendingSourceProjectId!,
      sourceTriggerIndex: _pendingSourceTriggerIndex!,
      notification: _recordedNotification!,
      interaction: _interaction,
      targetVisibleCount: targetVisibleCount,
    );

    _recordedEvents.add(event);
    print(
        '[SimNotif] _completePendingEvent ADD src=${event.sourceProjectId} msgId=${event.notification.messageId} totalAfter=${_recordedEvents.length}');

    final projectId = event.sourceProjectId;

    // Clear pending immediately so 2nd tap can't create duplicate with src=null
    _pendingSourceProjectId = null;
    _pendingSourceTriggerIndex = null;

    final events = _recordedEvents
        .where((e) => e.sourceProjectId == projectId)
        .map(
          (e) => {
            'sourceProjectId': e.sourceProjectId,
            'sourceTriggerIndex': e.sourceTriggerIndex,
            'notification': {
              'id': e.notification.id,
              'projectId': e.notification.projectId,
              'messageId': e.notification.messageId,
              'triggerMessageIndex': e.notification.triggerMessageIndex,
              'senderId': e.notification.senderId,
              'senderName': e.notification.senderName,
              'senderAvatarPath': e.notification.senderAvatarPath,
              'messageText': e.notification.messageText,
              'imagePath': e.notification.imagePath,
              'createdAt': e.notification.createdAt.toIso8601String(),
            },
            'interaction': e.interaction.name,
            'targetVisibleCount': e.targetVisibleCount,
          },
        )
        .toList();

    try {
      await saveRecordedNotificationEvents(
        projectId,
        events,
      );
    } catch (_) {
      // Keep the in-memory event even if persistence fails.
    }
  }

  // ---------------------------------------------------------------------------
  // TRIGGER SAVED NOTIFICATION
  // ---------------------------------------------------------------------------

  void triggerSavedNotification(
    notification_entity.Notification notification, {
    int? triggerMessageIndex,
    String? sourceProjectId,
    int? sourceTriggerIndex,
  }) {
    print(
        '[SimNotif] triggerSavedNotification proj=${notification.projectId} msgId=${notification.messageId} sourceProj=$sourceProjectId sourceIdx=$sourceTriggerIndex');
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

    _pendingSourceProjectId = sourceProjectId;
    _pendingSourceTriggerIndex = sourceTriggerIndex;
    _notificationOpenedAt = DateTime.now(); // NEW

    triggerNotification(simulatedNotification);
  }

  // ---------------------------------------------------------------------------
  // SHOW NOTIFICATION
  // ---------------------------------------------------------------------------

  void triggerNotification(
    SimulatedNotification notification,
  ) {
    print(
        '[SimNotif] triggerNotification id=${notification.id} proj=${notification.projectId} msgId=${notification.messageId} triggerIdx=${notification.triggerMessageIndex}');
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

  Future<void> recordBackNavigation() async {
    if (isClosed) return;
    if (_notificationOpenedAt == null) return;
    if (_recordedEvents.isEmpty) return;

    final delay = DateTime.now().difference(_notificationOpenedAt!);
    final delayMs = delay.inMilliseconds;
    print(
        '[SimNotif] recordBackNavigation delayMs=$delayMs lastNotif=${_recordedEvents.last.notification.messageId} proj=${_recordedEvents.last.sourceProjectId}');

    // Update last event with return delay
    final lastIndex = _recordedEvents.length - 1;
    final lastEvent = _recordedEvents[lastIndex];
    _recordedEvents[lastIndex] = lastEvent.copyWith(returnDelayMs: delayMs);

    // Persist
    final projectId = lastEvent.sourceProjectId;
    final events = _recordedEvents
        .where((e) => e.sourceProjectId == projectId)
        .map((e) => {
              'sourceProjectId': e.sourceProjectId,
              'sourceTriggerIndex': e.sourceTriggerIndex,
              'notification': {
                'id': e.notification.id,
                'projectId': e.notification.projectId,
                'messageId': e.notification.messageId,
                'triggerMessageIndex': e.notification.triggerMessageIndex,
                'senderId': e.notification.senderId,
                'senderName': e.notification.senderName,
                'senderAvatarPath': e.notification.senderAvatarPath,
                'messageText': e.notification.messageText,
                'imagePath': e.notification.imagePath,
                'createdAt': e.notification.createdAt.toIso8601String(),
              },
              'interaction': e.interaction.name,
              'targetVisibleCount': e.targetVisibleCount,
              'returnDelayMs': e.returnDelayMs, // NEW
            })
        .toList();

    try {
      await saveRecordedNotificationEvents(projectId, events);
    } catch (_) {}

    _notificationOpenedAt = null;
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
    print(
        '[SimNotif] hideNotificationPreserveInteraction visible=${state.visible} interaction=$_interaction');
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
