import 'package:flutter/material.dart';
import 'dart:io';
import '../../../person_management/domain/entities/person.dart';
import '../../../project_management/domain/entities/project.dart';

class ConversationHeader extends StatelessWidget {
  final Person? person;
  final Project? project;
  final bool isTyping;

  const ConversationHeader({
    super.key,
    this.person,
    this.project,
    required this.isTyping,
  });

  String _formatLastSeen(DateTime dateTime) {
    final now = DateTime.now();

    if (now.difference(dateTime).inMinutes < 1) {
      return 'just now';
    }

    if (now.day == dateTime.day &&
        now.month == dateTime.month &&
        now.year == dateTime.year) {
      return 'today at '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    }

    final yesterday = now.subtract(const Duration(days: 1));

    if (yesterday.day == dateTime.day &&
        yesterday.month == dateTime.month &&
        yesterday.year == dateTime.year) {
      return 'yesterday at '
          '${dateTime.hour.toString().padLeft(2, '0')}:'
          '${dateTime.minute.toString().padLeft(2, '0')}';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? image;

    final isGroup = project != null;

    final displayName = isGroup ? project!.title : person?.name ?? 'Unknown';

    final avatarPath = isGroup ? project!.groupImagePath : person?.avatarPath;

    if (avatarPath != null) {
      if (avatarPath.startsWith('http')) {
        image = NetworkImage(avatarPath);
      } else {
        image = FileImage(File(avatarPath));
      }
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundImage: image,
          child: image == null
              ? Text(
                  displayName[0].toUpperCase(),
                )
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!isGroup && person!.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.verified,
                        color: Colors.blue,
                        size: 16,
                      ),
                    ),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  isGroup
                      ? '${project!.participantIds.length} participants'
                      : isTyping
                          ? 'typing...'
                          : person!.isOnline
                              ? 'online'
                              : person!.lastSeen == null
                                  ? 'last seen recently'
                                  : 'last seen ${_formatLastSeen(person!.lastSeen!)}',
                  key: ValueKey(
                    isGroup
                        ? 'group'
                        : isTyping
                            ? 'typing'
                            : person!.isOnline
                                ? 'online'
                                : person!.lastSeen,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isTyping ? const Color(0xff25D366) : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.videocam),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.call),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }
}
