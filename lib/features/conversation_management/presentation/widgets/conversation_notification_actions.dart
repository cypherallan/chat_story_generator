import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../message_management/domain/entities/message.dart';
import '../../../message_management/domain/entities/message_status.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../notification_management/domain/entities/simulated_notification.dart';
import '../../../notification_management/presentation/cubit/notification_cubit.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/domain/entities/project.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';
import '../pages/conversation_page.dart';
import 'trigger_replay_notification_sheet.dart';

/// All notification-related actions that previously lived inside ConversationPage.
class ConversationNotificationActions {
  ConversationNotificationActions({
    required this.context,
    required this.currentProject,
    required this.simulatedNotificationCubit,
  });

  final BuildContext context;
  final Project currentProject;
  final SimulatedNotificationCubit simulatedNotificationCubit;

  Future<void> onNotificationTapped(
    SimulatedNotification notification,
  ) async {
    final projectCubit = context.read<ProjectCubit>();
    final personCubit = context.read<PersonCubit>();
    final messageCubit = context.read<MessageCubit>();

    final projectState = projectCubit.state;

    if (projectState is! ProjectLoaded) {
      return;
    }

    final matches = projectState.projects.where(
      (project) => project.id == notification.projectId,
    );

    if (matches.isEmpty) {
      return;
    }

    final project = matches.first;

    await projectCubit.clearUnreadCount(project.id);

    if (!context.mounted) {
      return;
    }

    if (project.id == currentProject.id) {
      // Same conversation – just record the tap with current message count
      final currentCount = messageCubit.state is MessageLoaded
          ? (messageCubit.state as MessageLoaded).messages.length
          : 0;
      simulatedNotificationCubit.recordTap(targetVisibleCount: currentCount);
      return;
    }
    simulatedNotificationCubit.recordTap(targetVisibleCount: 0);
    // -----------------------------------------------------------------

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: projectCubit),
            BlocProvider<MessageCubit>(
              create: (_) {
                final cubit = di.sl<MessageCubit>();
                cubit.loadMessages(project.id);
                return cubit;
              },
            ),
            BlocProvider.value(value: personCubit),
            BlocProvider(
              create: (_) => di.sl<SimulatedNotificationCubit>(),
            ),
          ],
          child: BlocProvider(
            create: (_) => di.sl<SimulatedNotificationCubit>(),
            child: ConversationPage(project: project),
          ),
        ),
      ),
    );

    if (context.mounted) {
      await projectCubit.loadProjects();
    }
  }

  Future<void> triggerReplayNotification() async {
    final notificationCubit = di.sl<NotificationCubit>();

    await notificationCubit.loadNotifications();

    if (!context.mounted) {
      return;
    }

    final notifications = notificationCubit.state.notifications;

    if (notifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No replay notifications have been created yet.'),
        ),
      );
      return;
    }

    final selectedNotification = await showTriggerReplayNotificationSheet(
      context,
      notifications,
    );

    if (!context.mounted || selectedNotification == null) {
      return;
    }

    final project = await context
        .read<ProjectCubit>()
        .findProject(selectedNotification.projectId);

    if (project == null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The conversation for this notification no longer exists.',
          ),
        ),
      );
      return;
    }

    // ------------------------------------------------------------
    // DETERMINE WHERE THE NOTIFICATION SHOULD APPEAR IN REPLAY
    // ------------------------------------------------------------

    final messageState = context.read<MessageCubit>().state;

    int triggerMessageIndex = 0;

    if (messageState is MessageLoaded) {
      triggerMessageIndex = messageState.messages.length;
    }

    final messageCubit = context.read<MessageCubit>();

    final added = await messageCubit.addNotificationMessage(
      projectId: selectedNotification.projectId,
      messageId: selectedNotification.messageId,
      senderId: selectedNotification.senderId,
      senderName: selectedNotification.senderName,
      text: selectedNotification.messageText,
      imagePath: selectedNotification.imagePath,
    );

    if (!added) {
      return;
    }

    final message = Message(
      id: selectedNotification.messageId,
      projectId: selectedNotification.projectId,
      senderId: selectedNotification.senderId,
      senderName: selectedNotification.senderName,
      text: selectedNotification.messageText,
      imagePath: selectedNotification.imagePath,
      createdAt: DateTime.now(),
      status: MessageStatus.delivered,
      isUnread: true,
    );

    await context.read<ProjectCubit>().recordIncomingMessage(
          projectId: selectedNotification.projectId,
          message: message,
        );

    if (!context.mounted) {
      return;
    }
// ------------------------------------------------------------
// UPDATE THE PERSISTED NOTIFICATION WITH THE TRIGGER INDEX
// ------------------------------------------------------------

    final updatedNotification = selectedNotification.copyWith(
      triggerMessageIndex: triggerMessageIndex,
    );

// Persist the trigger index so replay can use it later
    await notificationCubit.updateNotification(updatedNotification);

// ------------------------------------------------------------
// SHOW THE SIMULATED NOTIFICATION
// (now also records the SOURCE conversation context)
// ------------------------------------------------------------

    simulatedNotificationCubit.triggerSavedNotification(
      updatedNotification,
      triggerMessageIndex: triggerMessageIndex,
      sourceProjectId: currentProject.id, // A/B
      sourceTriggerIndex: triggerMessageIndex, // position in A/B
    );
  }
}
