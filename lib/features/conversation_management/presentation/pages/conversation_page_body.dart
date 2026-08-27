import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../project_management/domain/entities/project.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';
import '../../../message_management/domain/entities/message.dart';

import '../widgets/conversation_message_list.dart';
import '../widgets/conversation_typing_section.dart';
import '../widgets/conversation_composer_section.dart';
import 'dart:io';

class ConversationPageBody extends StatefulWidget {
  final Project project;
  final VoidCallback onChanged;

  const ConversationPageBody({
    super.key,
    required this.project,
    required this.onChanged,
  });

  @override
  State<ConversationPageBody> createState() => ConversationPageBodyState();
}

class ConversationPageBodyState extends State<ConversationPageBody> {
  late String selectedSenderId;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = {};
  final Set<String> typingPersonIds = {};
  bool otherPersonTyping = false;
  final Set<String> selectedMessageIds = {};
  Message? replyingTo;
  String? highlightedMessageId;

  bool get isSelectionMode => selectedMessageIds.isNotEmpty;

  int get currentMessageCount {
    final messageState = context.read<MessageCubit>().state;

    if (messageState is MessageLoaded) {
      return messageState.messages.length;
    }

    return 0;
  }

  @override
  void initState() {
    super.initState();
    selectedSenderId = widget.project.ownerId;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _notifyParent() {
    widget.onChanged();
  }

  void toggleMessageSelection(String messageId) {
    setState(() {
      if (selectedMessageIds.contains(messageId)) {
        selectedMessageIds.remove(messageId);
      } else {
        selectedMessageIds.add(messageId);
      }
    });
    _notifyParent();
  }

  void clearMessageSelection() {
    setState(() => selectedMessageIds.clear());
    _notifyParent();
  }

  void setReplyingTo(Message message) {
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
    _notifyParent();
  }

  Future<void> deleteSelectedMessages() async {
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

    final messages = (messageCubit.state as MessageLoaded).messages;

    for (final id in selectedMessageIds) {
      final message = messages.firstWhere(
        (message) => message.id == id,
      );

      if (message.isDeleted) {
        await messageCubit.permanentlyDeleteMessage(
          projectId: widget.project.id,
          messageId: id,
        );
      } else {
        await messageCubit.removeMessage(
          projectId: widget.project.id,
          messageId: id,
        );
      }
    }
    setState(() => selectedMessageIds.clear());
    _notifyParent();
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
                    project: widget.project,
                    scrollController: _scrollController,
                    messageKeys: _messageKeys,
                    selectedMessageIds: selectedMessageIds,
                    highlightedMessageId: highlightedMessageId,
                    onToggleSelection: toggleMessageSelection,
                    onSwipeReply: setReplyingTo,
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
                onCancelReply: () {
                  setState(() => replyingTo = null);
                  _notifyParent();
                },
                onSenderChanged: (senderId) {
                  final previous = selectedSenderId;
                  setState(() {
                    selectedSenderId = senderId;
                    if (senderId != widget.project.ownerId) {
                      typingPersonIds
                        ..clear()
                        ..add(senderId);
                      otherPersonTyping = true;
                    } else {
                      typingPersonIds.clear();
                      otherPersonTyping = false;
                    }
                  });
                  context.read<PersonCubit>().setPersonOffline(previous);
                  context.read<PersonCubit>().setPersonOnline(senderId);
                  _notifyParent();
                },
                onTypingStarted: () {
                  if (selectedSenderId != widget.project.ownerId) {
                    setState(() {
                      typingPersonIds
                        ..clear()
                        ..add(selectedSenderId);
                      otherPersonTyping = true;
                    });
                    context.read<MessageCubit>().markOutgoingMessagesAsRead(
                          projectId: widget.project.id,
                          currentUserId: widget.project.ownerId,
                        );
                    _notifyParent();
                    return;
                  }
                  setState(() {
                    typingPersonIds.clear();
                    otherPersonTyping = false;
                  });
                  context.read<MessageCubit>().markMessagesAsRead(
                        projectId: widget.project.id,
                        currentUserId: widget.project.ownerId,
                      );
                  context
                      .read<ProjectCubit>()
                      .clearUnreadCount(widget.project.id);
                  _notifyParent();
                },
                onTypingStopped: () {
                  if (mounted) {
                    setState(() {
                      typingPersonIds.remove(selectedSenderId);
                      otherPersonTyping = false;
                    });
                    _notifyParent();
                  }
                },
                onImageSelected: (result) {
                  final file = result['image'] as File;
                  final caption = result['caption'] as String;
                  final participants = (context.read<PersonCubit>().state
                          as PersonLoaded)
                      .persons
                      .where(
                          (p) => widget.project.participantIds.contains(p.id))
                      .toList();

                  final sender =
                      participants.where((p) => p.id == selectedSenderId);

                  if (sender.isEmpty) return;

                  if (selectedSenderId == widget.project.ownerId) {
                    context.read<MessageCubit>().markMessagesAsRead(
                          projectId: widget.project.id,
                          currentUserId: widget.project.ownerId,
                        );
                    context
                        .read<ProjectCubit>()
                        .clearUnreadCount(widget.project.id);
                  }

                  context.read<MessageCubit>().createMessage(
                        projectId: widget.project.id,
                        senderId: selectedSenderId,
                        senderName: sender.first.name,
                        text: caption,
                        imagePath: file.path,
                        replyingTo: replyingTo,
                        isUnread: selectedSenderId != widget.project.ownerId,
                      );

                  setState(() => replyingTo = null);
                  _notifyParent();
                },
                onSend: (senderId, text) {
                  final participants = (context.read<PersonCubit>().state
                          as PersonLoaded)
                      .persons
                      .where(
                          (p) => widget.project.participantIds.contains(p.id))
                      .toList();

                  if (senderId == widget.project.ownerId) {
                    context.read<MessageCubit>().markMessagesAsRead(
                          projectId: widget.project.id,
                          currentUserId: widget.project.ownerId,
                        );
                    context
                        .read<ProjectCubit>()
                        .clearUnreadCount(widget.project.id);
                  }

                  context.read<MessageCubit>().createMessage(
                        projectId: widget.project.id,
                        senderId: senderId,
                        senderName: participants
                            .firstWhere((p) => p.id == senderId)
                            .name,
                        text: text,
                        replyingTo: replyingTo,
                        isUnread: senderId != widget.project.ownerId,
                      );

                  if (senderId != widget.project.ownerId) {
                    context
                        .read<ProjectCubit>()
                        .incrementUnreadCount(widget.project.id);
                  }

                  setState(() {
                    replyingTo = null;
                    typingPersonIds.clear();
                    otherPersonTyping = false;
                  });
                  _notifyParent();

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
                    _notifyParent();
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
