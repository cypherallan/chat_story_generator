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

  Future<void> _triggerReplayNotification() async {
    final notificationCubit = di.sl<NotificationCubit>();

    await notificationCubit.loadNotifications();

    if (!mounted) return;

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
                    leading: const Icon(
                      Icons.notifications_outlined,
                    ),
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

    notificationCubit.triggerNotification(
      selectedNotification,
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final body = _bodyKey.currentState;
      if (body != null) {
        context.read<PersonCubit>().setPersonOnline(body.selectedSenderId);
      }
      context.read<ProjectCubit>().clearUnreadCount(widget.project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        final body = _bodyKey.currentState;
        if (body != null) {
          context.read<PersonCubit>().setPersonOffline(body.selectedSenderId);
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
        body: ConversationPageBody(
          key: _bodyKey,
          project: widget.project,
          onChanged: _onBodyChanged,
        ),
      ),
    );
  }
}
