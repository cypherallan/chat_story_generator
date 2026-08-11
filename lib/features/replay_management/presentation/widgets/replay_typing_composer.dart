import 'package:flutter/material.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import 'blinking_cursor.dart';

class ReplayTypingComposer extends StatelessWidget {
  final ConversationReplayState state;
  final ConversationReplayCubit replayCubit;

  const ReplayTypingComposer({
    super.key,
    required this.state,
    required this.replayCubit,
  });

  @override
  Widget build(BuildContext context) {
    // During replay, the composer is visible only when
    // the simulated owner is typing.
    if (!state.keyboardVisible &&
        !state.emojiKeyboardVisible &&
        state.composerText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildComposer(context),
        if (state.emojiKeyboardVisible) _buildEmojiKeyboard(context),
      ],
    );
  }

  Widget _buildComposer(BuildContext context) {
    final bool showCursor =
        state.keyboardVisible && state.playing && !state.emojiKeyboardVisible;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        6,
        6,
        6,
        6,
      ),
      color: const Color(0xFFEFEFEF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.emoji_emotions_outlined,
              color: Colors.grey,
            ),
            onPressed: null,
          ),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(
                minHeight: 44,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _buildTypedText(
                      showCursor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.attach_file,
                    size: 22,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 21,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFF25D366),
            child: Icon(
              state.composerText.isEmpty ? Icons.mic : Icons.send,
              color: Colors.white,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypedText(bool showCursor) {
    final text = state.composerText;

    if (text.isEmpty && !showCursor) {
      return const Text(
        'Message',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 16,
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text(
          text.isEmpty ? '' : text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        if (showCursor) const BlinkingCursor(),
        if (state.lastPressedEmoji != null)
          Padding(
            padding: const EdgeInsets.only(
              left: 2,
            ),
            child: Transform.scale(
              scale: 1.15,
              child: Text(
                state.lastPressedEmoji!,
                style: const TextStyle(
                  fontSize: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmojiKeyboard(BuildContext context) {
    final emojis = state.availableEmojis;

    if (emojis.isEmpty) {
      return Container(
        height: 230,
        color: const Color(0xFFF7F7F7),
        alignment: Alignment.center,
        child: const Text(
          'No emojis in this conversation',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    return Container(
      height: 230,
      width: double.infinity,
      color: const Color(0xFFF7F7F7),
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          childAspectRatio: 1,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          final emoji = emojis[index];

          final isPressed = state.lastPressedEmoji == emoji;

          return AnimatedScale(
            scale: isPressed ? 1.35 : 1.0,
            duration: const Duration(
              milliseconds: 80,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(
                  fontSize: 27,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
