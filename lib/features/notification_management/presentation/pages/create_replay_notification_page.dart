import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../project_management/domain/entities/project.dart';
import '../../domain/entities/replay_notification.dart';
import '../cubit/replay_notification_cubit.dart';
import '../cubit/replay_notification_state.dart';

class CreateReplayNotificationPage extends StatefulWidget {
  final List<Project> projects;
  final List<Person> persons;

  const CreateReplayNotificationPage({
    super.key,
    required this.projects,
    required this.persons,
  });

  @override
  State<CreateReplayNotificationPage> createState() =>
      _CreateReplayNotificationPageState();
}

class _CreateReplayNotificationPageState
    extends State<CreateReplayNotificationPage> {
  final TextEditingController _messageController = TextEditingController();

  String? _selectedProjectId;
  String? _selectedPersonId;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReplayNotificationCubit>().loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Project? get _selectedProject {
    if (_selectedProjectId == null) {
      return null;
    }

    for (final project in widget.projects) {
      if (project.id == _selectedProjectId) {
        return project;
      }
    }

    return null;
  }

  List<Person> get _availablePersons {
    final project = _selectedProject;

    if (project == null) {
      return widget.persons;
    }

    final participantIds = project.participantIds.toSet();

    return widget.persons
        .where(
          (person) => participantIds.contains(person.id),
        )
        .toList();
  }

  Person? get _selectedPerson {
    if (_selectedPersonId == null) {
      return null;
    }

    for (final person in widget.persons) {
      if (person.id == _selectedPersonId) {
        return person;
      }
    }

    return null;
  }

  Future<void> _save() async {
    final project = _selectedProject;
    final person = _selectedPerson;
    final message = _messageController.text.trim();

    if (project == null) {
      _showError('Please select a chat.');
      return;
    }

    if (person == null) {
      _showError(
        'Please select the person sending the notification.',
      );
      return;
    }

    if (message.isEmpty) {
      _showError('Please enter a message.');
      return;
    }

    final success =
        await context.read<ReplayNotificationCubit>().createNotification(
              projectId: project.id,
              senderId: person.id,
              senderName: person.name,
              senderAvatarPath: person.avatarPath,
              messageText: message,
            );

    if (!mounted) {
      return;
    }

    if (!success) {
      final error = context.read<ReplayNotificationCubit>().state.error;

      _showError(
        error ?? 'Failed to save notification.',
      );

      return;
    }

    _messageController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notification saved for replay.',
        ),
      ),
    );
  }

  Future<void> _trigger(ReplayNotification notification) async {
    await context
        .read<ReplayNotificationCubit>()
        .triggerNotification(notification);
  }

  Future<void> _delete(ReplayNotification notification) async {
    await context
        .read<ReplayNotificationCubit>()
        .removeNotification(notification.id);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notification deleted.',
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String _projectName(String projectId) {
    for (final project in widget.projects) {
      if (project.id == projectId) {
        return project.title;
      }
    }

    return 'Unknown chat';
  }

  @override
  Widget build(BuildContext context) {
    final availablePersons = _availablePersons;

    if (_selectedPersonId != null &&
        !availablePersons.any(
          (person) => person.id == _selectedPersonId,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedPersonId = null;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Replay Notifications'),
      ),
      body: BlocBuilder<ReplayNotificationCubit, ReplayNotificationState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Create a notification and manually trigger it '
                'whenever you want during playback.',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              // ============================================================
              // CREATE NOTIFICATION
              // ============================================================

              const Text(
                'Create Notification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedProjectId,
                decoration: const InputDecoration(
                  labelText: 'Chat',
                  border: OutlineInputBorder(),
                ),
                items: widget.projects.map(
                  (project) {
                    return DropdownMenuItem<String>(
                      value: project.id,
                      child: Text(project.title),
                    );
                  },
                ).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProjectId = value;
                    _selectedPersonId = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedPersonId,
                decoration: const InputDecoration(
                  labelText: 'Person',
                  border: OutlineInputBorder(),
                ),
                items: availablePersons.map(
                  (person) {
                    return DropdownMenuItem<String>(
                      value: person.id,
                      child: Text(person.name),
                    );
                  },
                ).toList(),
                onChanged: availablePersons.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedPersonId = value;
                        });
                      },
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  hintText: 'Enter the notification message...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: state.loading ? null : _save,
                  child: const Text(
                    'SAVE NOTIFICATION',
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ============================================================
              // SAVED NOTIFICATIONS
              // ============================================================

              const Text(
                'Saved Notifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              if (state.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    'No replay notifications created yet.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                )
              else
                ...state.notifications.map(
                  (notification) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notification.senderName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _projectName(
                                notification.projectId,
                              ),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notification.messageText,
                              style: const TextStyle(
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  tooltip: 'Delete',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                  ),
                                  onPressed: () {
                                    _delete(notification);
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _trigger(notification);
                                  },
                                  icon: const Icon(
                                    Icons.notifications_active,
                                  ),
                                  label: const Text(
                                    'TRIGGER',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
