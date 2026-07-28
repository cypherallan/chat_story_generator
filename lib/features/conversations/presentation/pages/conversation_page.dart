import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';

import '../../../message_management/presentation/widgets/conversation_header.dart';
import '../../../message_management/presentation/widgets/message_bubble.dart';
import '../../../message_management/presentation/widgets/message_composer.dart';

class ConversationPage extends StatefulWidget {
  final Project project;

  const ConversationPage({
    super.key,
    required this.project,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  late String selectedSenderId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    selectedSenderId = widget.project.ownerId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        titleSpacing: 0,
        title: BlocBuilder<PersonCubit, PersonState>(
          builder: (context, state) {
            if (state is PersonLoaded) {
              final otherPersonId = widget.project.participantIds.firstWhere(
                (id) => id != widget.project.ownerId,
                orElse: () => widget.project.ownerId,
              );

              final otherPerson = state.persons.firstWhere(
                (person) => person.id == otherPersonId,
              );

              return ConversationHeader(
                person: otherPerson,
              );
            }

            return const Text('Conversation');
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
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: BlocBuilder<PersonCubit, PersonState>(
                      builder: (context, personState) {
                        if (personState is! PersonLoaded) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        return BlocBuilder<MessageCubit, MessageState>(
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
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_scrollController.hasClients) {
                                  _scrollController.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 250),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });

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

                              final messages =
                                  messageState.messages.reversed.toList();

                              return Container(
                                color: Colors.transparent,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final message = messages[index];

                                    final sender =
                                        personState.persons.firstWhere(
                                      (person) => person.id == message.senderId,
                                    );

                                    final isMine =
                                        sender.id == widget.project.ownerId;

                                    return MessageBubble(
                                      message: message,
                                      sender: sender,
                                      isMine: isMine,
                                    );
                                  },
                                ),
                              );
                            }

                            return const SizedBox.shrink();
                          },
                        );
                      },
                    ),
                  ),
                ),
                BlocBuilder<PersonCubit, PersonState>(
                  builder: (context, state) {
                    if (state is! PersonLoaded) {
                      return const SizedBox.shrink();
                    }

                    final participants = state.persons
                        .where(
                          (person) =>
                              widget.project.participantIds.contains(person.id),
                        )
                        .toList();

                    return MessageComposer(
                      participants: participants,
                      selectedSenderId: selectedSenderId,
                      onSenderChanged: (senderId) {
                        setState(() {
                          selectedSenderId = senderId;
                        });
                      },
                      onSend: (senderId, text) {
                        context.read<MessageCubit>().createMessage(
                              projectId: widget.project.id,
                              senderId: senderId,
                              text: text,
                            );

                        if (participants.length == 2) {
                          setState(() {
                            selectedSenderId = senderId == participants[0].id
                                ? participants[1].id
                                : participants[0].id;
                          });
                        }
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
