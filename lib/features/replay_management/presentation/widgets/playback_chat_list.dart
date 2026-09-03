import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../group_management/domain/entities/project.dart';
import '../../../message_management/domain/entities/message.dart';
import '../../../message_management/presentation/widgets/message_bubble.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';

class PlaybackChatList extends StatelessWidget {
  final Project project;
  final ScrollController scrollController;
  final Set<String> selectedMessageIds;
  final void Function(String) onToggleSelection;
  final void Function(Message) onSwipeReply;
  final void Function(String) onReplyTap;

  const PlaybackChatList({
    super.key,
    required this.project,
    required this.scrollController,
    required this.selectedMessageIds,
    required this.onToggleSelection,
    required this.onSwipeReply,
    required this.onReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, personState) {
        if (personState is! PersonLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocConsumer<ConversationReplayCubit, ConversationReplayState>(
          listenWhen: (previous, current) =>
              previous.visibleMessages.length != current.visibleMessages.length,
          listener: (context, state) {
            // Keep the newest message visible while the conversation is playing.
            if (scrollController.hasClients) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (scrollController.hasClients) {
                  scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
              });
            }
          },
          builder: (context, replayState) {
            final chronological =
                List<Message>.from(replayState.visibleMessages)
                  ..sort((a, b) {
                    final c = a.createdAt.compareTo(b.createdAt);
                    if (c != 0) return c;
                    return a.id.compareTo(b.id);
                  });

// Newest messages at the bottom
            final displayMessages = chronological.reversed.toList();

            return ListView.builder(
              controller: scrollController,
              reverse: true,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: displayMessages.length,
              itemBuilder: (context, index) {
                final message = displayMessages[index];

                final chronoIndex =
                    chronological.indexWhere((m) => m.id == message.id);

                final prevChrono =
                    chronoIndex > 0 ? chronological[chronoIndex - 1] : null;

                final nextChrono = chronoIndex < chronological.length - 1
                    ? chronological[chronoIndex + 1]
                    : null;

                final isFirstInGroup = prevChrono == null ||
                    prevChrono.senderId != message.senderId;

                final isLastInGroup = nextChrono == null ||
                    nextChrono.senderId != message.senderId;

                final sender = personState.persons.firstWhere(
                  (person) => person.id == message.senderId,
                  orElse: () => personState.persons.isNotEmpty
                      ? personState.persons.first
                      : Person(
                          id: message.senderId,
                          name: 'Unknown',
                          avatarPath: null,
                        ),
                );

                final isMine = sender.id == project.ownerId;
                final isGroup = project.participantIds.length > 2;

                return MessageBubble(
                  key: ValueKey(message.id),
                  message: message,
                  sender: sender,
                  isMine: isMine,
                  isGroup: isGroup,
                  isFirstInGroup: isFirstInGroup,
                  isLastInGroup: isLastInGroup,
                  isSelected: selectedMessageIds.contains(message.id),
                  isHighlighted: false,
                  forcedDragOffset: replayState.swipingMessageId == message.id
                      ? replayState.swipeOffset
                      : null,
                  forceShowReplyArrow:
                      replayState.swipingMessageId == message.id &&
                          replayState.swipeOffset > 15,
                  onLongPress: () => onToggleSelection(message.id),
                  onTap: () {
                    if (selectedMessageIds.isNotEmpty) {
                      onToggleSelection(message.id);
                    }
                  },
                  onSwipeReply: () => onSwipeReply(message),
                  onReplyTap: message.replyToMessageId == null
                      ? null
                      : () => onReplyTap(message.replyToMessageId!),
                );
              },
            );
          },
        );
      },
    );
  }
}
