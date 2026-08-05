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
import '../../../conversations/presentation/pages/group_info_page.dart';
import '../../../message_management/domain/entities/message.dart';
import '../../../message_management/presentation/widgets/reaction_picker.dart';

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
  final Map<String, GlobalKey> _messageKeys = {};
  bool otherPersonTyping = false;
  final Set<String> selectedMessageIds = {};
  Message? replyingTo;
  String? reactionMessageId;
  String? highlightedMessageId;

  bool get isSelectionMode => selectedMessageIds.isNotEmpty;

  void toggleMessageSelection(String messageId) {
    setState(() {
      if (selectedMessageIds.contains(messageId)) {
        selectedMessageIds.remove(messageId);
      } else {
        selectedMessageIds.add(messageId);
      }
    });
  }

  void clearMessageSelection() {
    setState(() {
      selectedMessageIds.clear();
    });
  }

  void _scrollToMessage(String messageId) {
    final key = _messageKeys[messageId];

    if (key?.currentContext == null) return;

    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.5,
    ).then((_) {
      if (!mounted) return;

      setState(() {
        highlightedMessageId = messageId;
      });

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            highlightedMessageId = null;
          });
        }
      });
    });
  }

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
            leading: isSelectionMode
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: clearMessageSelection,
                  )
                : null,
            titleSpacing: 0,
            title: isSelectionMode
                ? Text("${selectedMessageIds.length}")
                : BlocBuilder<PersonCubit, PersonState>(
                    builder: (context, state) {
                      final isGroup = widget.project.participantIds.length > 2;

                      if (isGroup) {
                        if (state is PersonLoaded) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MultiBlocProvider(
                                    providers: [
                                      BlocProvider.value(
                                        value: context.read<PersonCubit>(),
                                      ),
                                      BlocProvider.value(
                                        value: context.read<ProjectCubit>(),
                                      ),
                                    ],
                                    child: GroupInfoPage(
                                      project: widget.project,
                                      persons: state.persons,
                                    ),
                                  ),
                                ),
                              );
                            },
                            child: ConversationHeader(
                              project: widget.project,
                              persons: state.persons,
                              isTyping: otherPersonTyping,
                            ),
                          );
                        }

                        return const Text('Conversation');
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
            actions: isSelectionMode
                ? [
                    IconButton(
                      icon: const Icon(Icons.star_border),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.emoji_emotions_outlined),
                      onPressed: () async {
                        if (selectedMessageIds.length != 1) return;

                        final messageId = selectedMessageIds.first;

                        final messageCubit = context.read<MessageCubit>();

                        await showDialog(
                          context: context,
                          builder: (dialogContext) {
                            return Dialog(
                              backgroundColor: Colors.transparent,
                              child: ReactionPicker(
                                onSelected: (emoji) {
                                  messageCubit.toggleReaction(
                                    messageId: messageId,
                                    userId: widget.project.ownerId,
                                    emoji: emoji,
                                  );

                                  Navigator.pop(dialogContext);
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.reply),
                      onPressed: () {
                        if (selectedMessageIds.length != 1) return;

                        final state = context.read<MessageCubit>().state;

                        if (state is! MessageLoaded) return;

                        final message = state.messages.firstWhere(
                          (m) => m.id == selectedMessageIds.first,
                        );

                        final personState = context.read<PersonCubit>().state;

                        if (personState is PersonLoaded) {
                          final originalSender = personState.persons.firstWhere(
                            (p) => p.id == message.senderId,
                          );

                          setState(() {
                            replyingTo = message.copyWith(
                              replyToSenderName: originalSender.name,
                            );
                            selectedMessageIds.clear();
                          });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (selectedMessageIds.isEmpty) return;

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Delete message"),
                              content: Text(
                                selectedMessageIds.length == 1
                                    ? "Delete this message?"
                                    : "Delete these ${selectedMessageIds.length} messages?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text("Delete"),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirm != true) return;

                        final messageCubit = context.read<MessageCubit>();

                        for (final id in selectedMessageIds) {
                          await messageCubit.removeMessage(
                            projectId: widget.project.id,
                            messageId: id,
                          );
                        }

                        setState(() {
                          selectedMessageIds.clear();
                        });
                      },
                    ),
                    PopupMenuButton(
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: "more",
                          child: Text("More"),
                        ),
                      ],
                    ),
                  ]
                : [
                    BlocBuilder<MessageCubit, MessageState>(
                      builder: (context, state) {
                        return IconButton(
                          tooltip: "Preview Conversation",
                          icon: const Icon(Icons.play_circle_fill),
                          onPressed: state is! MessageLoaded
                              ? null
                              : () {
                                  final personCubit =
                                      context.read<PersonCubit>();
                                  final messageCubit =
                                      context.read<MessageCubit>();

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MultiBlocProvider(
                                        providers: [
                                          BlocProvider.value(
                                              value: personCubit),
                                          BlocProvider.value(
                                              value: messageCubit),
                                          BlocProvider(
                                            create: (_) =>
                                                ConversationReplayCubit(),
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

                                      return KeyedSubtree(
                                        key: _messageKeys.putIfAbsent(
                                          message.id,
                                          () => GlobalKey(),
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 1000),
                                          curve: Curves.easeOut,
                                          color:
                                              highlightedMessageId == message.id
                                                  ? const Color(0xffA8E6A1)
                                                  : Colors.transparent,
                                          child: MessageBubble(
                                            isSelected: selectedMessageIds
                                                .contains(message.id),
                                            isHighlighted:
                                                highlightedMessageId ==
                                                    message.id,
                                            onLongPress: () {
                                              toggleMessageSelection(
                                                  message.id);
                                            },
                                            onTap: () {
                                              if (isSelectionMode) {
                                                toggleMessageSelection(
                                                    message.id);
                                              }
                                            },
                                            onReplyTap:
                                                message.replyToMessageId == null
                                                    ? null
                                                    : () {
                                                        _scrollToMessage(message
                                                            .replyToMessageId!);
                                                      },
                                            message: message,
                                            sender: sender,
                                            isMine: isMine,
                                            isGroup: widget.project
                                                    .participantIds.length >
                                                2,
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
                          replyingTo: replyingTo,
                          onCancelReply: () {
                            setState(() {
                              replyingTo = null;
                            });
                          },
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
                                  senderName: participants
                                      .firstWhere((p) => p.id == senderId)
                                      .name,
                                  text: text,
                                  replyingTo: replyingTo,
                                );

                            replyingTo = null;

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
