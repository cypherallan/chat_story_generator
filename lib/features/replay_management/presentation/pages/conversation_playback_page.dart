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
import '../../../message_management/domain/entities/message.dart';
import '../../../message_management/domain/entities/message_status.dart';
import '../../../message_management/domain/usecases/add_message.dart';
import 'package:uuid/uuid.dart';
import '../../../project_management/domain/usecases/update_project.dart';
import '../../../notification_management/presentation/cubit/replay_notification_cubit.dart';

class ConversationPlaybackPage extends StatefulWidget {
  const ConversationPlaybackPage({
    super.key,
  });

  @override
  State<ConversationPlaybackPage> createState() =>
      _ConversationPlaybackPageState();
}

class _ConversationPlaybackPageState extends State<ConversationPlaybackPage> {
  late final SimulatedNotificationCubit _notificationCubit;
  late final ConversationReplayCubit _replayCubit;
  late final AddMessage _addMessage;

  @override
  void initState() {
    super.initState();

    _notificationCubit = di.sl<SimulatedNotificationCubit>();
    _addMessage = di.sl<AddMessage>();

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
          BlocProvider<ReplayNotificationCubit>(
            create: (_) =>
                di.sl<ReplayNotificationCubit>()..loadNotifications(),
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
    return ReplayHomeView(
      onChatTap: (project) {
        _openReplayConversation(
          context,
          project,
        );
      },
    );
  }

  Future<void> _openNotificationChat(
    BuildContext context,
    dynamic notification,
  ) async {
    final projectId = notification.projectId;

    final personState = context.read<PersonCubit>().state;

    if (personState is! PersonLoaded) {
      return;
    }

    // ---------------------------------------------------------------------------
    // 1. Find the target project.
    // ---------------------------------------------------------------------------

    final projectState = context.read<ProjectCubit>().state;

    if (projectState is! ProjectLoaded) {
      return;
    }

    Project? project;

    for (final item in projectState.projects) {
      if (item.id == projectId) {
        project = item;
        break;
      }
    }

    if (project == null) {
      return;
    }

    // ---------------------------------------------------------------------------
    // 2. Create the notification as a real chat message.
    // ---------------------------------------------------------------------------

    final message = Message(
      id: const Uuid().v4(),
      projectId: project.id,
      senderId: notification.senderId,
      senderName: notification.senderName,
      text: notification.messageText,
      imagePath: notification.imagePath,
      createdAt: notification.createdAt,
      status: MessageStatus.delivered,
    );

    // ---------------------------------------------------------------------------
    // 3. Save the message.
    // ---------------------------------------------------------------------------

    final saveResult = await _addMessage(message);

    if (!mounted) {
      return;
    }

    final savedMessage = saveResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
          ),
        );

        return null;
      },
      (saved) => saved,
    );

    if (savedMessage == null) {
      return;
    }

    // ---------------------------------------------------------------------------
    // 4. Update the chat preview.
    // ---------------------------------------------------------------------------

    final updatedProject = project.copyWith(
      lastMessage: savedMessage.text,
      lastMessageImagePath: savedMessage.imagePath,
      lastMessageTime: savedMessage.createdAt,
      lastSenderId: savedMessage.senderId,
      lastMessageStatus: savedMessage.status,
      unreadCount: project.unreadCount + 1,
    );

    final updateResult = await di.sl<UpdateProject>()(updatedProject);

    if (!mounted) {
      return;
    }

    final updateFailed = updateResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
          ),
        );

        return true;
      },
      (_) => false,
    );

    if (updateFailed) {
      return;
    }

    // ---------------------------------------------------------------------------
    // 5. Reload all messages from this chat.
    // ---------------------------------------------------------------------------

    final messagesResult = await di.sl<GetMessages>()(project.id).first;

    if (!mounted) {
      return;
    }

    final messages = messagesResult.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure.message),
          ),
        );

        return <Message>[];
      },
      (messages) => messages,
    );

    // ---------------------------------------------------------------------------
    // 6. Only show messages up to the notification message.
    // ---------------------------------------------------------------------------

    final visibleMessages = messages
        .where(
          (item) => !item.createdAt.isAfter(savedMessage.createdAt),
        )
        .toList();

    // Make absolutely sure the notification message is included.
    if (!visibleMessages.any(
      (item) => item.id == savedMessage.id,
    )) {
      visibleMessages.add(savedMessage);
    }

    visibleMessages.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );

    // ---------------------------------------------------------------------------
    // 7. Load replay data without starting playback.
    // ---------------------------------------------------------------------------

    _replayCubit.load(
      visibleMessages,
      project.ownerId,
      personState.persons,
    );

    _replayCubit.openConversationFromNotification(
      projectId: project.id,
      messages: visibleMessages,
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
      onNotificationTap: (notification) {
        _openNotificationChat(
          context,
          notification,
        );
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
              project.ownerId,
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
