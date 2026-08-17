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
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return BlocConsumer<MessageCubit, MessageState>(
          listener: (context, messageState) {
            if (messageState is MessageLoaded) {
              onMessagesLoaded();
            }
          },
          builder: (context, messageState) {
            if (messageState is MessageLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (messageState is MessageError) {
              return Center(
                child: Text(messageState.message),
              );
            }

            if (messageState is MessageLoaded) {
              if (messageState.messages.isEmpty) {
                return const Center(
                  child: Text(
                    'No messages yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                );
              }

              // Original order: oldest -> newest.
              final chronologicalMessages =
                  List<Message>.from(messageState.messages)
                    ..sort(
                      (a, b) => a.createdAt.compareTo(b.createdAt),
                    );

              // Only incoming unread messages count.
              final unreadMessages = chronologicalMessages
                  .where(
                    (message) =>
                        message.isUnread && message.senderId != project.ownerId,
                  )
                  .toList();

              final unreadCount = unreadMessages.length;

              // The first unread message in chronological order.
              final firstUnreadMessageId =
                  unreadMessages.isNotEmpty ? unreadMessages.first.id : null;

              // The ListView is reversed, so we display newest -> oldest.
              final messages = chronologicalMessages.reversed.toList();

              return ListView.builder(
                controller: scrollController,
                reverse: true,
                itemCount: messages.length + (unreadCount > 0 ? 1 : 0),
                itemBuilder: (context, index) {
                  /*
                   * Because the ListView is reversed, index 0 represents
                   * the newest message.
                   *
                   * We insert the unread divider immediately before the
                   * oldest unread message when viewed normally.
                   */
                  if (unreadCount > 0) {
                    final unreadDividerIndex = messages.indexWhere(
                      (message) => message.id == firstUnreadMessageId,
                    );

                    if (index == unreadDividerIndex + 1) {
                      return _UnreadMessagesDivider(
                        count: unreadCount,
                      );
                    }
                  }

                  final messageIndex = unreadCount > 0 &&
                          messages.indexWhere(
                                (message) => message.id == firstUnreadMessageId,
                              ) <
                              index
                      ? index - 1
                      : index;

                  if (messageIndex < 0 || messageIndex >= messages.length) {
                    return const SizedBox.shrink();
                  }

                  final message = messages[messageIndex];

                  final previousMessage =
                      messageIndex > 0 ? messages[messageIndex - 1] : null;

                  final nextMessage = messageIndex < messages.length - 1
                      ? messages[messageIndex + 1]
                      : null;

                  final isFirstInGroup = previousMessage == null ||
                      previousMessage.senderId != message.senderId;

                  final isLastInGroup = nextMessage == null ||
                      nextMessage.senderId != message.senderId;

                  final sender = personState.persons.firstWhere(
                    (person) => person.id == message.senderId,
                    orElse: () => personState.persons.first,
                  );

                  final isMine = sender.id == project.ownerId;

                  return KeyedSubtree(
                    key: messageKeys.putIfAbsent(
                      message.id,
                      () => GlobalKey(),
                    ),
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
                            : () => onReplyTap(
                                  message.replyToMessageId!,
                                ),
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
            }

            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}

class _UnreadMessagesDivider extends StatelessWidget {
  final int count;

  const _UnreadMessagesDivider({
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      child: Row(
        children: [
          const Expanded(
            child: Divider(
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
            ),
            child: Text(
              '$count unread ${count == 1 ? 'message' : 'messages'}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Expanded(
            child: Divider(
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}
