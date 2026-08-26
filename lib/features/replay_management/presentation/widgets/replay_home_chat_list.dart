import 'package:flutter/material.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../project_management/presentation/models/chat_list_item.dart';
import '../../../person_management/domain/entities/person.dart';

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
    final filteredProjects = projects
        .where(
          (project) => project.ownerId == ownerId,
        )
        .toList();

    final sortedProjects = [...filteredProjects];

    sortedProjects.sort((a, b) {
      final aTime = a.lastMessageTime ?? a.createdAt;
      final bTime = b.lastMessageTime ?? b.createdAt;

      return bTime.compareTo(aTime);
    });

    if (sortedProjects.isEmpty) {
      return const Center(
        child: Text(
          'No Chats yet.',
          textAlign: TextAlign.center,
        ),
      );
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
            orElse: () => project.ownerId,
          );

          for (final person in persons) {
            if (person.id == otherPersonId) {
              otherPerson = person;
              break;
            }
          }

          if (otherPerson == null) {
            return const SizedBox.shrink();
          }
        }

        String lastMessagePreview = project.lastMessage;

        if (project.lastMessageImagePath != null) {
          lastMessagePreview = project.lastMessage.isNotEmpty
              ? '🖼️ ${project.lastMessage}'
              : 'Photo';
        }

        if (isGroup && project.lastSenderId != null) {
          if (project.lastSenderId == project.ownerId) {
            lastMessagePreview = 'You: $lastMessagePreview';
          } else {
            Person? sender;

            for (final person in persons) {
              if (person.id == project.lastSenderId) {
                sender = person;
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
          lastMessageImagePath: project.lastMessageImagePath,
          lastMessageTime: project.lastMessageTime,
          lastMessageStatus: project.lastMessageStatus,
          isLastMessageMine: project.lastSenderId == project.ownerId,
          unreadCount: project.unreadCount,
        );
        final isHighlighted = highlightedProjectId == project.id;
        final tileColor =
            isHighlighted && isChatTapPressed ? Colors.grey.shade300 : null;

        return Container(
          color: tileColor,
          child: ListTile(
            leading: _buildAvatar(chat),
            title: Text(
              chat.chatName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              chat.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: chat.lastMessageTime == null
                ? null
                : Text(
                    _formatTime(
                      chat.lastMessageTime!,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
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
        child: Text(
          fallbackLetter,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(imagePath),
      );
    }

    final fallbackLetter =
        chat.chatName.isNotEmpty ? chat.chatName[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 25,
      child: Text(
        fallbackLetter,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
