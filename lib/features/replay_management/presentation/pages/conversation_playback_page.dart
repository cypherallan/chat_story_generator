import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../message_management/domain/usecases/get_messages.dart';
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

enum _ReplayStartChoice {
  time,
  message,
}

class _ReplayStartSelection {
  final _ReplayStartChoice choice;
  final DateTime? startTime;
  final String? messageId;

  const _ReplayStartSelection({
    required this.choice,
    this.startTime,
    this.messageId,
  });
}

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
            if (messages.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'This conversation has no messages to replay.',
                  ),
                ),
              );
              return;
            }

            // ------------------------------------------------------------
            // LOAD THE COMPLETE CONVERSATION FIRST
            // ------------------------------------------------------------

            _replayCubit.load(
              messages,
              widget.ownerId,
              personState.persons,
              project.id,
            );

            // ------------------------------------------------------------
            // ASK HOW THE REPLAY SHOULD START
            // ------------------------------------------------------------

            final selection = await _showReplayStartSelection(
              context,
              messages,
            );

            if (!mounted || selection == null) {
              return;
            }

            // ------------------------------------------------------------
            // APPLY THE SELECTED START METHOD
            // ------------------------------------------------------------

            if (selection.choice == _ReplayStartChoice.time) {
              final startTime = selection.startTime;

              if (startTime == null) {
                return;
              }

              _replayCubit.setReplayStartTime(startTime);
            } else {
              final messageId = selection.messageId;

              if (messageId == null) {
                return;
              }

              _replayCubit.setReplayStartMessage(messageId);
            }

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

  // ===========================================================================
  // START METHOD SELECTION
  // ===========================================================================

  Future<_ReplayStartSelection?> _showReplayStartSelection(
    BuildContext context,
    List<Message> messages,
  ) async {
    final sortedMessages = List<Message>.from(messages)
      ..sort(
        (a, b) => a.createdAt.compareTo(b.createdAt),
      );

    final result = await showDialog<_ReplayStartSelection>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Where do you want the replay to start from?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Choose method:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ----------------------------------------------------------
              // TIME
              // ----------------------------------------------------------

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: const Text(
                  'Choose a time to start the replay from.',
                ),
                onTap: () async {
                  final startTime = await _showReplayStartTimePicker(
                    dialogContext,
                    sortedMessages,
                  );

                  if (startTime != null && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(
                      _ReplayStartSelection(
                        choice: _ReplayStartChoice.time,
                        startTime: startTime,
                      ),
                    );
                  }
                },
              ),

              const Divider(),

              // ----------------------------------------------------------
              // MESSAGE
              // ----------------------------------------------------------

              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.message_outlined),
                title: const Text('Message'),
                subtitle: const Text(
                  'Choose a message to start replay after.',
                ),
                onTap: () async {
                  final messageId = await _showReplayStartMessagePicker(
                    dialogContext,
                    sortedMessages,
                  );

                  if (messageId != null && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(
                      _ReplayStartSelection(
                        choice: _ReplayStartChoice.message,
                        messageId: messageId,
                      ),
                    );
                  }
                },
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
          ],
        );
      },
    );

    return result;
  }

  // ===========================================================================
  // TIME PICKER
  // ===========================================================================

  Future<DateTime?> _showReplayStartTimePicker(
    BuildContext context,
    List<Message> messages,
  ) async {
    if (messages.isEmpty) {
      return null;
    }

    final firstMessageTime = messages.first.createdAt;
    final lastMessageTime = messages.last.createdAt;

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
              title: const Text('Replay starting time'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose the time where the replay should begin.',
                  ),
                  const SizedBox(height: 20),
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

  // ===========================================================================
  // MESSAGE PICKER
  // ===========================================================================

  Future<String?> _showReplayStartMessagePicker(
    BuildContext context,
    List<Message> messages,
  ) async {
    if (messages.isEmpty) {
      return null;
    }

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Choose a message',
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.55,
            child: ListView.separated(
              itemCount: messages.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final message = messages[index];

                final time = TimeOfDay.fromDateTime(
                  message.createdAt,
                ).format(context);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  title: Text(
                    message.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(time),
                  onTap: () {
                    Navigator.of(dialogContext).pop(
                      message.id,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('CANCEL'),
            ),
          ],
        );
      },
    );
  }
}
