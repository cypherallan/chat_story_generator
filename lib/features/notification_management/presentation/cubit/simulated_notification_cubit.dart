import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/simulated_notification.dart';
import 'simulated_notification_state.dart';

class SimulatedNotificationCubit extends Cubit<SimulatedNotificationState> {
  Timer? _hideTimer;

  SimulatedNotificationCubit() : super(const SimulatedNotificationState());

  void showNotification({
    required String projectId,
    required String senderId,
    required String senderName,
    String? senderAvatarPath,
    required String messageText,
    String? imagePath,
    Duration duration = const Duration(seconds: 4),
  }) {
    _hideTimer?.cancel();

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

    emit(
      state.copyWith(
        notification: notification,
        visible: true,
      ),
    );

    _hideTimer = Timer(
      duration,
      hideNotification,
    );
  }

  void hideNotification() {
    _hideTimer?.cancel();
    _hideTimer = null;

    emit(
      state.copyWith(
        visible: false,
      ),
    );
  }

  void clear() {
    _hideTimer?.cancel();
    _hideTimer = null;

    emit(
      state.copyWith(
        visible: false,
        clearNotification: true,
      ),
    );
  }

  @override
  Future<void> close() {
    _hideTimer?.cancel();
    return super.close();
  }
}
