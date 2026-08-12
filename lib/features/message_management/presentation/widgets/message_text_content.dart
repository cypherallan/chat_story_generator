import 'package:flutter/material.dart';

class MessageTextContent extends StatelessWidget {
  final String text;
  final bool isDeleted;

  const MessageTextContent({
    super.key,
    required this.text,
    required this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15.5,
        height: 1.3,
        color: isDeleted ? Colors.grey : Colors.black87,
        fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
      ),
    );
  }
}
