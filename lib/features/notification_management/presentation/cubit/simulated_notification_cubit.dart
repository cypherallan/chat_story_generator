import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/simulated_notification.dart';
import 'simulated_notification_state.dart';
import 'dart:async';

class SimulatedNotificationCubit extends Cubit<SimulatedNotificationState> {
  SimulatedNotificationCubit() : super(const SimulatedNotificationState());

  Timer? _hideTimer;

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
