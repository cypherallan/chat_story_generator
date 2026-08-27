import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';
import '../../../person_management/domain/entities/person.dart';
import 'chat_bubble_shape.dart';
import 'message_sender_avatar.dart';
import 'swipe_reply_arrow.dart';
import 'message_bubble_content.dart';
import 'message_reactions_badge.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final Person sender;
  final bool isMine;
  final bool isGroup;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isSelected;
  final bool isHighlighted;
  final double? forcedDragOffset;
  final bool forceShowReplyArrow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onReplyTap;
  final VoidCallback? onSwipeReply;

  const MessageBubble({
    super.key,
    required this.message,
    required this.sender,
    required this.isMine,
    required this.isGroup,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    this.isSelected = false,
    this.isHighlighted = false,
    this.onTap,
    this.onLongPress,
    this.onReplyTap,
    this.onSwipeReply,
    this.forcedDragOffset,
    this.forceShowReplyArrow = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0;

  double get _effectiveDragOffset {
    if (widget.forcedDragOffset != null) {
      return widget.forcedDragOffset!;
    }
    return _dragOffset;
  }

  bool get _showReplyArrow =>
      widget.forceShowReplyArrow || _effectiveDragOffset > 15;

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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onHorizontalDragUpdate: (details) {
        final delta = details.primaryDelta ?? 0;
        if (delta <= 0) return;
        setState(() {
          _dragOffset += delta;
          if (_dragOffset > 80) {
            _dragOffset = 80;
          }
        });
      },
      onHorizontalDragEnd: (_) {
        if (_dragOffset > 55) {
          widget.onSwipeReply?.call();
        }
        setState(() {
          _dragOffset = 0;
        });
      },
      onHorizontalDragCancel: () {
        setState(() {
          _dragOffset = 0;
        });
      },
      child: Align(
        alignment: widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!widget.isMine && widget.isGroup)
              MessageSenderAvatar(
                sender: widget.sender,
                isFirstInGroup: widget.isFirstInGroup,
              ),
            Stack(
              clipBehavior: Clip.none,
              alignment:
                  widget.isMine ? Alignment.centerRight : Alignment.centerLeft,
              children: [
                if (_showReplyArrow) SwipeReplyArrow(isMine: widget.isMine),
                Transform.translate(
                  offset: Offset(_effectiveDragOffset, 0),
                  child: ChatBubbleShape(
                    isMine: widget.isMine,
                    isSelected: widget.isSelected,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      margin: const EdgeInsets.fromLTRB(8, 2, 8, 6),
                      constraints: BoxConstraints(
                        maxWidth: widget.isGroup && !widget.isMine
                            ? MediaQuery.of(context).size.width * .68
                            : MediaQuery.of(context).size.width * .75,
                        minWidth: 80,
                      ),
                      child: MessageBubbleContent(
                        message: widget.message,
                        sender: widget.sender,
                        isMine: widget.isMine,
                        isGroup: widget.isGroup,
                        isFirstInGroup: widget.isFirstInGroup,
                        isLastInGroup: widget.isLastInGroup,
                        timeText: _formatTime(widget.message.createdAt),
                        onReplyTap: widget.onReplyTap,
                      ),
                    ),
                  ),
                ),
                if (widget.message.reactions.isNotEmpty)
                  MessageReactionsBadge(
                    isMine: widget.isMine,
                    reactions: widget.message.reactions.values,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
