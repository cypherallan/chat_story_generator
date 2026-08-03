import 'package:flutter/material.dart';

import '../../../message_management/domain/entities/message.dart';
import '../../../person_management/domain/entities/person.dart';

import '../../../message_management/presentation/widgets/message_bubble.dart';
import '../../../message_management/presentation/widgets/typing_indicator.dart';
import 'conversation_header.dart';

class ConversationBody extends StatelessWidget {
  final List<Message> messages;
  final List<Person> persons;
  final String ownerId;

  final bool otherPersonTyping;

  final ScrollController scrollController;

  final Widget? bottomWidget;

  const ConversationBody({
    super.key,
    required this.messages,
    required this.persons,
    required this.ownerId,
    required this.scrollController,
    required this.otherPersonTyping,
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    final otherPerson = persons.firstWhere(
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

                    return MessageBubble(
                      message: message,
                      sender: sender,
                      isMine: sender.id == ownerId,
                      isGroup: persons.length > 2,
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
