import 'package:flutter/material.dart';

import '../../../message_management/domain/entities/message.dart';
import '../../../project_management/domain/entities/project.dart';

import '../../../person_management/presentation/cubit/person_cubit.dart';

import '../widgets/conversation_header.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../message_management/presentation/widgets/message_bubble.dart';
import '../../../conversations/presentation/cubit/conversation_replay_cubit.dart';

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
  final ScrollController _scrollController = ScrollController();
 
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



  @override
  void initState() {
    super.initState();

    final replayCubit = context.read<ConversationReplayCubit>();

    replayCubit.load(widget.messages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
        builder: (context, replayState) {
          return FloatingActionButton(
            child: Icon(
              replayState.playing ? Icons.pause : Icons.play_arrow,
            ),
            onPressed: () {
  final cubit = context.read<ConversationReplayCubit>();

  if (replayState.playing) {
    cubit.pause();
  } else {
    cubit.play();
  }
}
          );
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

              return BlocBuilder<ConversationReplayCubit,
                  ConversationReplayState>(
                builder: (context, replayState) {
                  final messages =
                      replayState.visibleMessages.reversed.toList();

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
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
              );
            },
          ),
        ],
      ),
    );
  }
}
