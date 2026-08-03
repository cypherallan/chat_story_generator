import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';

import '../widgets/conversation_header.dart';
import '../../../message_management/presentation/widgets/message_bubble.dart';
import '../../../message_management/presentation/widgets/message_composer.dart';
import '../../../message_management/presentation/widgets/typing_indicator.dart';

import 'conversation_playback_page.dart';
import '../cubit/conversation_replay_cubit.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';

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
  bool otherPersonTyping = false;

  @override
  void initState() {
    super.initState();
    selectedSenderId = widget.project.ownerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonCubit>().setPersonOnline(selectedSenderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        onPopInvokedWithResult: (didPop, result) async {
          if (!didPop) return;

          context.read<PersonCubit>().setPersonOffline(selectedSenderId);

          await context.read<ProjectCubit>().loadProjects();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            titleSpacing: 0,
            title: BlocBuilder<PersonCubit, PersonState>(
              builder: (context, state) {
                final isGroup = widget.project.participantIds.length > 2;

                if (isGroup) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.project.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.project.participantIds.length} participants',
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                }

                if (state is PersonLoaded) {
                  final otherPersonId =
                      widget.project.participantIds.firstWhere(
                    (id) => id != widget.project.ownerId,
                    orElse: () => widget.project.ownerId,
                  );

                  final otherPerson = state.persons.firstWhere(
                    (person) => person.id == otherPersonId,
                  );

                  return ConversationHeader(
                    person: otherPerson,
                    isTyping: otherPersonTyping,
                  );
                }

                return const Text('Conversation');
              },
            ),
            actions: [
              BlocBuilder<MessageCubit, MessageState>(
                builder: (context, state) {
                  return IconButton(
                    tooltip: "Preview Conversation",
                    icon: const Icon(Icons.play_circle_fill),
                    onPressed: state is! MessageLoaded
                        ? null
                        : () {
                            final personCubit = context.read<PersonCubit>();
                            final messageCubit = context.read<MessageCubit>();

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MultiBlocProvider(
                                  providers: [
                                    BlocProvider.value(
                                      value: personCubit,
                                    ),
                                    BlocProvider.value(
                                      value: messageCubit,
                                    ),
                                    BlocProvider(
                                      create: (_) => ConversationReplayCubit(),
                                    ),
                                  ],
                                  child: ConversationPlaybackPage(
                                    project: widget.project,
                                    messages: state.messages,
                                  ),
                                ),
                              ),
                            );
                          },
                  );
                },
              ),
            ],
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

                            return BlocConsumer<MessageCubit, MessageState>(
                              listener: (context, messageState) {
                                if (messageState is MessageLoaded) {
                                  _scrollToBottom();
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

                                  final messages =
                                      messageState.messages.reversed.toList();

                                  return ListView.builder(
                                    controller: _scrollController,
                                    reverse: true,
                                    itemCount: messages.length,
                                    itemBuilder: (context, index) {
                                      final message = messages[index];

                                      final sender =
                                          personState.persons.firstWhere(
                                        (person) =>
                                            person.id == message.senderId,
                                      );

                                      final isMine =
                                          sender.id == widget.project.ownerId;

                                      return MessageBubble(
                                        message: message,
                                        sender: sender,
                                        isMine: isMine,
                                        isGroup: widget
                                                .project.participantIds.length >
                                            2,
                                      );
                                    },
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

                        return TypingIndicator(
                          visible: otherPersonTyping,
                        );
                      },
                    ),
                    BlocBuilder<PersonCubit, PersonState>(
                      builder: (context, state) {
                        if (state is! PersonLoaded) {
                          return const SizedBox.shrink();
                        }

                        final participants = state.persons
                            .where(
                              (person) => widget.project.participantIds
                                  .contains(person.id),
                            )
                            .toList();

                        return MessageComposer(
                          participants: participants,
                          selectedSenderId: selectedSenderId,
                          onSenderChanged: (senderId) {
                            final previous = selectedSenderId;

                            setState(() {
                              selectedSenderId = senderId;
                            });

                            context
                                .read<PersonCubit>()
                                .setPersonOffline(previous);
                            context
                                .read<PersonCubit>()
                                .setPersonOnline(senderId);
                          },
                          onTypingStarted: () {
                            if (selectedSenderId != widget.project.ownerId) {
                              setState(() {
                                otherPersonTyping = true;
                              });

                              context.read<MessageCubit>().markMessagesAsRead(
                                    projectId: widget.project.id,
                                    currentUserId: widget.project.ownerId,
                                  );
                            }
                          },
                          onTypingStopped: () {
                            if (mounted) {
                              setState(() {
                                otherPersonTyping = false;
                              });
                            }
                          },
                          onSend: (senderId, text) {
                            context.read<MessageCubit>().createMessage(
                                  projectId: widget.project.id,
                                  senderId: senderId,
                                  text: text,
                                );

                            if (participants.length == 2) {
                              final previousSender = selectedSenderId;

                              final nextSender = senderId == participants[0].id
                                  ? participants[1].id
                                  : participants[0].id;

                              setState(() {
                                selectedSenderId = nextSender;
                              });

                              context
                                  .read<PersonCubit>()
                                  .setPersonOffline(previousSender);
                              context
                                  .read<PersonCubit>()
                                  .setPersonOnline(nextSender);
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
        ));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
