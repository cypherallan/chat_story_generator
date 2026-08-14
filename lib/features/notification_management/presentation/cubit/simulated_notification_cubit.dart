import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/simulated_notification.dart';
import 'simulated_notification_state.dart';

class SimulatedNotificationCubit extends Cubit<SimulatedNotificationState> {
  SimulatedNotificationCubit() : super(const SimulatedNotificationState());

  /// Immediately displays a prepared notification.
  ///
  /// This does NOT create a Firebase message.
  /// This does NOT modify any chat.
  /// This simply makes the notification visible on screen.
  void triggerNotification(
    SimulatedNotification notification,
  ) {
    emit(
      state.copyWith(
        notification: notification,
        visible: true,
      ),
    );
  }

  /// Convenience method for creating and immediately displaying
  /// a notification.
  void showNotification({
    required String projectId,
    required String senderId,
    required String senderName,
    String? senderAvatarPath,
    required String messageText,
    String? imagePath,
  }) {
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
    emit(
      state.copyWith(
        visible: false,
      ),
    );
  }

  void clear() {
    emit(const SimulatedNotificationState());
  }

  @override
  Future<void> close() {
    return super.close();
  }
}
