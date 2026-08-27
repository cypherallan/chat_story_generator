import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../message_management/domain/entities/message.dart';
import '../../../message_management/presentation/widgets/message_bubble.dart';

class ConversationMessageList extends StatelessWidget {
  final Project project;
  final ScrollController scrollController;
  final Map<String, GlobalKey> messageKeys;
  final Set<String> selectedMessageIds;
  final String? highlightedMessageId;
  final void Function(String) onToggleSelection;
  final void Function(Message) onSwipeReply;
  final void Function(String) onReplyTap;
  final VoidCallback onMessagesLoaded;

  const ConversationMessageList({
    super.key,
    required this.project,
    required this.scrollController,
    required this.messageKeys,
    required this.selectedMessageIds,
    required this.highlightedMessageId,
    required this.onToggleSelection,
    required this.onSwipeReply,
    required this.onReplyTap,
    required this.onMessagesLoaded,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, personState) {
        if (personState is! PersonLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocConsumer<MessageCubit, MessageState>(
          listener: (context, messageState) {
            if (messageState is MessageLoaded) {
              onMessagesLoaded();
            }
          },
          builder: (context, messageState) {
            if (messageState is MessageLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (messageState is MessageError) {
              return Center(child: Text(messageState.message));
            }
            if (messageState is! MessageLoaded) {
              return const SizedBox.shrink();
            }
            if (messageState.messages.isEmpty) {
              return const Center(
                child: Text('No messages yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
              );
            }

            final chronological = List<Message>.from(messageState.messages)
              ..sort((a, b) {
                final c = a.createdAt.compareTo(b.createdAt);
                if (c != 0) return c;
                return a.id.compareTo(b.id);
              });

            final unread = chronological
                .where((m) => m.isUnread && m.senderId != project.ownerId)
                .toList();

            final hasUnread = unread.isNotEmpty;
            final firstUnreadIndex = hasUnread
                ? chronological.indexWhere((m) => m.id == unread.first.id)
                : -1;
            final List<Object> chronologicalWithDivider = [];
            if (hasUnread && firstUnreadIndex != -1) {
              chronologicalWithDivider
                  .addAll(chronological.sublist(0, firstUnreadIndex));
              chronologicalWithDivider
                  .add(_UnreadDivider(count: unread.length));
              chronologicalWithDivider
                  .addAll(chronological.sublist(firstUnreadIndex));
            } else {
              chronologicalWithDivider.addAll(chronological);
            }

            final displayList = chronologicalWithDivider.reversed.toList();

            return ListView.builder(
              controller: scrollController,
              reverse: true,
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final item = displayList[index];

                if (item is _UnreadDivider) {
                  return KeyedSubtree(
                    key: const ValueKey('unread_divider'),
                    child: item,
                  );
                }

                final message = item as Message;
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
                  (p) => p.id == message.senderId,
                  orElse: () => personState.persons.first,
                );
                final isMine = sender.id == project.ownerId;

                return KeyedSubtree(
                  key: messageKeys.putIfAbsent(message.id, () => GlobalKey()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    color: highlightedMessageId == message.id
                        ? const Color(0xffA8E6A1)
                        : Colors.transparent,
                    child: MessageBubble(
                      key: ValueKey(message.id),
                      isSelected: selectedMessageIds.contains(message.id),
                      isHighlighted: highlightedMessageId == message.id,
                      onLongPress: () => onToggleSelection(message.id),
                      onSwipeReply: () => onSwipeReply(message),
                      onTap: () {
                        if (selectedMessageIds.isNotEmpty) {
                          onToggleSelection(message.id);
                        }
                      },
                      onReplyTap: message.replyToMessageId == null
                          ? null
                          : () => onReplyTap(message.replyToMessageId!),
                      message: message,
                      sender: sender,
                      isMine: isMine,
                      isGroup: project.participantIds.length > 2,
                      isFirstInGroup: isFirstInGroup,
                      isLastInGroup: isLastInGroup,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _UnreadDivider extends StatelessWidget {
  final int count;
  const _UnreadDivider({required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          const Expanded(
              child: Divider(thickness: 1, color: Color(0xFFCED6D2))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F3E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count unread ${count == 1 ? 'message' : 'messages'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF54656F),
                ),
              ),
            ),
          ),
          const Expanded(
              child: Divider(thickness: 1, color: Color(0xFFCED6D2))),
        ],
      ),
    );
  }
}
