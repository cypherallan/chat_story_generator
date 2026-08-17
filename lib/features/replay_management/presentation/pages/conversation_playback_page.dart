import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../message_management/domain/usecases/get_messages.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/domain/entities/project.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';
import '../../../project_management/domain/usecases/get_projects.dart';
import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import '../widgets/replay_conversation_view.dart';
import '../widgets/replay_home_view.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';

class ConversationPlaybackPage extends StatefulWidget {
  final String ownerId;

  const ConversationPlaybackPage({
    super.key,
    required this.ownerId,
  });

  @override
  State<ConversationPlaybackPage> createState() =>
      _ConversationPlaybackPageState();
}

class _ConversationPlaybackPageState extends State<ConversationPlaybackPage> {
  late final SimulatedNotificationCubit _notificationCubit;
  late final ConversationReplayCubit _replayCubit;

  @override
  void initState() {
    super.initState();

    _notificationCubit = di.sl<SimulatedNotificationCubit>();

    _replayCubit = ConversationReplayCubit(
      notificationCubit: _notificationCubit,
      getMessages: di.sl<GetMessages>(),
      getProjects: di.sl<GetProjects>(),
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
          BlocProvider<ProjectCubit>(
            create: (_) => di.sl<ProjectCubit>()..loadProjects(),
          ),
          BlocProvider<PersonCubit>(
            create: (_) => di.sl<PersonCubit>()..loadPersons(),
          ),
          BlocProvider<SimulatedNotificationCubit>.value(
            value: _notificationCubit,
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

            return _buildHome(context);
          },
        ),
      ),
    );
  }

  Widget _buildHome(BuildContext context) {
    final personState = context.watch<PersonCubit>().state;
    final projectState = context.watch<ProjectCubit>().state;

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

    final projectState = context.watch<ProjectCubit>().state;

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

    final List<Person> persons = personState.persons;

    return ReplayConversationView(
      project: project,
      persons: persons,
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
    context.read<SimulatedNotificationCubit>().clear();
    final personState = context.read<PersonCubit>().state;

    if (personState is! PersonLoaded) {
      return;
    }

    final projectsResult = await di.sl<GetProjects>()();

    if (!mounted) return;

    final messagesResult = await di.sl<GetMessages>()(project.id).first;

    if (!mounted) return;

    projectsResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
          ),
        );
      },
      (projects) {
        messagesResult.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message),
              ),
            );
          },
          (messages) async {
            _replayCubit.load(
              messages,
              widget.ownerId,
              personState.persons,
            );

            _replayCubit.openConversation(
              project.id,
            );
          },
        );
      },
    );
  }
}
