import 'package:flutter/material.dart';

import '../../domain/entities/message.dart';
import '../../../person_management/domain/entities/person.dart';
import 'message_status_icon.dart';
import 'chat_bubble_shape.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final Person sender;
  final bool isMine;
  final bool isGroup;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final bool isSelected;
  final bool isHighlighted;
  final double? forcedDragOffset; // NEW
  final bool forceShowReplyArrow; // NEW
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
    this.forcedDragOffset, // NEW
    this.forceShowReplyArrow = false, // NEW
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

  ImageProvider? _getAvatarImage() {
    final avatarPath = widget.sender.avatarPath;

    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }

    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return CachedNetworkImageProvider(avatarPath);
    }

    // Local Windows/device paths are intentionally not loaded here.
    // They are not valid network URLs.
    return null;
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
                SizedBox(
                  width: 42,
                  child: widget.isLastInGroup
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: _getAvatarImage(),
                          child: _getAvatarImage() == null
                              ? Text(
                                  widget.sender.name.isNotEmpty
                                      ? widget.sender.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 13),
                                )
                              : null,
                        )
                      : null,
                ),
              Stack(
                  clipBehavior: Clip.none,
                  alignment: widget.isMine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  children: [
                    if (_showReplyArrow)
                      Positioned(
                        left: widget.isMine ? null : 8,
                        right: widget.isMine ? 8 : null,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Color(0xff25D366),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.reply,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    Transform.translate(
                      offset: Offset(_effectiveDragOffset, 0),
                      child: ChatBubbleShape(
                        isMine: widget.isMine,
                        isSelected: widget.isSelected,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 1000),
                          margin: const EdgeInsets.fromLTRB(
                            8,
                            2,
                            8,
                            6,
                          ),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * .75,
                            minWidth: 80,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isGroup &&
                                  !widget.isMine &&
                                  widget.isLastInGroup)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    widget.sender.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.message.replyToSenderName ??
                                              '',
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
                              widget.message.imagePath != null &&
                                      !widget.message.isDeleted
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          child: widget.message.imagePath!
                                                  .startsWith('http')
                                              ? CachedNetworkImage(
                                                  imageUrl:
                                                      widget.message.imagePath!,
                                                  width: 250,
                                                  fit: BoxFit.cover,
                                                  memCacheWidth: 750,
                                                  maxWidthDiskCache: 750,
                                                  placeholder: (context, url) =>
                                                      Container(
                                                    width: 250,
                                                    height: 250,
                                                    color: Colors.grey.shade200,
                                                    child: const Center(
                                                      child: SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Container(
                                                    width: 250,
                                                    height: 250,
                                                    color: Colors.grey.shade200,
                                                    child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                )
                                              : Image.file(
                                                  File(widget
                                                      .message.imagePath!),
                                                  width: 250,
                                                  cacheWidth: 750,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        if (widget.message.text.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 6,
                                            ),
                                            child: Text(
                                              widget.message.text,
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                height: 1.3,
                                                color: widget.message.isDeleted
                                                    ? Colors.grey
                                                    : Colors.black87,
                                                fontStyle:
                                                    widget.message.isDeleted
                                                        ? FontStyle.italic
                                                        : FontStyle.normal,
                                              ),
                                            ),
                                          ),
                                      ],
                                    )
                                  : Text(
                                      widget.message.text,
                                      style: TextStyle(
                                        fontSize: 15.5,
                                        height: 1.3,
                                        color: widget.message.isDeleted
                                            ? Colors.grey
                                            : Colors.black87,
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
                                    if (widget.isMine &&
                                        !widget.message.isDeleted) ...[
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
                    ),
                    if (widget.message.reactions.isNotEmpty)
                      Positioned(
                        bottom: -12,
                        left: widget.isMine ? null : 12,
                        right: widget.isMine ? 12 : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Text(
                            widget.message.reactions.values.join(' '),
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ]),
            ]),
      ),
    );
  }
}
