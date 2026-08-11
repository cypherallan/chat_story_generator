import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../message_management/domain/usecases/get_messages.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/domain/entities/project.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import '../widgets/replay_conversation_view.dart';
import '../widgets/replay_home_view.dart';

class ConversationPlaybackPage extends StatefulWidget {
  const ConversationPlaybackPage({
    super.key,
  });

  @override
  State<ConversationPlaybackPage> createState() =>
      _ConversationPlaybackPageState();
}

class _ConversationPlaybackPageState
    extends State<ConversationPlaybackPage> {
  late final ConversationReplayCubit _replayCubit;

  @override
  void initState() {
    super.initState();

    _replayCubit = di.sl<ConversationReplayCubit>();

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
          BlocProvider<ConversationReplayCubit>.value(
            value: _replayCubit,
          ),
        ],
        child: BlocBuilder<
            ConversationReplayCubit,
            ConversationReplayState>(
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
    return ReplayHomeView(
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

    final projectState =
        context.watch<ProjectCubit>().state;

    final personState =
        context.watch<PersonCubit>().state;

    if (projectState is! ProjectLoaded ||
        personState is! PersonLoaded) {
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
      onBack: _replayCubit.showHome,
    );
  }

  Future<void> _openReplayConversation(
    BuildContext context,
    Project project,
  ) async {
    final result =
        await di.sl<GetMessages>()(project.id).first;

    if (!mounted) return;

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
          ),
        );
      },
      (messages) {
        _replayCubit.load(
          messages,
          project.ownerId,
        );

        _replayCubit.openConversation(
          project.id,
        );
      },
    );
  }
}