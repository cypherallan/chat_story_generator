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
import '../../../message_management/domain/entities/message.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';
import '../../../notification_management/domain/usecases/get_notifications.dart';

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
            // ------------------------------------------------------------
            // LOAD THE CONVERSATION FIRST
            // ------------------------------------------------------------

            _replayCubit.load(
              messages,
              widget.ownerId,
              personState.persons,
              project.id,
            );

            // ------------------------------------------------------------
            // ASK WHERE REPLAY SHOULD START
            // ------------------------------------------------------------

            final startTime = await _showReplayStartTimePicker(
              context,
              messages,
            );

            if (!mounted || startTime == null) {
              return;
            }

            // ------------------------------------------------------------
            // SAVE THE SELECTED START TIME
            // ------------------------------------------------------------

            _replayCubit.setReplayStartTime(startTime);

            // ------------------------------------------------------------
            // OPEN THE CONVERSATION
            // ------------------------------------------------------------

            _replayCubit.openConversation(
              project.id,
            );
          },
        );
      },
    );
  }

  Future<DateTime?> _showReplayStartTimePicker(
    BuildContext context,
    List<Message> messages,
  ) async {
    if (messages.isEmpty) {
      return null;
    }

    final sortedMessages = List<Message>.from(messages)
      ..sort(
        (a, b) => a.createdAt.compareTo(b.createdAt),
      );

    final firstMessageTime = sortedMessages.first.createdAt;
    final lastMessageTime = sortedMessages.last.createdAt;

    DateTime selectedDate = firstMessageTime;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(
      firstMessageTime,
    );

    final result = await showDialog<DateTime>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final selectedDateTime = DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );

            return AlertDialog(
              title: const Text('Replay starting point'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose where you want the replay to begin.',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Start replay from',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      MaterialLocalizations.of(context)
                          .formatMediumDate(selectedDate),
                    ),
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(
                          firstMessageTime.year,
                          firstMessageTime.month,
                          firstMessageTime.day,
                        ),
                        lastDate: DateTime(
                          lastMessageTime.year,
                          lastMessageTime.month,
                          lastMessageTime.day,
                        ),
                      );

                      if (pickedDate != null) {
                        setDialogState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time),
                    title: Text(
                      selectedTime.format(context),
                    ),
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );

                      if (pickedTime != null) {
                        setDialogState(() {
                          selectedTime = pickedTime;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available: '
                    '${MaterialLocalizations.of(context).formatMediumDate(firstMessageTime)} '
                    '${TimeOfDay.fromDateTime(firstMessageTime).format(context)}'
                    ' – '
                    '${MaterialLocalizations.of(context).formatMediumDate(lastMessageTime)} '
                    '${TimeOfDay.fromDateTime(lastMessageTime).format(context)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('CANCEL'),
                ),
                FilledButton(
                  onPressed: () {
                    if (selectedDateTime.isBefore(firstMessageTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Start time cannot be before the first message.',
                          ),
                        ),
                      );
                      return;
                    }

                    if (selectedDateTime.isAfter(lastMessageTime)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Start time cannot be after the last message.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      selectedDateTime,
                    );
                  },
                  child: const Text('CONTINUE'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }
}
