import 'package:flutter/material.dart';

class PlaybackKeyboard extends StatelessWidget {
  final bool visible;
  final String? pressedKey;
  final bool shiftEnabled;

  const PlaybackKeyboard({
    super.key,
    required this.visible,
    required this.pressedKey,
    required this.shiftEnabled,
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

    final keyPressed =
        isShiftKey ? false : pressedKey?.toLowerCase() == text.toLowerCase();

    final isPressed = keyPressed;

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(
                  isPressed ? .05 : .12,
                ),
                blurRadius: 1,
                offset: Offset(
                  0,
                  isPressed ? 0 : 1,
                ),
              ),
            ],
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
        ),
      ),
    );
  }
}
