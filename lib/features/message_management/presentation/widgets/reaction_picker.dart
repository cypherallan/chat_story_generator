import 'package:flutter/material.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onSelected;

  const ReactionPicker({
    super.key,
    required this.onSelected,
  });

  static const emojis = [
    '❤️',
    '😂',
    '😮',
    '😢',
    '👍',
    '🙏',
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: emojis.map(
            (emoji) {
              return GestureDetector(
                onTap: () {
                  onSelected(emoji);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                  ),
                  child: Text(
                    emoji,
                    style: const TextStyle(
                      fontSize: 28,
                    ),
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}
