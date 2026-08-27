import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../project_management/presentation/models/chat_list_item.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../presentation/cubit/conversation_replay_cubit.dart';

class ReplayHomeChatList extends StatelessWidget {
  final List<Project> projects;
  final List<Person> persons;
  final void Function(Project project) onChatTap;
  final String ownerId;
  final String? highlightedProjectId;
  final bool isChatTapPressed;

  const ReplayHomeChatList({
    super.key,
    required this.projects,
    required this.persons,
    required this.onChatTap,
    required this.ownerId,
    this.highlightedProjectId,
    this.isChatTapPressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final replayCubit = context.read<ConversationReplayCubit>();
    final replayMap = replayCubit.replayVisiblePerProject;

    final filteredProjects =
        projects.where((p) => p.ownerId == ownerId).toList();
    final sortedProjects = [...filteredProjects];

    // sort by REPLAY time, not final DB time
    sortedProjects.sort((a, b) {
      final aReplayLast = replayMap[a.id]?.isNotEmpty == true
          ? replayMap[a.id]!.last.createdAt
          : null;
      final bReplayLast = replayMap[b.id]?.isNotEmpty == true
          ? replayMap[b.id]!.last.createdAt
          : null;
      final aTime = aReplayLast ?? a.lastMessageTime ?? a.createdAt;
      final bTime = bReplayLast ?? b.lastMessageTime ?? b.createdAt;
      return bTime.compareTo(aTime);
    });

    if (sortedProjects.isEmpty) {
      return const Center(
          child: Text('No Chats yet.', textAlign: TextAlign.center));
    }

    return ListView.builder(
      itemCount: sortedProjects.length,
      itemBuilder: (context, index) {
        final project = sortedProjects[index];
        final isGroup = project.participantIds.length > 2;

        Person? otherPerson;
        if (!isGroup) {
          final otherPersonId = project.participantIds.firstWhere(
              (id) => id != project.ownerId,
              orElse: () => project.ownerId);
          for (final person in persons) {
            if (person.id == otherPersonId) {
              otherPerson = person;
              break;
            }
          }
          if (otherPerson == null) return const SizedBox.shrink();
        }

        // --- REPLAY-TIME LAST MESSAGE ---
        final replayMessages = replayMap[project.id];
        final replayLastMsg =
            (replayMessages != null && replayMessages.isNotEmpty)
                ? replayMessages.last
                : null;

        String lastMessagePreview;
        String? lastImagePath;
        DateTime? lastTime;
        String? lastSenderId;

        if (replayLastMsg != null) {
          lastMessagePreview = replayLastMsg.text;
          // if your Message has imagePath field, use it - adjust name if different
          lastImagePath = (replayLastMsg as dynamic).imagePath as String?;
          lastTime = replayLastMsg.createdAt;
          lastSenderId = replayLastMsg.senderId;
          if (lastImagePath != null) {
            lastMessagePreview = lastMessagePreview.isNotEmpty
                ? '🖼 $lastMessagePreview'
                : 'Photo';
          }
        } else {
          // fallback to DB before replay starts
          lastMessagePreview = project.lastMessage;
          lastImagePath = project.lastMessageImagePath;
          lastTime = project.lastMessageTime;
          lastSenderId = project.lastSenderId;
          if (project.lastMessageImagePath != null) {
            lastMessagePreview = project.lastMessage.isNotEmpty
                ? '🖼 ${project.lastMessage}'
                : 'Photo';
          }
        }

        if (isGroup && lastSenderId != null) {
          if (lastSenderId == project.ownerId) {
            lastMessagePreview = 'You: $lastMessagePreview';
          } else {
            Person? sender;
            for (final p in persons) {
              if (p.id == lastSenderId) {
                sender = p;
                break;
              }
            }
            lastMessagePreview = sender != null
                ? '${sender.name}: $lastMessagePreview'
                : 'Unknown: $lastMessagePreview';
          }
        }

        final chat = ChatListItem(
          project: project,
          chatName: isGroup ? project.title : otherPerson!.name,
          avatarPath: isGroup ? null : otherPerson!.avatarPath,
          groupImagePath: project.groupImagePath,
          verified: isGroup ? false : otherPerson!.isVerified,
          lastMessage: lastMessagePreview,
          lastMessageImagePath: lastImagePath,
          lastMessageTime: lastTime,
          lastMessageStatus:
              replayLastMsg != null ? null : project.lastMessageStatus,
          isLastMessageMine: lastSenderId == project.ownerId,
          unreadCount: project.unreadCount,
        );

        final isHighlighted = highlightedProjectId == project.id;
        final tileColor =
            isHighlighted && isChatTapPressed ? Colors.grey.shade300 : null;

        return Container(
          color: tileColor,
          child: ListTile(
            leading: _buildAvatar(chat),
            title: Text(chat.chatName,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(chat.lastMessage,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: chat.lastMessageTime == null
                ? null
                : Text(_formatTime(chat.lastMessageTime!),
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            onTap: () => onChatTap(project),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(ChatListItem chat) {
    final imagePath = chat.groupImagePath ?? chat.avatarPath;
    if (imagePath == null || imagePath.isEmpty) {
      final fallbackLetter =
          chat.chatName.isNotEmpty ? chat.chatName[0].toUpperCase() : '?';
      return CircleAvatar(
          radius: 25,
          child: Text(fallbackLetter,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CircleAvatar(radius: 25, backgroundImage: NetworkImage(imagePath));
    }
    final fallbackLetter =
        chat.chatName.isNotEmpty ? chat.chatName[0].toUpperCase() : '?';
    return CircleAvatar(
        radius: 25,
        child: Text(fallbackLetter,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)));
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : time.hour == 0
            ? 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
