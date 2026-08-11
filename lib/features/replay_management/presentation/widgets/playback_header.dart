import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/domain/entities/project.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';

class PlaybackHeader extends StatelessWidget {
  final Project project;
  final VoidCallback onBack;

  // ---------------------------------------------------------------------------
  // SELECTION MODE
  // ---------------------------------------------------------------------------
  final bool isSelectionMode;
  final int selectedCount;
  final VoidCallback onClearSelection;

  const PlaybackHeader({
    super.key,
    required this.project,
    required this.onBack,
    required this.isSelectionMode,
    required this.selectedCount,
    required this.onClearSelection,
  });

  Person? _findPerson(
    List<Person> persons,
    String id,
  ) {
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
            'Playback',
            'online',
            false,
          );
        }

        return BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
          builder: (context, replayState) {
            final otherPersonIds = project.participantIds
                .where(
                  (id) => id != project.ownerId,
                )
                .toList();

            Person? person;

            if (otherPersonIds.isNotEmpty) {
              person = _findPerson(
                personState.persons,
                otherPersonIds.first,
              );
            }

            final title = project.participantIds.length > 2
                ? project.title
                : person?.name ?? project.title;

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
              title,
              subtitle,
              isTyping,
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // NORMAL HEADER
  // ===========================================================================

  Widget _buildHeader(
    BuildContext context,
    Person? person,
    String title,
    String subtitle,
    bool isTyping,
  ) {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.only(
        left: 0,
        right: 4,
      ),
      child: Row(
        children: [
          // -------------------------------------------------------------------
          // BACK
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),

          // -------------------------------------------------------------------
          // PROFILE PICTURE
          // -------------------------------------------------------------------
          _buildAvatar(person),

          const SizedBox(width: 10),

          // -------------------------------------------------------------------
          // NAME + STATUS
          // -------------------------------------------------------------------
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

          // -------------------------------------------------------------------
          // VIDEO
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.videocam_outlined,
            ),
            onPressed: () {},
          ),

          // -------------------------------------------------------------------
          // CALL
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.call_outlined,
            ),
            onPressed: () {},
          ),

          // -------------------------------------------------------------------
          // THREE DOTS
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.more_vert,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SELECTION HEADER
  // ===========================================================================

  Widget _buildSelectionHeader() {
    return Container(
      height: kToolbarHeight,
      padding: const EdgeInsets.only(
        left: 0,
        right: 4,
      ),
      child: Row(
        children: [
          // -------------------------------------------------------------------
          // EXIT SELECTION MODE
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
            ),
            onPressed: onClearSelection,
          ),

          // -------------------------------------------------------------------
          // SELECTED COUNT
          // -------------------------------------------------------------------
          Expanded(
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // STAR
          // Placeholder for now.
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.star_border,
            ),
            onPressed: () {},
          ),

          // -------------------------------------------------------------------
          // REACTION
          // Placeholder for now.
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.emoji_emotions_outlined,
            ),
            onPressed: () {},
          ),

          // -------------------------------------------------------------------
          // REPLY
          // Placeholder for now.
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.reply,
            ),
            onPressed: () {},
          ),

          // -------------------------------------------------------------------
          // COPY
          // Placeholder for now.
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.copy,
            ),
            onPressed: () {},
          ),

          // -------------------------------------------------------------------
          // DELETE
          // Placeholder for now.
          // -------------------------------------------------------------------
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
            ),
            onPressed: () {},
          ),

          // -------------------------------------------------------------------
          // MORE
          // -------------------------------------------------------------------
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

  // ===========================================================================
  // AVATAR
  // ===========================================================================

  Widget _buildAvatar(Person? person) {
    if (person?.avatarPath != null && person!.avatarPath!.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundImage: NetworkImage(
          person.avatarPath!,
        ),
      );
    }

    return const CircleAvatar(
      radius: 20,
      child: Icon(
        Icons.person,
        size: 22,
      ),
    );
  }
}
