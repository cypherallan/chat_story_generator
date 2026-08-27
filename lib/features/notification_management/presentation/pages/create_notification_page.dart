import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../group_management/domain/entities/project.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../../domain/entities/notification.dart' as notification_entity;
import '../../../group_management/presentation/cubit/group_cubit.dart';
import 'package:uuid/uuid.dart';

class CreateNotificationPage extends StatefulWidget {
  final List<Project> projects;
  final List<Person> persons;
  final String currentPersonId;

  const CreateNotificationPage({
    super.key,
    required this.projects,
    required this.persons,
    required this.currentPersonId,
  });

  @override
  State<CreateNotificationPage> createState() => _CreateNotificationPageState();
}

class _CreateNotificationPageState extends State<CreateNotificationPage> {
  String? _selectedSenderId;
  Project? _selectedProject;

  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<NotificationCubit>().loadNotifications();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Person? get _selectedSender {
    if (_selectedSenderId == null) {
      return null;
    }

    for (final person in widget.persons) {
      if (person.id == _selectedSenderId) {
        return person;
      }
    }

    return null;
  }

  Project? _findDirectChat({
    required String senderId,
    required String ownerId,
  }) {
    for (final project in widget.projects) {
      if (project.ownerId != ownerId) {
        continue;
      }

      if (project.participantIds.length != 2) {
        continue;
      }

      final participants = project.participantIds.toSet();

      if (participants.contains(senderId) && participants.contains(ownerId)) {
        return project;
      }
    }

    return null;
  }

  void _updateSelectedChat() {
    if (_selectedSenderId == null) {
      setState(() {
        _selectedProject = null;
      });
      return;
    }

    if (_selectedSenderId == widget.currentPersonId) {
      setState(() {
        _selectedProject = null;
      });
      return;
    }

    final project = _findDirectChat(
      senderId: _selectedSenderId!,
      ownerId: widget.currentPersonId,
    );

    setState(() {
      _selectedProject = project;
    });
  }

  Future<void> _save() async {
    final sender = _selectedSender;

    final messageText = _messageController.text.trim();

    if (sender == null) {
      _showError(
        'Please select the contact who will send the notification.',
      );
      return;
    }

    if (messageText.isEmpty) {
      _showError(
        'Please enter the notification message.',
      );
      return;
    }

    final groupCubit = context.read<GroupCubit>();

    // Find the existing conversation or create it automatically.
    final project = await groupCubit.openOrCreatePrivateChat(
      ownerId: widget.currentPersonId,
      contactId: sender.id,
      contactName: sender.name,
    );

    if (!mounted) {
      return;
    }

    // IMPORTANT:
    // Generate ONE ID for the future incoming message.
    //
    // We do NOT create the Message here.
    // The actual Message will be created when this
    // notification is TRIGGERED.
    final messageId = const Uuid().v4();

    final success = await context.read<NotificationCubit>().createNotification(
          projectId: project.id,
          messageId: messageId,
          senderId: sender.id,
          senderName: sender.name,
          senderAvatarPath: sender.avatarPath,
          messageText: messageText,
        );

    if (!mounted) {
      return;
    }

    if (!success) {
      final error = context.read<NotificationCubit>().state.error;

      _showError(
        error ?? 'Failed to save notification.',
      );

      return;
    }

    _messageController.clear();

    // Refresh projects because a new conversation may have been created.
    await groupCubit.loadProjects();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notification saved for later triggering.',
        ),
      ),
    );
  }

  Future<void> _delete(
    notification_entity.Notification notification,
  ) async {
    await context.read<NotificationCubit>().removeNotification(notification.id);

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Replay Notifications'),
      ),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Create notifications here, then trigger them later '
                'from the normal conversation.',
                style: TextStyle(
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Create Notification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // ============================================================
              // CONTACT SENDING THE NOTIFICATION
              // ============================================================

              DropdownButtonFormField<String>(
                value: _selectedSenderId,
                decoration: const InputDecoration(
                  labelText: 'Contact sending notification',
                  border: OutlineInputBorder(),
                ),
                items: (widget.persons
                        .where((person) => person.id != widget.currentPersonId)
                        .toList()
                      ..sort(
                        (a, b) => a.name.toLowerCase().compareTo(
                              b.name.toLowerCase(),
                            ),
                      ))
                    .map(
                      (person) => DropdownMenuItem<String>(
                        value: person.id,
                        child: Text(person.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSenderId = value;
                  });

                  _updateSelectedChat();
                },
              ),

              const SizedBox(height: 16),

              // ============================================================
              // AUTOMATICALLY FOUND CHAT
              // ============================================================

              if (_selectedSenderId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_outlined,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedProject != null
                              ? 'Chat found: ${_selectedProject!.title}'
                              : 'A conversation will be created automatically.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // ============================================================
              // CUSTOM MESSAGE
              // ============================================================

              TextField(
                controller: _messageController,
                maxLines: 4,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Notification message',
                  hintText: 'Type the message that should appear...',
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
                  (notification_entity.Notification notification) {
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
