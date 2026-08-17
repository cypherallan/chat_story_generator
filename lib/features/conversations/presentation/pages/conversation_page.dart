import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';

import '../widgets/conversation_app_bar.dart';
import '../../../replay_management/presentation/pages/conversation_playback_page.dart';
import 'conversation_page_body.dart';
import '../../../../injection_container.dart' as di;
import '../../../notification_management/presentation/cubit/notification_cubit.dart';
import '../../../notification_management/presentation/pages/create_notification_page.dart';
import '../../../notification_management/domain/entities/notification.dart'
    as notification_entity;
import '../../../notification_management/presentation/widgets/simulated_notification_banner.dart';
import '../../../notification_management/domain/entities/simulated_notification.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';

import '../../../../core/presentation/widgets/phone_frame.dart';

class ConversationPage extends StatefulWidget {
  final Project project;

  const ConversationPage({
    super.key,
    required this.project,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final GlobalKey<ConversationPageBodyState> _bodyKey =
      GlobalKey<ConversationPageBodyState>();
  late final SimulatedNotificationCubit _simulatedNotificationCubit;

  // Local mirrors so the AppBar can rebuild
  Set<String> _typingPersonIds = {};
  bool _otherPersonTyping = false;
  Set<String> _selectedMessageIds = {};
  bool _isSelectionMode = false;

  void _onBodyChanged() {
    final body = _bodyKey.currentState;
    if (body == null) return;

    setState(() {
      _typingPersonIds = Set.from(body.typingPersonIds);
      _otherPersonTyping = body.otherPersonTyping;
      _selectedMessageIds = Set.from(body.selectedMessageIds);
      _isSelectionMode = body.isSelectionMode;
    });
  }

  Future<void> _onNotificationTapped(
    SimulatedNotification notification,
  ) async {
    final projectCubit = context.read<ProjectCubit>();
    final personCubit = context.read<PersonCubit>();

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

    final messageCubit = di.sl<MessageCubit>();

    final added = await messageCubit.addNotificationMessage(
      projectId: notification.projectId,
      messageId: notification.messageId,
      senderId: notification.senderId,
      senderName: notification.senderName,
      text: notification.messageText,
      imagePath: notification.imagePath,
    );

    await messageCubit.close();

    if (!added) {
      return;
    }

    await projectCubit.clearUnreadCount(project.id);

    if (!mounted) return;

    if (project.id == widget.project.id) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: projectCubit,
            ),
            BlocProvider(
              create: (_) => di.sl<MessageCubit>()..loadMessages(project.id),
            ),
            BlocProvider.value(
              value: personCubit,
            ),
          ],
          child: BlocProvider(
            create: (_) => di.sl<SimulatedNotificationCubit>(),
            child: ConversationPage(
              project: project,
            ),
          ),
        ),
      ),
    );

    if (mounted) {
      await projectCubit.loadProjects();
    }
  }

  Future<void> _triggerReplayNotification() async {
    final notificationCubit = di.sl<NotificationCubit>();

    await notificationCubit.loadNotifications();

    if (!mounted) {
      return;
    }

    final notifications = notificationCubit.state.notifications;

    if (notifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No replay notifications have been created yet.',
          ),
        ),
      );
      return;
    }

    final selectedNotification =
        await showModalBottomSheet<notification_entity.Notification>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Trigger Replay Notification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ...notifications.map(
                (notification) {
                  return ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: Text(
                      notification.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      notification.messageText.isEmpty
                          ? 'Photo'
                          : notification.messageText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      Navigator.of(sheetContext).pop(notification);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selectedNotification == null) {
      return;
    }

    final messageCubit = context.read<MessageCubit>();
    final projectCubit = context.read<ProjectCubit>();

    final messageCreated = await messageCubit.createNotificationMessage(
      messageId: selectedNotification.messageId,
      projectId: selectedNotification.projectId,
      senderId: selectedNotification.senderId,
      senderName: selectedNotification.senderName,
      text: selectedNotification.messageText,
      imagePath: selectedNotification.imagePath,
    );

    if (!messageCreated) {
      return;
    }

    if (selectedNotification.senderId != widget.project.ownerId) {
      await projectCubit.incrementUnreadCount(
        selectedNotification.projectId,
      );
    } else {}

    if (!mounted) {
      return;
    }

    _simulatedNotificationCubit.triggerSavedNotification(
      selectedNotification,
    );

    await notificationCubit.removeNotification(
      selectedNotification.id,
    );
  }

  void _openCreateNotification() {
    final projectState = context.read<ProjectCubit>().state;
    final personState = context.read<PersonCubit>().state;

    if (projectState is! ProjectLoaded) {
      return;
    }

    if (personState is! PersonLoaded) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: context.read<ProjectCubit>(),
            ),
            BlocProvider.value(
              value: context.read<PersonCubit>(),
            ),
            BlocProvider(
              create: (_) => di.sl<NotificationCubit>()..loadNotifications(),
            ),
          ],
          child: CreateNotificationPage(
            projects: projectState.projects,
            persons: personState.persons,
            currentPersonId: widget.project.ownerId,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();

    _simulatedNotificationCubit = di.sl<SimulatedNotificationCubit>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final body = _bodyKey.currentState;

      if (body != null) {
        context.read<PersonCubit>().setPersonOnline(
              body.selectedSenderId,
            );
      }

      context.read<ProjectCubit>().clearUnreadCount(
            widget.project.id,
          );
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _simulatedNotificationCubit,
      child: PhoneFrame(
        child: PopScope(
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop) return;

            final body = _bodyKey.currentState;

            if (body != null) {
              context.read<PersonCubit>().setPersonOffline(
                    body.selectedSenderId,
                  );
            }

            await context.read<ProjectCubit>().loadProjects();
          },
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: ConversationAppBar(
              project: widget.project,
              isSelectionMode: _isSelectionMode,
              selectedCount: _selectedMessageIds.length,
              typingPersonIds: _typingPersonIds,
              otherPersonTyping: _otherPersonTyping,
              onClearSelection: () =>
                  _bodyKey.currentState?.clearMessageSelection(),
              onPreviewPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConversationPlaybackPage(),
                  ),
                );
              },
              onCreateNotification: _openCreateNotification,
              onTriggerNotification: _triggerReplayNotification,
              selectedMessageIds: _selectedMessageIds,
              onReplySelected: (message) {
                _bodyKey.currentState?.setReplyingTo(message);
              },
              onReactionSelected: (messageId, emoji) {
                context.read<MessageCubit>().toggleReaction(
                      messageId: messageId,
                      userId: widget.project.ownerId,
                      emoji: emoji,
                    );
              },
              onDeleteSelected: () async {
                await _bodyKey.currentState?.deleteSelectedMessages();
              },
            ),
            body: Stack(
              children: [
                ConversationPageBody(
                  key: _bodyKey,
                  project: widget.project,
                  onChanged: _onBodyChanged,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SimulatedNotificationBanner(
                    onTap: _onNotificationTapped,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
