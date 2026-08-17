part of 'conversation_replay_cubit.dart';

mixin _SwipeReplyMixin on _ConversationReplayCubitBase {
  @override
  void _performSwipeThenType(Message message) {
    final targetId = message.replyToMessageId!;

    // Make sure the target message is already visible
    final targetExists = state.visibleMessages.any((m) => m.id == targetId);

    if (!targetExists) {
      // Fallback – just type without swipe
      _startOwnerTyping(message);
      return;
    }

    // 1. Start swipe animation
    emit(
      state.copyWith(
        swipingMessageId: targetId,
        swipeOffset: 0,
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        clearReplyPreview: true,
      ),
    );

    // Animate the swipe over ~450 ms
    const steps = 12;
    const stepDuration = Duration(milliseconds: 35);
    int step = 0;

    void animateStep() {
      if (!state.playing) return;

      step++;
      final progress = step / steps;
      final offset = 80.0 * progress; // same max as MessageBubble

      emit(
        state.copyWith(
          swipeOffset: offset,
        ),
      );

      if (step < steps) {
        _timer = Timer(stepDuration, animateStep);
      } else {
        // 2. Swipe finished → show reply preview and start typing
        _timer = Timer(const Duration(milliseconds: 180), () {
          if (!state.playing) return;

          emit(
            state.copyWith(
              clearSwipe: true, // hide the swipe visual
              replyPreviewText: message.replyToText,
              replyPreviewSenderName: message.replyToSenderName,
            ),
          );

          // Small pause so user can see the preview appear
          _timer = Timer(const Duration(milliseconds: 350), () {
            if (!state.playing) return;
            _startOwnerTyping(message);
          });
        });
      }
    }

    // Small delay before the swipe starts (feels more natural)
    _timer = Timer(const Duration(milliseconds: 300), animateStep);
  }
}
