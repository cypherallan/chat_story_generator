import 'package:flutter/material.dart';
import '../../../person_management/domain/entities/person.dart';
import 'expression_panel.dart';
import 'attachment_sheet.dart';
import '../../domain/entities/message.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageComposer extends StatefulWidget {
  final List<Person> participants;
  final String selectedSenderId;
  final ValueChanged<String> onSenderChanged;
  final Function(String senderId, String text) onSend;
  final ValueChanged<Map<String, dynamic>> onImageSelected;
  final VoidCallback? onTypingStarted;
  final Message? replyingTo;
  final VoidCallback? onCancelReply;
  final VoidCallback? onTypingStopped;

  const MessageComposer({
    super.key,
    required this.participants,
    required this.selectedSenderId,
    required this.onSenderChanged,
    required this.onSend,
    required this.onImageSelected,
    this.onTypingStarted,
    this.onTypingStopped,
    this.replyingTo,
    this.onCancelReply,
  });

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  final controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmoji = false;
  bool _showAttachments = false;
  bool _showParticipants = false; // NEW for Task 1
  bool hasText = false;
  final List<int> _typingDelays = [];
  DateTime? _lastTypingTime;

  @override
  void initState() {
    super.initState();
    controller.addListener(() {
      final value = controller.text.trim().isNotEmpty;
      if (value != hasText) {
        setState(() => hasText = value);
      }
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        widget.onTypingStarted?.call();
      } else {
        widget.onTypingStopped?.call();
      }
    });
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(widget.selectedSenderId, text);
    controller.clear();
    _typingDelays.clear();
    _lastTypingTime = null;
    // FIX Task 1: keep keyboard on screen
    FocusScope.of(context).requestFocus(_focusNode);
    setState(() {
      hasText = false;
      _showEmoji = false;
      _showAttachments = false;
      _showParticipants = false;
    });
  }

  @override
  void dispose() {
    controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (widget.replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade300))),
            child: Row(children: [
              Container(width: 4, height: 40, color: const Color(0xff25D366)),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text("Replying",
                        style: TextStyle(
                            color: Color(0xff25D366),
                            fontWeight: FontWeight.bold)),
                    Text(widget.replyingTo!.text,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ])),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancelReply),
            ]),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(children: [
            Expanded(
                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(24)),
              child: Row(children: [
                // FIX Task 1: replaced PopupMenuButton with panel that keeps keyboard
                Builder(builder: (context) {
                  if (widget.participants.isEmpty)
                    return const SizedBox.shrink();
                  final currentPerson = widget.participants.firstWhere(
                      (p) => p.id == widget.selectedSenderId,
                      orElse: () => widget.participants.first);
                  ImageProvider? image;
                  if (currentPerson.avatarPath != null &&
                      currentPerson.avatarPath!.startsWith('http')) {
                    image =
                        CachedNetworkImageProvider(currentPerson.avatarPath!);
                  }
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _showParticipants = !_showParticipants;
                        _showEmoji = false;
                        _showAttachments = false;
                      });
                      FocusScope.of(context).requestFocus(_focusNode);
                    },
                    child: Container(
                      key: ValueKey(currentPerson.id),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(30)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        CircleAvatar(
                            radius: 12,
                            backgroundImage: image,
                            child: image == null
                                ? Text(currentPerson.name[0].toUpperCase())
                                : null),
                        const SizedBox(width: 6),
                        Text(currentPerson.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Icon(_showParticipants
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded),
                      ]),
                    ),
                  );
                }),
                IconButton(
                    icon: Icon(_showEmoji
                        ? Icons.keyboard_outlined
                        : Icons.sentiment_satisfied_alt_outlined),
                    onPressed: () {
                      if (_showEmoji) {
                        setState(() => _showEmoji = false);
                        FocusScope.of(context).requestFocus(_focusNode);
                        return;
                      }
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _showAttachments = false;
                        _showEmoji = true;
                        _showParticipants = false;
                      });
                    }),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: _focusNode,
                    autofocus: false,
                    decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none),
                    minLines: 1,
                    maxLines: 5,
                    onChanged: (value) {
                      final now = DateTime.now();

                      if (value.isNotEmpty) {
                        if (_lastTypingTime != null) {
                          _typingDelays.add(
                            now.difference(_lastTypingTime!).inMilliseconds,
                          );
                        } else {
                          // Delay before the first character.
                          _typingDelays.add(0);
                        }

                        _lastTypingTime = now;
                      }

                      if (value.trim().isNotEmpty) {
                        widget.onTypingStarted?.call();
                      }
                    },
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.attach_file),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      setState(() {
                        _showEmoji = false;
                        _showAttachments = !_showAttachments;
                        _showParticipants = false;
                      });
                    }),
                IconButton(
                    icon: const Icon(Icons.camera_alt), onPressed: () {}),
              ]),
            )),
            const SizedBox(width: 6),
            CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green,
                child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) =>
                        ScaleTransition(scale: animation, child: child),
                    child: hasText
                        ? IconButton(
                            key: const ValueKey("send"),
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _send)
                        : IconButton(
                            key: const ValueKey("mic"),
                            icon: const Icon(Icons.mic, color: Colors.white),
                            onPressed: () {}))),
          ]),
        ),
        // FIX Task 1: participants list appears ABOVE keyboard, not behind it
        if (_showParticipants)
          Container(
            height: 180,
            color: Colors.white,
            child: ListView(
                children: widget.participants
                    .map((person) => ListTile(
                          leading: CircleAvatar(
                              child: Text(person.name[0].toUpperCase())),
                          title: Text(person.name),
                          trailing: person.id == widget.selectedSenderId
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            widget.onSenderChanged(person.id);
                            setState(() => _showParticipants = false);
                            FocusScope.of(context).requestFocus(_focusNode);
                          },
                        ))
                    .toList()),
          ),
        if (_showEmoji) ExpressionPanel(controller: controller),
        if (_showAttachments)
          SizedBox(
              height: 280,
              child: AttachmentSheet(
                  onImageSelected: widget.onImageSelected,
                  onClose: () => setState(() => _showAttachments = false))),
      ]),
    );
  }
}
