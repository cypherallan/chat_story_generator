import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/replay_notification.dart';
import '../../domain/usecases/add_replay_notification.dart';
import '../../domain/usecases/delete_replay_notification.dart';
import '../../domain/usecases/get_replay_notifications.dart';
import 'replay_notification_state.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';

class ReplayNotificationCubit extends Cubit<ReplayNotificationState> {
  final GetReplayNotifications getReplayNotifications;
  final AddReplayNotification addReplayNotification;
  final DeleteReplayNotification deleteReplayNotification;
  final SimulatedNotificationCubit simulatedNotificationCubit;

  ReplayNotificationCubit({
    required this.getReplayNotifications,
    required this.addReplayNotification,
    required this.deleteReplayNotification,
    required this.simulatedNotificationCubit,
  }) : super(const ReplayNotificationState());

  // ===========================================================================
  // LOAD
  // ===========================================================================

  Future<void> loadNotifications() async {
    if (isClosed) return;

    emit(
      state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    try {
      final notifications = await getReplayNotifications();

      if (isClosed) return;

      emit(
        state.copyWith(
          notifications: notifications,
          loading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      if (isClosed) return;

      emit(
        state.copyWith(
          loading: false,
          error: e.toString(),
        ),
      );
    }
  }

  // ===========================================================================
  // CREATE
  // ===========================================================================

  Future<bool> createNotification({
    required String projectId,
    required String senderId,
    required String senderName,
    String? senderAvatarPath,
    required String messageText,
    String? imagePath,
  }) async {
    if (isClosed) return false;

    final notification = ReplayNotification(
      id: const Uuid().v4(),
      projectId: projectId,
      senderId: senderId,
      senderName: senderName,
      senderAvatarPath: senderAvatarPath,
      messageText: messageText,
      imagePath: imagePath,
    );

    try {
      final saved = await addReplayNotification(notification);

      if (isClosed) return false;

      emit(
        state.copyWith(
          notifications: [
            ...state.notifications,
            saved,
          ],
          clearError: true,
        ),
      );

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

  void triggerNotification(
    ReplayNotification notification,
  ) {
    if (isClosed) return;

    simulatedNotificationCubit.showNotification(
      projectId: notification.projectId,
      senderId: notification.senderId,
      senderName: notification.senderName,
      senderAvatarPath: notification.senderAvatarPath,
      messageText: notification.messageText,
      imagePath: notification.imagePath,
    );
  }

  // ===========================================================================
  // DELETE
  // ===========================================================================

  Future<void> removeNotification(
    String id,
  ) async {
    if (isClosed) return;

    try {
      await deleteReplayNotification(id);

      if (isClosed) return;

      final updatedList = state.notifications
          .where(
            (notification) => notification.id != id,
          )
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
