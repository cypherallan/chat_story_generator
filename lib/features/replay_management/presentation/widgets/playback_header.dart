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

  const PlaybackHeader({
    super.key,
    required this.project,
    required this.onBack,
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
          // BACK ARROW
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),

          // PROFILE PICTURE
          _buildAvatar(person),

          const SizedBox(width: 10),

          // NAME + STATUS
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

          // VIDEO
          IconButton(
            icon: const Icon(
              Icons.videocam_outlined,
            ),
            onPressed: () {},
          ),

          // CALL
          IconButton(
            icon: const Icon(
              Icons.call_outlined,
            ),
            onPressed: () {},
          ),

          // THREE DOTS
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
