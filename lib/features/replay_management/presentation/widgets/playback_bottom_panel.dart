import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import 'playback_keyboard.dart';
import 'playback_message_composer.dart';
import 'playback_navigation_bar.dart';

class PlaybackBottomPanel extends StatelessWidget {
  const PlaybackBottomPanel({super.key});

  static const double _baseComposerHeight = 62;
  static const double _replyPreviewHeight = 72;
  static const double _keyboardHeight = 228;
  static const double _emojiKeyboardHeight = 280;
  static const double _navigationBarHeight = 48;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
      builder: (context, state) {
        final keyboardVisible =
            state.keyboardVisible || state.emojiKeyboardVisible;
        final keyboardHeight =
            state.emojiKeyboardVisible ? _emojiKeyboardHeight : _keyboardHeight;
        final hasReplyPreview = state.replyPreviewText != null;
        final composerHeight =
            _baseComposerHeight + (hasReplyPreview ? _replyPreviewHeight : 0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Composer - always visible above keyboard
            SizedBox(
              height: composerHeight,
              child: PlaybackMessageComposer(
                text: state.composerText,
                keyboardVisible: keyboardVisible,
              ),
            ),

            // Keyboard - slides in/out but keeps space reserved
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: keyboardVisible ? keyboardHeight : 0,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  height: keyboardHeight,
                  child: PlaybackKeyboard(
                    visible: keyboardVisible,
                    pressedKey: state.pressedKey,
                    shiftEnabled: state.shiftEnabled,
                    shiftPressed: state.shiftPressed,
                    emojiKeyboardVisible: state.emojiKeyboardVisible,
                    pressedEmoji: state.lastPressedEmoji,
                    availableEmojis: state.availableEmojis,
                    emojiPressCount: state.emojiPressCount,
                  ),
                ),
              ),
            ),

            // Navigation bar - ALWAYS at very bottom, fixed 48px
            SizedBox(
              height: _navigationBarHeight,
              child: PlaybackNavigationBar(
                onBackPressed: () {
                  context.read<ConversationReplayCubit>().hideKeyboard();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
