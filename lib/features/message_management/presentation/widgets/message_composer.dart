import 'package:flutter/material.dart';
import '../../../person_management/domain/entities/person.dart';
import 'expression_panel.dart';
import 'attachment_sheet.dart';
import '../../domain/entities/message.dart';

class MessageComposer extends StatefulWidget {
  final List<Person> participants;
  final String selectedSenderId;
  final ValueChanged<String> onSenderChanged;
  final Function(String senderId, String text) onSend;

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
  bool hasText = false;

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      final value = controller.text.trim().isNotEmpty;

      if (value != hasText) {
        setState(() {
          hasText = value;
        });
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

    widget.onSend(
      widget.selectedSenderId,
      text,
    );

    controller.clear();

    _focusNode.unfocus();

    widget.onTypingStopped?.call();

    setState(() {
      hasText = false;

      _showEmoji = false;
      _showAttachments = false;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    color: const Color(0xff25D366),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Replying",
                          style: TextStyle(
                            color: Color(0xff25D366),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.replyingTo!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancelReply,
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        PopupMenuButton<String>(
                          onSelected: widget.onSenderChanged,
                          itemBuilder: (context) {
                            return widget.participants.map((person) {
                              return PopupMenuItem<String>(
                                value: person.id,
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      child: Text(
                                        person.name[0].toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(person.name),
                                    ),
                                    if (person.isVerified)
                                      const Icon(
                                        Icons.verified,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                  ],
                                ),
                              );
                            }).toList();
                          },
                          child: Builder(
                            builder: (context) {
                              final currentPerson =
                                  widget.participants.firstWhere(
                                (person) =>
                                    person.id == widget.selectedSenderId,
                              );
                              ImageProvider? image;

                              if (currentPerson.avatarPath != null &&
                                  currentPerson.avatarPath!
                                      .startsWith('http')) {
                                image = NetworkImage(currentPerson.avatarPath!);
                              }

                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: ScaleTransition(
                                      scale: animation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  key: ValueKey(currentPerson.id),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundImage: image,
                                        child: image == null
                                            ? Text(
                                                currentPerson.name[0]
                                                    .toUpperCase(),
                                              )
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        currentPerson.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.keyboard_arrow_down_rounded,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _showEmoji
                                ? Icons.keyboard_outlined
                                : Icons.sentiment_satisfied_alt_outlined,
                          ),
                          onPressed: () {
                            if (_showEmoji) {
                              setState(() {
                                _showEmoji = false;
                              });

                              FocusScope.of(context).requestFocus(_focusNode);
                              return;
                            }

                            FocusScope.of(context).unfocus();

                            setState(() {
                              _showAttachments = false;
                              _showEmoji = true;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            focusNode: _focusNode,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                            ),
                            minLines: 1,
                            maxLines: 5,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.attach_file,
                          ),
                          onPressed: () {
                            FocusScope.of(context).unfocus();

                            setState(() {
                              if (_showEmoji) {
                                _showEmoji = false;
                                _showAttachments = true;
                              } else {
                                _showAttachments = !_showAttachments;
                              }
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.green,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: hasText
                        ? IconButton(
                            key: const ValueKey("send"),
                            icon: const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                            onPressed: _send,
                          )
                        : IconButton(
                            key: const ValueKey("mic"),
                            icon: const Icon(
                              Icons.mic,
                              color: Colors.white,
                            ),
                            onPressed: () {},
                          ),
                  ),
                ),
              ],
            ),
          ),
          if (_showEmoji)
            ExpressionPanel(
              controller: controller,
            ),
          if (_showAttachments)
            const SizedBox(
              height: 280,
              child: AttachmentSheet(),
            ),
        ],
      ),
    );
  }
}
