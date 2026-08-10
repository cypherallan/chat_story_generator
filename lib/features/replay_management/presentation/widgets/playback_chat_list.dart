import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/domain/entities/project.dart';
import '../../../message_management/presentation/widgets/message_bubble.dart';
import '../cubit/conversation_replay_cubit.dart';

class PlaybackChatList extends StatelessWidget {
  final Project project;
  final ScrollController scrollController;

  const PlaybackChatList({
    super.key,
    required this.project,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, personState) {
        if (personState is! PersonLoaded) {
          return const SizedBox();
        }

        return BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
          builder: (context, replayState) {
            final messages = replayState.visibleMessages.reversed.toList();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (scrollController.hasClients) {
                scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              }
            });

            return ListView.builder(
              controller: scrollController,
              reverse: true,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];

                final sender = personState.persons.firstWhere(
                  (p) => p.id == message.senderId,
                );

                final isMine = sender.id == project.ownerId;
                final previousMessage = index > 0 ? messages[index - 1] : null;

                final nextMessage =
                    index < messages.length - 1 ? messages[index + 1] : null;

                final isFirstInGroup = previousMessage == null ||
                    previousMessage.senderId != message.senderId;

                final isLastInGroup = nextMessage == null ||
                    nextMessage.senderId != message.senderId;
                return MessageBubble(
                  message: message,
                  sender: sender,
                  isMine: isMine,
                  isGroup: project.participantIds.length > 2,
                  isFirstInGroup: isFirstInGroup,
                  isLastInGroup: isLastInGroup,
                );
              },
            );
          },
        );
      },
    );
  }
}
