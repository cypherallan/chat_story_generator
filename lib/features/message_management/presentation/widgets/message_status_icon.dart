import 'package:flutter/material.dart';

import '../../domain/entities/message_status.dart';

class MessageStatusIcon extends StatelessWidget {
  final MessageStatus status;

  const MessageStatusIcon({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(
          Icons.schedule,
          size: 13,
          color: Colors.grey.shade500,
        );

      case MessageStatus.sent:
        return Icon(
          Icons.done,
          size: 15,
          color: Colors.grey.shade500,
        );

      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 15,
          color: Colors.grey.shade500,
        );

      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 15,
          color: Color(0xff53BDEB),
        );
    }
  }
}
