import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/domain/entities/project.dart';
import '../cubit/conversation_replay_cubit.dart';
import 'conversation_header.dart';

class PlaybackHeader extends StatelessWidget {
  final Project project;

  const PlaybackHeader({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, personState) {
        if (personState is! PersonLoaded) {
          return const Text("Playback");
        }

        return BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
          builder: (context, replayState) {
            final otherPersonId = project.participantIds.firstWhere(
              (id) => id != project.ownerId,
            );

            final original = personState.persons.firstWhere(
              (p) => p.id == otherPersonId,
            );

            final playbackPerson = original.copyWith(
              isOnline: replayState.onlinePersonId == otherPersonId,
            );

            return ConversationHeader(
              person: playbackPerson,
              isTyping: replayState.typing &&
                  replayState.typingPersonId == otherPersonId,
            );
          },
        );
      },
    );
  }
}
