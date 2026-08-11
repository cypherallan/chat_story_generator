import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../project_management/domain/entities/project.dart';
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
            final messages = replayState.visibleMessages;

            if (messages.isEmpty) {
              return const Center(
                child: Text(
                  'No messages yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            }

            // Newest messages at the bottom (same pattern as the normal conversation list)
            final displayMessages = messages.reversed.toList();

            return ListView.builder(
              controller: scrollController,
              reverse: true,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: displayMessages.length,
              itemBuilder: (context, index) {
                final message = displayMessages[index];

                final previousMessage =
                    index > 0 ? displayMessages[index - 1] : null;
                final nextMessage = index < displayMessages.length - 1
                    ? displayMessages[index + 1]
                    : null;

                final isFirstInGroup = previousMessage == null ||
                    previousMessage.senderId != message.senderId;
                final isLastInGroup = nextMessage == null ||
                    nextMessage.senderId != message.senderId;

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
