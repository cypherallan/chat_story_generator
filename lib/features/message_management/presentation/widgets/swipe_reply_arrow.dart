import 'package:flutter/material.dart';

class SwipeReplyArrow extends StatelessWidget {
  final bool isMine;

  const SwipeReplyArrow({
    super.key,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isMine ? null : 8,
      right: isMine ? 8 : null,
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
    );
  }
}
