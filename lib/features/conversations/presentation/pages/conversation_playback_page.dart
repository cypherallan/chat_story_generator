import 'package:flutter/material.dart';

import '../../../message_management/domain/entities/message.dart';
import '../../../project_management/domain/entities/project.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';

import '../widgets/conversation_header.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../message_management/presentation/widgets/message_bubble.dart';

class ConversationPlaybackPage extends StatefulWidget {
  final Project project;
  final List<Message> messages;

  const ConversationPlaybackPage({
    super.key,
    required this.project,
    required this.messages,
  });

  @override
  State<ConversationPlaybackPage> createState() =>
      _ConversationPlaybackPageState();
}

class _ConversationPlaybackPageState extends State<ConversationPlaybackPage> {
  final List<Message> visibleMessages = [];
  final ScrollController _scrollController = ScrollController();

  int currentIndex = 0;

  bool isPlaying = false;
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _playNextMessage() async {
    if (!isPlaying) return;

    if (currentIndex >= widget.messages.length) {
      isPlaying = false;
      return;
    }

    setState(() {
      visibleMessages.add(widget.messages[currentIndex]);
      currentIndex++;
    });

    await Future.delayed(
      const Duration(milliseconds: 350),
    );

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    _playNextMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.play_arrow),
        onPressed: () {
          if (isPlaying) return;

          setState(() {
            isPlaying = true;
          });

          _playNextMessage();
        },
      ),
      appBar: AppBar(
        titleSpacing: 0,
        title: BlocBuilder<PersonCubit, PersonState>(
          builder: (context, state) {
            if (state is! PersonLoaded) {
              return const Text("Playback");
            }

            final otherPersonId = widget.project.participantIds.firstWhere(
              (id) => id != widget.project.ownerId,
            );

            final otherPerson = state.persons.firstWhere(
              (p) => p.id == otherPersonId,
            );

            return ConversationHeader(
              person: otherPerson,
              isTyping: false,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat_wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),
          BlocBuilder<PersonCubit, PersonState>(
            builder: (context, personState) {
              if (personState is! PersonLoaded) {
                return const SizedBox();
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                itemCount: visibleMessages.length,
                itemBuilder: (context, index) {
                  final messages = visibleMessages.reversed.toList();

                  final message = messages[index];

                  final sender = personState.persons.firstWhere(
                    (p) => p.id == message.senderId,
                  );

                  final isMine = sender.id == widget.project.ownerId;

                  return MessageBubble(
                    message: message,
                    sender: sender,
                    isMine: isMine,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
