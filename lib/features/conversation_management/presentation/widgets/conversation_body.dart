import 'package:flutter/material.dart';

import '../../../message_management/domain/entities/message.dart';
import '../../../person_management/domain/entities/person.dart';

import '../../../message_management/presentation/widgets/message_bubble.dart';
import '../../../message_management/presentation/widgets/typing_indicator.dart';
import 'conversation_header.dart';

import '../../../project_management/domain/entities/project.dart';

class ConversationBody extends StatelessWidget {
  final List<Message> messages;
  final List<Person> persons;
  final String ownerId;

  final bool otherPersonTyping;

  final ScrollController scrollController;

  final Widget? bottomWidget;
  final Project? project;

  const ConversationBody({
    super.key,
    required this.messages,
    required this.persons,
    required this.ownerId,
    required this.scrollController,
    required this.otherPersonTyping,
    this.bottomWidget,
    this.project,
  });

  @override
  Widget build(BuildContext context) {
    final isGroup = project != null && project!.participantIds.length > 2;

    final otherPerson = isGroup
        ? null
        : persons.firstWhere(
            (p) => p.id != ownerId,
          );

    final visibleMessages = messages.reversed.toList();

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
              ConversationHeader(
                person: otherPerson,
                project: project,
                isTyping: otherPersonTyping,
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  reverse: true,
                  itemCount: visibleMessages.length,
                  itemBuilder: (_, index) {
                    final message = visibleMessages[index];

                    final sender = persons.firstWhere(
                      (p) => p.id == message.senderId,
                    );
                    final messageAbove = index < messages.length - 1
                        ? messages[index + 1]
                        : null;

                    final messageBelow = index > 0 ? messages[index - 1] : null;

                    final isFirstInGroup = messageAbove == null ||
                        messageAbove.senderId != message.senderId;

                    final isLastInGroup = messageBelow == null ||
                        messageBelow.senderId != message.senderId;
                    return MessageBubble(
                      message: message,
                      sender: sender,
                      isMine: sender.id == ownerId,
                      isGroup: persons.length > 2,
                      isFirstInGroup: isFirstInGroup,
                      isLastInGroup: isLastInGroup,
                    );
                  },
                ),
              ),
              TypingIndicator(
                visible: otherPersonTyping,
              ),
              if (bottomWidget != null) bottomWidget!,
            ],
          ),
        ),
      ],
    );
  }
}
