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
import '../../../notification_management/presentation/widgets/simulated_notification_banner.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';

import '../widgets/conversation_notification_actions.dart';

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
  late final ConversationNotificationActions _notificationActions;

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

  void _openCreateNotification() {
    final projectState = context.read<ProjectCubit>().state;
    final personState = context.read<PersonCubit>().state;

    if (projectState is! ProjectLoaded) return;
    if (personState is! PersonLoaded) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<ProjectCubit>()),
            BlocProvider.value(value: context.read<PersonCubit>()),
            BlocProvider.value(value: context.read<MessageCubit>()),
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
    _notificationActions = ConversationNotificationActions(
      context: context,
      currentProject: widget.project,
      simulatedNotificationCubit: _simulatedNotificationCubit,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final body = _bodyKey.currentState;

      if (body != null) {
        context.read<PersonCubit>().setPersonOnline(body.selectedSenderId);
      }

      // Existing: clear unread badge
      context.read<ProjectCubit>().clearUnreadCount(widget.project.id);
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
      child: PopScope(
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
                  builder: (_) => ConversationPlaybackPage(
                    ownerId: widget.project.ownerId,
                    notificationCubit: _simulatedNotificationCubit,
                  ),
                ),
              );
            },
            onCreateNotification: _openCreateNotification,
            onTriggerNotification:
                _notificationActions.triggerReplayNotification,
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
                  onTap: _notificationActions.onNotificationTapped,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
