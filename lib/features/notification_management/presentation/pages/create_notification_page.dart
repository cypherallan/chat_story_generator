import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../group_management/domain/entities/project.dart';
import '../cubit/notification_cubit.dart';
import '../cubit/notification_state.dart';
import '../../domain/entities/notification.dart' as notification_entity;
import '../../../group_management/presentation/cubit/group_cubit.dart';
import 'package:uuid/uuid.dart';
import '../../../person_management/presentation/widgets/person_avatar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

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
      if (mounted) context.read<NotificationCubit>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  List<Project> get _availableGroups {
    final list = widget.projects
        .where((p) =>
            p.participantIds.length > 2 && // <-- only real groups
            p.participantIds.contains(widget.currentPersonId))
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return list;
  }

  List<Person> get _availableContacts {
    final list = widget.persons
        .where((p) => p.id != widget.currentPersonId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  List<Person> _contactsForProject(Project project) {
    return widget.persons
        .where((p) =>
            project.participantIds.contains(p.id) &&
            p.id != widget.currentPersonId)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Person? get _selectedSender {
    if (_selectedSenderId == null) return null;
    try {
      return widget.persons.firstWhere((p) => p.id == _selectedSenderId);
    } catch (_) {
      return null;
    }
  }

  Project? _findDirectChat(
      {required String senderId, required String ownerId}) {
    for (final project in widget.projects) {
      if (project.ownerId != ownerId) continue;
      if (project.participantIds.length != 2) continue;
      final participants = project.participantIds.toSet();
      if (participants.contains(senderId) && participants.contains(ownerId))
        return project;
    }
    return null;
  }

  // ===== DIVIDED PICKER =====
  Future<void> _showTargetPicker() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 16),
                const Text('Select target',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                // GROUPS SECTION
                const Text('GROUPS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                if (_availableGroups.isEmpty)
                  const ListTile(
                      title: Text('No groups',
                          style: TextStyle(color: Colors.grey)))
                else
                  ..._availableGroups.map((project) {
                    final isSelected = _selectedProject?.id == project.id &&
                        _selectedSenderId == null;
                    return ListTile(
                      leading: _buildGroupAvatar(project),
                      title: Text(project.title),
                      subtitle:
                          Text('${project.participantIds.length} members'),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() {
                          _selectedProject = project;
                          _selectedSenderId = null; // will pick sender next
                        });
                        // after picking group, ask for sender from that group
                        Future.delayed(const Duration(milliseconds: 200),
                            () => _showSenderForGroupPicker(project));
                      },
                    );
                  }),

                const Divider(height: 32),

                // CONTACTS SECTION
                const Text('CONTACTS',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1)),
                const SizedBox(height: 8),
                ..._availableContacts.map((person) {
                  final isSelected = _selectedSenderId == person.id;
                  return ListTile(
                    leading: PersonAvatar(person: person, radius: 20),
                    title: Text(person.name),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedSenderId = person.id;
                        _selectedProject = _findDirectChat(
                            senderId: person.id,
                            ownerId: widget.currentPersonId);
                      });
                    },
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSenderForGroupPicker(Project group) async {
    final contacts = _contactsForProject(group);
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 12),
            Text('Who sends in "${group.title}"?',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...contacts.map((person) => ListTile(
                  leading: PersonAvatar(person: person, radius: 20),
                  title: Text(person.name),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedSenderId = person.id);
                  },
                )),
            if (contacts.isEmpty)
              const ListTile(
                  title: Text('No contacts in this group',
                      style: TextStyle(color: Colors.grey))),
          ],
        );
      },
    );
  }

  Widget _buildGroupAvatar(Project project) {
    ImageProvider? img;
    if (project.groupImagePath != null && project.groupImagePath!.isNotEmpty) {
      if (project.groupImagePath!.startsWith('http')) {
        img = CachedNetworkImageProvider(project.groupImagePath!);
      } else {
        img = FileImage(File(project.groupImagePath!));
      }
    }
    return CircleAvatar(
      radius: 20,
      backgroundImage: img,
      child: img == null
          ? Text(
              project.title.isNotEmpty ? project.title[0].toUpperCase() : 'G')
          : null,
    );
  }

  Future<void> _save() async {
    final sender = _selectedSender;
    final messageText = _messageController.text.trim();

    if (_selectedProject == null && sender == null) {
      _showError('Select a group or a contact.');
      return;
    }
    if (sender == null) {
      _showError('Select contact who will send notification.');
      return;
    }
    if (messageText.isEmpty) {
      _showError('Enter notification message.');
      return;
    }

    final groupCubit = context.read<GroupCubit>();
    Project project;

    if (_selectedProject != null &&
        _selectedProject!.participantIds.length > 2) {
      // Group notification
      project = _selectedProject!;
    } else {
      // Private chat
      project = await groupCubit.openOrCreatePrivateChat(
        ownerId: widget.currentPersonId,
        contactId: sender.id,
        contactName: sender.name,
      );
    }

    if (!mounted) return;
    final messageId = const Uuid().v4();

    final success = await context.read<NotificationCubit>().createNotification(
          projectId: project.id,
          messageId: messageId,
          senderId: sender.id,
          senderName: sender.name,
          senderAvatarPath: sender.avatarPath,
          messageText: messageText,
        );

    if (!mounted) return;
    if (!success) {
      final error = context.read<NotificationCubit>().state.error;
      _showError(error ?? 'Failed to save notification.');
      return;
    }

    _messageController.clear();
    await groupCubit.loadProjects();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Notification saved for later triggering.')));
    setState(() {
      _selectedProject = null;
      _selectedSenderId = null;
    });
  }

  Future<void> _delete(notification_entity.Notification notification) async {
    await context.read<NotificationCubit>().removeNotification(notification.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Notification deleted.')));
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _projectName(String projectId) {
    for (final project in widget.projects) {
      if (project.id == projectId) return project.title;
    }
    return 'Unknown chat';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Replay Notifications')),
      body: BlocBuilder<NotificationCubit, NotificationState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                  'Create notifications here, then trigger them later from the normal conversation.',
                  style: TextStyle(fontSize: 15)),
              const SizedBox(height: 24),
              const Text('Create Notification',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // DIVIDED SELECTOR
              InkWell(
                onTap: _showTargetPicker,
                borderRadius: BorderRadius.circular(8),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Select Group / Contact',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: _selectedProject != null &&
                          _selectedProject!.participantIds.length > 2
                      ? Row(children: [
                          _buildGroupAvatar(_selectedProject!),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_selectedProject!.title)),
                        ])
                      : _selectedSender != null
                          ? Row(children: [
                              PersonAvatar(
                                  person: _selectedSender!, radius: 16),
                              const SizedBox(width: 10),
                              Text(_selectedSender!.name),
                            ])
                          : const Text('Tap to select group or contact',
                              style: TextStyle(color: Colors.grey)),
                ),
              ),

              if (_selectedProject != null &&
                  _selectedProject!.participantIds.length > 2) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _showSenderForGroupPicker(_selectedProject!),
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Contact sending in group',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.arrow_drop_down),
                    ),
                    child: _selectedSender != null
                        ? Row(children: [
                            PersonAvatar(person: _selectedSender!, radius: 16),
                            const SizedBox(width: 10),
                            Text(_selectedSender!.name),
                          ])
                        : const Text('Select who sends',
                            style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],

              if (_selectedSenderId != null &&
                  (_selectedProject == null ||
                      _selectedProject!.participantIds.length == 2))
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_outlined, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                            _selectedProject != null
                                ? 'Chat found: ${_selectedProject!.title}'
                                : 'A conversation will be created automatically.',
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              TextField(
                controller: _messageController,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Notification message',
                    hintText: 'Type the message that should appear...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                  height: 52,
                  child: ElevatedButton(
                      onPressed: state.loading ? null : _save,
                      child: const Text('SAVE NOTIFICATION'))),
              const SizedBox(height: 32),
              const Text('Saved Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (state.loading)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator()))
              else if (state.notifications.isEmpty)
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('No replay notifications created yet.',
                        style: TextStyle(color: Colors.grey)))
              else
                ...state.notifications
                    .map((notification_entity.Notification notification) {
                  final project = widget.projects
                          .where((p) => p.id == notification.projectId)
                          .isNotEmpty
                      ? widget.projects
                          .firstWhere((p) => p.id == notification.projectId)
                      : null;
                  final isGroup =
                      project != null && project.participantIds.length > 2;
                  final groupName = _projectName(notification.projectId);
                  final showGroup = isGroup && groupName != 'Unknown chat';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            showGroup ? groupName : notification.senderName,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (showGroup) ...[
                            const SizedBox(height: 4),
                            Text(
                              notification.senderName,
                              style: const TextStyle(
                                  color: Color(0xFF25D366),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text(notification.messageText,
                              style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 12),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                    tooltip: 'Delete',
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _delete(notification)),
                              ]),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}
