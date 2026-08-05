import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';
import '../../../person_management/domain/entities/person.dart';
import 'message_status_icon.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final Person sender;
  final bool isMine;
  final bool isGroup;
  final bool isSelected;
  final bool isHighlighted;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplyTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
    required this.isMine,
    required this.isGroup,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
    this.onLongPress,
    this.onReplyTap,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        setState(() {});
      });

    if (widget.isHighlighted) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  ImageProvider? _getAvatarImage() {
    if (widget.sender.avatarPath == null || widget.sender.avatarPath!.isEmpty) {
      return null;
    }

    if (widget.sender.avatarPath!.startsWith('http')) {
      return NetworkImage(widget.sender.avatarPath!);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Align(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          margin: const EdgeInsets.symmetric(
            vertical: 2,
            horizontal: 8,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * .75,
            minWidth: 80,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0x3325D366)
                : widget.isMine
                    ? const Color(0xffE7FFDB)
                    : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(widget.isMine ? 16 : 4),
              bottomRight: Radius.circular(widget.isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isGroup && !widget.isMine)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: _getAvatarImage(),
                      child: widget.sender.avatarPath == null ||
                              widget.sender.avatarPath!.isEmpty
                          ? Text(
                              widget.sender.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.sender.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                        fontSize: 13,
                      ),
                    )
                  ],
                ),
              if (!widget.message.isDeleted &&
                  widget.message.replyToText != null)
                GestureDetector(
                  onTap: widget.onReplyTap,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.05),
                      borderRadius: BorderRadius.circular(8),
                      border: const Border(
                        left: BorderSide(
                          color: Color(0xff25D366),
                          width: 4,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.message.replyToSenderName ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xff25D366),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          widget.message.replyToText!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Text(
                widget.message.text,
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.3,
                  color:
                      widget.message.isDeleted ? Colors.grey : Colors.black87,
                  fontStyle: widget.message.isDeleted
                      ? FontStyle.italic
                      : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.bottomRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.message.isEdited)
                      const Text(
                        "Edited",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(
                        widget.message.createdAt,
                      ),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    if (widget.isMine && !widget.message.isDeleted) ...[
                      const SizedBox(width: 3),
                      MessageStatusIcon(
                        status: widget.message.status,
                      )
                    ]
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
