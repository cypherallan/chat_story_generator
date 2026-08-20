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

        return SizedBox(
          height: composerHeight +
              _navigationBarHeight +
              (keyboardVisible ? keyboardHeight : 0),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                left: 0,
                right: 0,
                bottom: _navigationBarHeight +
                    (keyboardVisible ? keyboardHeight : 0),
                child: PlaybackMessageComposer(
                  text: state.composerText,
                  keyboardVisible: keyboardVisible,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: _navigationBarHeight,
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PlaybackNavigationBar(
                  onBackPressed: () {
                    context.read<ConversationReplayCubit>().hideKeyboard();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
