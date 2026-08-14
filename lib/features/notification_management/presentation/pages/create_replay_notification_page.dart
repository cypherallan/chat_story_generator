import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../project_management/domain/entities/project.dart';
import '../cubit/replay_notification_cubit.dart';

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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
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
        title: const Text('Create Notification'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose the conversation where this notification '
            'actually belongs.',
            style: TextStyle(
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 20),
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
              onPressed: _save,
              child: const Text(
                'SAVE NOTIFICATION',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
