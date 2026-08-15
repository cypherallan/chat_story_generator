import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../project_management/domain/entities/project.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../../domain/entities/notification.dart' as notification_entity;

class CreateNotificationPage extends StatefulWidget {
  final List<Project> projects;
  final List<Person> persons;

  const CreateNotificationPage({
    super.key,
    required this.projects,
    required this.persons,
  });

  @override
  State<CreateNotificationPage> createState() => _CreateNotificationPageState();
}

class _CreateNotificationPageState extends State<CreateNotificationPage> {
  String? _selectedSenderId;
  String? _selectedOwnerId;

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

  Person? get _selectedOwner {
    if (_selectedOwnerId == null) {
      return null;
    }

    for (final person in widget.persons) {
      if (person.id == _selectedOwnerId) {
        return person;
      }
    }

    return null;
  }

  /// Finds the direct chat between:
  ///
  /// sender = the person sending the notification
  /// owner  = "you"
  ///
  /// This follows the same structure used when creating
  /// a normal two-person chat.
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
    if (_selectedSenderId == null || _selectedOwnerId == null) {
      setState(() {
        _selectedProject = null;
      });
      return;
    }

    if (_selectedSenderId == _selectedOwnerId) {
      setState(() {
        _selectedProject = null;
      });
      return;
    }

    final project = _findDirectChat(
      senderId: _selectedSenderId!,
      ownerId: _selectedOwnerId!,
    );

    setState(() {
      _selectedProject = project;
    });
  }

  Future<void> _save() async {
    final sender = _selectedSender;
    final owner = _selectedOwner;
    final project = _selectedProject;

    final messageText = _messageController.text.trim();

    if (sender == null) {
      _showError(
        'Please select the contact who will send the notification.',
      );
      return;
    }

    if (owner == null) {
      _showError(
        'Please select who you are.',
      );
      return;
    }

    if (sender.id == owner.id) {
      _showError(
        'The sender and "you" must be different people.',
      );
      return;
    }

    if (project == null) {
      _showError(
        'No direct chat exists between these two contacts.',
      );
      return;
    }

    if (messageText.isEmpty) {
      _showError(
        'Please enter the notification message.',
      );
      return;
    }

    final success = await context.read<NotificationCubit>().createNotification(
          projectId: project.id,
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
                items: widget.persons
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
              // WHO ARE YOU?
              // ============================================================

              DropdownButtonFormField<String>(
                value: _selectedOwnerId,
                decoration: const InputDecoration(
                  labelText: 'You are',
                  border: OutlineInputBorder(),
                ),
                items: widget.persons
                    .map(
                      (person) => DropdownMenuItem<String>(
                        value: person.id,
                        child: Text(person.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedOwnerId = value;
                  });

                  _updateSelectedChat();
                },
              ),

              const SizedBox(height: 16),

              // ============================================================
              // AUTOMATICALLY FOUND CHAT
              // ============================================================

              if (_selectedSenderId != null && _selectedOwnerId != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: _selectedProject == null
                      ? const Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'No direct chat exists between these '
                                'two contacts.',
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const Icon(
                              Icons.chat_outlined,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Chat found: ${_selectedProject!.title}',
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
