import 'package:flutter/material.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../group_management/domain/entities/project.dart';
import '../../../shared/widgets/profile_avatar.dart';

class ConversationHeader extends StatelessWidget {
  final Person? person;
  final Project? project;
  final List<Person>? persons;
  final bool isTyping;
  final Set<String> typingPersonIds;

  const ConversationHeader({
    super.key,
    this.person,
    this.project,
    this.persons,
    this.isTyping = false,
    this.typingPersonIds = const {},
  });

  List<Person> _sortedOthers() {
    if (project == null || persons == null) return [];
    final others = persons!
        .where((p) =>
            project!.participantIds.contains(p.id) && p.id != project!.ownerId)
        .toList();
    others.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return others;
  }

  String _groupParticipants() {
    if (project == null || persons == null) return '';
    final others = _sortedOthers();
    final names = ['You', ...others.map((p) => p.name)];
    if (names.isEmpty) return '';
    if (names.length <= 4) return names.join(', ');
    return '${names.take(3).join(', ')}, +${names.length - 3}';
  }

  String _groupTypingText() {
    if (persons == null || project == null) return '';
    final others = _sortedOthers();
    final typingOthers =
        others.where((p) => typingPersonIds.contains(p.id)).toList();
    // if owner is typing, don't show in subtitle (you are typing yourself)
    if (typingOthers.isEmpty) return _groupParticipants();
    if (typingOthers.length == 1) {
      return '${typingOthers.first.name} is typing...';
    }
    if (typingOthers.length == 2) {
      return '${typingOthers[0].name}, ${typingOthers[1].name} are typing...';
    }
    return '${typingOthers.length} people are typing...';
  }

  @override
  Widget build(BuildContext context) {
    final isGroup = project != null;
    final displayName = isGroup ? project!.title : person?.name ?? 'Unknown';
    final avatarPath = isGroup ? project!.groupImagePath : person?.avatarPath;

    return Row(
      children: [
        ProfileAvatar(imagePath: avatarPath, name: displayName, radius: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(displayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                  if (!isGroup && person!.isVerified)
                    const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child:
                            Icon(Icons.verified, color: Colors.blue, size: 16)),
                ],
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  isGroup
                      ? _groupTypingText()
                      : isTyping
                          ? 'typing...'
                          : 'online',
                  key: ValueKey(
                    isGroup
                        ? _groupTypingText()
                        : isTyping
                            ? 'typing'
                            : 'online',
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isGroup
                        ? (typingPersonIds.isNotEmpty
                            ? const Color(0xff25D366)
                            : Colors.grey)
                        : const Color(0xff25D366),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
