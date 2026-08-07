import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';
import '../../../message_management/domain/entities/message.dart';

import '../widgets/conversation_app_bar.dart';
import '../widgets/conversation_message_list.dart';
import '../widgets/conversation_typing_section.dart';
import '../widgets/conversation_composer_section.dart';
import 'conversation_playback_page.dart';
import '../cubit/conversation_replay_cubit.dart';

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
  final Set<String> typingPersonIds = {};
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
    setState(() => selectedMessageIds.clear());
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
      setState(() => highlightedMessageId = messageId);
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => highlightedMessageId = null);
      });
    });
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
  void initState() {
    super.initState();
    selectedSenderId = widget.project.ownerId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PersonCubit>().setPersonOnline(selectedSenderId);
      context.read<ProjectCubit>().clearUnreadCount(widget.project.id);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
        appBar: ConversationAppBar(
          project: widget.project,
          isSelectionMode: isSelectionMode,
          selectedCount: selectedMessageIds.length,
          typingPersonIds: typingPersonIds,
          otherPersonTyping: otherPersonTyping,
          onClearSelection: clearMessageSelection,
          onPreviewPressed: () {
            final state = context.read<MessageCubit>().state;
            if (state is! MessageLoaded) return;

            final personCubit = context.read<PersonCubit>();
            final messageCubit = context.read<MessageCubit>();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: personCubit),
                    BlocProvider.value(value: messageCubit),
                    BlocProvider(create: (_) => ConversationReplayCubit()),
                  ],
                  child: ConversationPlaybackPage(
                    project: widget.project,
                    messages: state.messages,
                  ),
                ),
              ),
            );
          },
          selectedMessageIds: selectedMessageIds,
          onReplySelected: (message) {
            final personState = context.read<PersonCubit>().state;
            if (personState is! PersonLoaded) return;

            final originalSender = personState.persons.firstWhere(
              (p) => p.id == message.senderId,
            );

            setState(() {
              replyingTo = message.copyWith(
                replyToSenderName: originalSender.name,
              );
              selectedMessageIds.clear();
            });
          },
          onReactionSelected: (messageId, emoji) {
            context.read<MessageCubit>().toggleReaction(
                  messageId: messageId,
                  userId: widget.project.ownerId,
                  emoji: emoji,
                );
          },
          onDeleteSelected: () async {
            if (selectedMessageIds.isEmpty) return;

            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Delete message"),
                content: Text(
                  selectedMessageIds.length == 1
                      ? "Delete this message?"
                      : "Delete these ${selectedMessageIds.length} messages?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Delete"),
                  ),
                ],
              ),
            );

            if (confirm != true) return;

            final messageCubit = context.read<MessageCubit>();
            for (final id in selectedMessageIds) {
              await messageCubit.removeMessage(
                projectId: widget.project.id,
                messageId: id,
              );
            }
            setState(() => selectedMessageIds.clear());
          },
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
                      child: ConversationMessageList(
                        project: widget.project,
                        scrollController: _scrollController,
                        messageKeys: _messageKeys,
                        selectedMessageIds: selectedMessageIds,
                        highlightedMessageId: highlightedMessageId,
                        onToggleSelection: toggleMessageSelection,
                        onSwipeReply: (message) {
                          final personState = context.read<PersonCubit>().state;
                          if (personState is! PersonLoaded) return;

                          final originalSender = personState.persons.firstWhere(
                            (p) => p.id == message.senderId,
                          );

                          setState(() {
                            replyingTo = message.copyWith(
                              replyToSenderName: originalSender.name,
                            );
                          });
                        },
                        onReplyTap: _scrollToMessage,
                        onMessagesLoaded: _scrollToBottom,
                      ),
                    ),
                  ),
                  ConversationTypingSection(
                    otherPersonTyping: otherPersonTyping,
                  ),
                  ConversationComposerSection(
                    project: widget.project,
                    selectedSenderId: selectedSenderId,
                    replyingTo: replyingTo,
                    onCancelReply: () => setState(() => replyingTo = null),
                    onSenderChanged: (senderId) {
                      final previous = selectedSenderId;
                      setState(() => selectedSenderId = senderId);
                      context.read<PersonCubit>().setPersonOffline(previous);
                      context.read<PersonCubit>().setPersonOnline(senderId);
                    },
                    onTypingStarted: () {
                      if (selectedSenderId != widget.project.ownerId) {
                        setState(() {
                          typingPersonIds.add(selectedSenderId);
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
                          typingPersonIds.remove(selectedSenderId);
                          otherPersonTyping = false;
                        });
                      }
                    },
                    onImageSelected: (file) {
                      final participants =
                          (context.read<PersonCubit>().state as PersonLoaded)
                              .persons
                              .where((p) =>
                                  widget.project.participantIds.contains(p.id))
                              .toList();

                      final sender =
                          participants.where((p) => p.id == selectedSenderId);

                      if (sender.isEmpty) return;

                      context.read<MessageCubit>().createMessage(
                            projectId: widget.project.id,
                            senderId: selectedSenderId,
                            senderName: sender.first.name,
                            text: '',
                            imagePath: file.path,
                            replyingTo: replyingTo,
                          );

                      setState(() => replyingTo = null);
                    },
                    onSend: (senderId, text) {
                      final participants =
                          (context.read<PersonCubit>().state as PersonLoaded)
                              .persons
                              .where((p) =>
                                  widget.project.participantIds.contains(p.id))
                              .toList();

                      context.read<MessageCubit>().createMessage(
                            projectId: widget.project.id,
                            senderId: senderId,
                            senderName: participants
                                .firstWhere((p) => p.id == senderId)
                                .name,
                            text: text,
                            replyingTo: replyingTo,
                          );

                      if (senderId != widget.project.ownerId) {
                        context
                            .read<ProjectCubit>()
                            .incrementUnreadCount(widget.project.id);
                      }

                      setState(() => replyingTo = null);

                      if (participants.length == 2) {
                        final previousSender = selectedSenderId;
                        final nextSender = senderId == participants[0].id
                            ? participants[1].id
                            : participants[0].id;

                        setState(() => selectedSenderId = nextSender);
                        context
                            .read<PersonCubit>()
                            .setPersonOffline(previousSender);
                        context.read<PersonCubit>().setPersonOnline(nextSender);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
