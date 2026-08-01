import 'package:flutter/material.dart';
import 'blinking_cursor.dart';

class PlaybackMessageComposer extends StatelessWidget {
  final String text;
  final bool keyboardVisible;

  const PlaybackMessageComposer({
    super.key,
    required this.text,
    required this.keyboardVisible,
  });

  @override
  Widget build(BuildContext context) {
    final hasText = text.isNotEmpty;

    return SafeArea(
      top: false,
      child: Material(
        color: const Color(0xffF0F2F5),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            if (text.isEmpty) const SizedBox(),
                            if (text.isNotEmpty)
                              Flexible(
                                child: Text(
                                  text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                            const BlinkingCursor(),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.attach_file,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.camera_alt,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xff25D366),
                child: Icon(
                  hasText ? Icons.send : Icons.mic,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
