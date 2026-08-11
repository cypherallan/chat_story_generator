import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/domain/entities/project.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';

import '../../../shared/widgets/profile_avatar.dart';

class PlaybackHeader extends StatelessWidget {
  final Project project;
  final VoidCallback onBack;
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onClearSelection;
  final bool deleteIconPressed;

  const PlaybackHeader({
    super.key,
    required this.project,
    required this.onBack,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onClearSelection,
    this.deleteIconPressed = false,
  });

  Person? _findPerson(List<Person> persons, String id) {
    for (final person in persons) {
      if (person.id == id) {
        return person;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, personState) {
        if (isSelectionMode) {
          return _buildSelectionHeader();
        }

        if (personState is! PersonLoaded) {
          return _buildHeader(
            context,
            null,
            project.title,
            'online',
            false,
            isGroup: project.participantIds.length > 2,
          );
        }

        return BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
          builder: (context, replayState) {
            final isGroup = project.participantIds.length > 2;

            final otherPersonIds = project.participantIds
                .where((id) => id != project.ownerId)
                .toList();

            // ================================================================
            // GROUP CHAT
            // ================================================================

            if (isGroup) {
              final groupMembers = personState.persons
                  .where(
                    (person) => project.participantIds.contains(person.id),
                  )
                  .toList();

              final participantNames =
                  groupMembers.map((person) => person.name).toList();

              String subtitle;

              // During replay, show the person currently typing.
              if (replayState.typing && replayState.typingPersonId != null) {
                final typingPerson = _findPerson(
                  personState.persons,
                  replayState.typingPersonId!,
                );

                subtitle = typingPerson != null
                    ? '${typingPerson.name} is typing...'
                    : 'typing...';
              } else {
                // WhatsApp-style group participant preview.
                if (participantNames.isEmpty) {
                  subtitle = 'Group';
                } else if (participantNames.length <= 3) {
                  subtitle = participantNames.join(', ');
                } else {
                  subtitle =
                      '${participantNames.take(3).join(', ')}, +${participantNames.length - 3}';
                }
              }

              return _buildHeader(
                context,
                null,
                project.title,
                subtitle,
                replayState.typing,
                isGroup: true,
              );
            }

            // ================================================================
            // ONE-TO-ONE CHAT
            // ================================================================

            Person? person;

            if (otherPersonIds.isNotEmpty) {
              person = _findPerson(
                personState.persons,
                otherPersonIds.first,
              );
            }

            final isTyping = replayState.typing &&
                replayState.typingPersonId != null &&
                otherPersonIds.contains(
                  replayState.typingPersonId,
                );

            final subtitle = isTyping
                ? 'typing...'
                : replayState.onlinePersonId != null
                    ? 'online'
                    : 'last seen recently';

            return _buildHeader(
              context,
              person,
              person?.name ?? project.title,
              subtitle,
              isTyping,
              isGroup: false,
            );
          },
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Person? person,
    String title,
    String subtitle,
    bool isTyping, {
    required bool isGroup,
  }) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.only(left: 0, right: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          _buildPersonAvatar(
            person,
            isGroup: isGroup,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isTyping ? Colors.green : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildPersonAvatar(
    Person? person, {
    required bool isGroup,
  }) {
    if (isGroup) {
      return ProfileAvatar(
        imagePath: project.groupImagePath,
        name: project.title,
        radius: 20,
      );
    }

    return ProfileAvatar(
      imagePath: person?.avatarPath,
      name: person?.name ?? 'Playback',
      radius: 20,
    );
  }

  Widget _buildSelectionHeader() {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.only(left: 0, right: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onClearSelection,
          ),
          Expanded(
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.star_border),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.reply),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {},
          ),

          // DELETE – visually pressed during replay
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: deleteIconPressed ? Colors.red : null,
              size: deleteIconPressed ? 28 : 24,
            ),
            onPressed: () {},
          ),

          PopupMenuButton<String>(
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'more',
                child: Text('More'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
