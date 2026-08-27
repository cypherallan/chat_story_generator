import 'package:flutter/material.dart';

import '../../../group_management/domain/entities/project.dart';
import '../../../message_management/domain/entities/message.dart';

import 'conversation_message_list.dart';
import 'conversation_typing_section.dart';
import 'conversation_composer_section.dart';

class ConversationInteractiveBody extends StatelessWidget {
  final Project project;
  final ScrollController scrollController;
  final Map<String, GlobalKey> messageKeys;
  final Set<String> selectedMessageIds;
  final String? highlightedMessageId;
  final bool otherPersonTyping;
  final String selectedSenderId;
  final Message? replyingTo;

  final void Function(String) onToggleSelection;
  final void Function(Message) onSwipeReply;
  final void Function(String) onReplyTap;
  final VoidCallback onMessagesLoaded;
  final VoidCallback onCancelReply;
  final void Function(String) onSenderChanged;
  final VoidCallback onTypingStarted;
  final VoidCallback onTypingStopped;
  final void Function(Map<String, dynamic>) onImageSelected;
  final void Function(String senderId, String text) onSend;

  const ConversationInteractiveBody({
    super.key,
    required this.project,
    required this.scrollController,
    required this.messageKeys,
    required this.selectedMessageIds,
    required this.highlightedMessageId,
    required this.otherPersonTyping,
    required this.selectedSenderId,
    required this.replyingTo,
    required this.onToggleSelection,
    required this.onSwipeReply,
    required this.onReplyTap,
    required this.onMessagesLoaded,
    required this.onCancelReply,
    required this.onSenderChanged,
    required this.onTypingStarted,
    required this.onTypingStopped,
    required this.onImageSelected,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/chat_wallpaper.png',
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ConversationMessageList(
                    project: project,
                    scrollController: scrollController,
                    messageKeys: messageKeys,
                    selectedMessageIds: selectedMessageIds,
                    highlightedMessageId: highlightedMessageId,
                    onToggleSelection: onToggleSelection,
                    onSwipeReply: onSwipeReply,
                    onReplyTap: onReplyTap,
                    onMessagesLoaded: onMessagesLoaded,
                  ),
                ),
              ),
              ConversationTypingSection(otherPersonTyping: otherPersonTyping),
              ConversationComposerSection(
                project: project,
                selectedSenderId: selectedSenderId,
                replyingTo: replyingTo,
                onCancelReply: onCancelReply,
                onSenderChanged: onSenderChanged,
                onTypingStarted: onTypingStarted,
                onTypingStopped: onTypingStopped,
                onImageSelected: onImageSelected,
                onSend: onSend,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
