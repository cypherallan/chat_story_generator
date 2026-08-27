import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../message_management/domain/usecases/get_messages.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../group_management/domain/entities/project.dart';
import '../../../group_management/presentation/cubit/group_cubit.dart';
import '../../../group_management/domain/usecases/get_projects.dart';
import '../../../notification_management/domain/usecases/get_recorded_notification_events.dart';
import '../../../notification_management/domain/usecases/save_recorded_notification_events.dart';
import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import '../widgets/replay_conversation_view.dart';
import '../widgets/replay_home_view.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';
import '../../../notification_management/domain/usecases/get_notifications.dart';
import '../widgets/replay_start_selection.dart';
import '../../data/services/replay_export_service.dart';
import '../../../message_management/domain/entities/message.dart';

class ConversationPlaybackPage extends StatefulWidget {
  final String ownerId;
  final SimulatedNotificationCubit notificationCubit;

  const ConversationPlaybackPage({
    super.key,
    required this.ownerId,
    required this.notificationCubit,
  });

  @override
  State<ConversationPlaybackPage> createState() =>
      _ConversationPlaybackPageState();
}

class _ConversationPlaybackPageState extends State<ConversationPlaybackPage> {
  late final ConversationReplayCubit _replayCubit;

  @override
  void initState() {
    super.initState();

    _replayCubit = ConversationReplayCubit(
      notificationCubit: widget.notificationCubit,
      getMessages: di.sl<GetMessages>(),
      getProjects: di.sl<GetProjects>(),
      getNotifications: di.sl<GetNotifications>(),
      getRecordedNotificationEvents: di.sl<GetRecordedNotificationEvents>(),
      saveRecordedNotificationEvents: di.sl<SaveRecordedNotificationEvents>(),
      exportService: di.sl<ReplayExportService>(),
    );

    _replayCubit.showHome();
  }

  @override
  void dispose() {
    _replayCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<GroupCubit>(
            create: (_) => di.sl<GroupCubit>()..loadProjects(),
          ),
          BlocProvider<PersonCubit>(
            create: (_) => di.sl<PersonCubit>()..loadPersons(),
          ),
          BlocProvider<SimulatedNotificationCubit>.value(
            value: widget.notificationCubit,
          ),
          BlocProvider<ConversationReplayCubit>.value(
            value: _replayCubit,
          ),
        ],
        child: BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
          builder: (context, replayState) {
            if (replayState.screen == ReplayScreen.conversation) {
              return _buildConversation(
                context,
                replayState,
              );
            }

            return _buildHome(context, replayState);
          },
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context, ConversationReplayState replayState) {
    final personState = context.watch<PersonCubit>().state;
    final projectState = context.watch<GroupCubit>().state;

    if (personState is! PersonLoaded || projectState is! ProjectLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ReplayHomeView(
      projects: projectState.projects,
      ownerId: widget.ownerId,
      highlightedProjectId: replayState.highlightedChatProjectId,
      isChatTapPressed:
          replayState.visualInteraction == ReplayVisualInteraction.chatTap,
      onChatTap: (project) {
        _openReplayConversation(
          context,
          project,
        );
      },
    );
  }

  Widget _buildConversation(
    BuildContext context,
    ConversationReplayState replayState,
  ) {
    final projectId = replayState.currentProjectId;

    if (projectId == null) {
      return const Scaffold(
        body: Center(
          child: Text('Conversation not selected.'),
        ),
      );
    }

    final projectState = context.watch<GroupCubit>().state;
    final personState = context.watch<PersonCubit>().state;

    if (projectState is! ProjectLoaded || personState is! PersonLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    Project? project;

    for (final item in projectState.projects) {
      if (item.id == projectId) {
        project = item;
        break;
      }
    }

    if (project == null) {
      return const Scaffold(
        body: Center(
          child: Text('Project not found.'),
        ),
      );
    }

    return ReplayConversationView(
      project: project,
      persons: personState.persons,
      replayCubit: _replayCubit,
      state: replayState,
      onBack: () {
        context.read<SimulatedNotificationCubit>().clear();
        _replayCubit.showHome();
      },
    );
  }

  Future<void> _openReplayConversation(
    BuildContext context,
    Project project,
  ) async {
    final personState = context.read<PersonCubit>().state;
    if (personState is! PersonLoaded) return;

    final projectsResult = await di.sl<GetProjects>()();
    if (!mounted) return;

    projectsResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      },
      (allProjects) async {
        final List<Message> allMessages = [];
        for (final p in allProjects.where((p) => p.ownerId == widget.ownerId)) {
          final res = await di.sl<GetMessages>()(p.id).first;
          res.fold((_) {}, (msgs) => allMessages.addAll(msgs));
        }
        allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

        final clickedMessages =
            allMessages.where((m) => m.projectId == project.id).toList();
        if (clickedMessages.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('This conversation has no messages to replay.')),
          );
          return;
        }

        _replayCubit.load(
          allMessages,
          widget.ownerId,
          personState.persons,
          project.id,
        );

        final selection =
            await showReplayStartSelection(context, allMessages, project.id);
        if (!mounted || selection == null) return;

        if (selection.choice == ReplayStartChoice.time) {
          final t = selection.startTime;
          if (t != null) _replayCubit.setReplayStartTime(t);
        } else {
          final mid = selection.messageId;
          if (mid != null) _replayCubit.setReplayStartMessage(mid);
        }

        _replayCubit.openConversationViaHome(project.id);
      },
    );
  }
}
