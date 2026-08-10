import 'dart:async';
import 'package:flutter/material.dart';

class PlaybackKeyboard extends StatelessWidget {
  final bool visible;
  final String? pressedKey;
  final bool shiftEnabled;
  final bool shiftPressed;

  final bool emojiKeyboardVisible;
  final String? pressedEmoji;

  final List<String> availableEmojis;
  final int emojiPressCount;

  const PlaybackKeyboard({
    super.key,
    required this.visible,
    required this.pressedKey,
    required this.shiftEnabled,
    required this.shiftPressed,
    required this.emojiKeyboardVisible,
    required this.pressedEmoji,
    this.availableEmojis = const [],
    this.emojiPressCount = 0,
  });

  Widget _key(
    String text,
    String? pressedKey, {
    double flex = 1,
  }) {
    final isShiftKey = text == "⇧";

    final displayText = isShiftKey
        ? text
        : (shiftEnabled ? text.toUpperCase() : text.toLowerCase());

    final isPressed = isShiftKey
        ? shiftPressed
        : pressedKey?.toLowerCase() == text.toLowerCase();

    return Expanded(
      flex: (flex * 10).toInt(),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          height: 42,
          decoration: BoxDecoration(
            color: isPressed ? const Color(0xffC7CCD2) : Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 70),
              scale: isPressed ? 0.92 : 1,
              child: Text(
                displayText,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 250),
      offset: visible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: visible ? 1 : 0,
        child: Container(
          color: const Color(0xffD9DDE3),
          height: emojiKeyboardVisible ? 280 : null,
          child: emojiKeyboardVisible
              ? _PlaybackEmojiGrid(
                  emojis: availableEmojis.isNotEmpty
                      ? availableEmojis
                      : _defaultEmojis,
                  pressedEmoji: pressedEmoji,
                  pressCount: emojiPressCount,
                )
              : _buildLetters(),
        ),
      ),
    );
  }

  Widget _buildLetters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _key("q", pressedKey),
              _key("w", pressedKey),
              _key("e", pressedKey),
              _key("r", pressedKey),
              _key("t", pressedKey),
              _key("y", pressedKey),
              _key("u", pressedKey),
              _key("i", pressedKey),
              _key("o", pressedKey),
              _key("p", pressedKey),
            ],
          ),
          Row(
            children: [
              const Spacer(),
              _key("a", pressedKey),
              _key("s", pressedKey),
              _key("d", pressedKey),
              _key("f", pressedKey),
              _key("g", pressedKey),
              _key("h", pressedKey),
              _key("j", pressedKey),
              _key("k", pressedKey),
              _key("l", pressedKey),
              const Spacer(),
            ],
          ),
          Row(
            children: [
              _key("⇧", pressedKey, flex: 1.3),
              _key("z", pressedKey),
              _key("x", pressedKey),
              _key("c", pressedKey),
              _key("v", pressedKey),
              _key("b", pressedKey),
              _key("n", pressedKey),
              _key("m", pressedKey),
              _key("⌫", pressedKey, flex: 1.3),
            ],
          ),
          Row(
            children: [
              _key("123", pressedKey, flex: 1.3),
              _key(",", pressedKey, flex: .8),
              _key("space", pressedKey, flex: 4),
              _key(".", pressedKey, flex: .8),
              _key("⏎", pressedKey, flex: 1.3),
            ],
          ),
        ],
      ),
    );
  }
}

const _defaultEmojis = [
  "😀",
  "😂",
  "😍",
  "😎",
  "😢",
  "😭",
  "🔥",
  "❤️",
  "👍",
  "🎉",
  "🤔",
  "😊",
  "🙏",
  "💯",
  "✨",
  "🥳",
  "😅",
  "🤣",
  "😇",
  "🥰",
  "😉",
  "👀",
  "🫶",
  "🤷",
];

class _PlaybackEmojiGrid extends StatelessWidget {
  final List<String> emojis;
  final String? pressedEmoji;
  final int pressCount;

  const _PlaybackEmojiGrid({
    required this.emojis,
    required this.pressedEmoji,
    required this.pressCount,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      clipBehavior: Clip.none,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, index) {
        final emoji = emojis[index];
        return _EmojiCell(
          emoji: emoji,
          isPressed: pressedEmoji == emoji,
          pressCount: pressedEmoji == emoji ? pressCount : 0,
        );
      },
    );
  }
}

class _EmojiCell extends StatefulWidget {
  final String emoji;
  final bool isPressed;
  final int pressCount;

  const _EmojiCell({
    required this.emoji,
    required this.isPressed,
    required this.pressCount,
  });

  @override
  State<_EmojiCell> createState() => _EmojiCellState();
}

class _EmojiCellState extends State<_EmojiCell> {
  bool _flash = false;
  Timer? _timer;

  @override
  void didUpdateWidget(_EmojiCell oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Every time pressCount increments, trigger an independent flash
    if (widget.pressCount != oldWidget.pressCount && widget.pressCount > 0) {
      _triggerFlash();
    }
  }

  void _triggerFlash() {
    _timer?.cancel();

    setState(() => _flash = true);

    _timer = Timer(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() => _flash = false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // _flash is independent and local — it fires on every tap no matter how fast
    final bool pressed = _flash || widget.isPressed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 50),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: pressed ? const Color(0xFF9BA3AB) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: AnimatedScale(
          duration: const Duration(milliseconds: 50),
          curve: Curves.easeOut,
          scale: pressed ? 0.82 : 1.0,
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }
}
