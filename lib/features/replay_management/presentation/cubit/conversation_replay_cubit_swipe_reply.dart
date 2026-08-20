part of 'conversation_replay_cubit.dart';

mixin _SwipeReplyMixin on _ConversationReplayCubitBase {
  @override
  void _performSwipeThenType(Message message) {
    final targetId = message.replyToMessageId!;
    final targetExists = state.visibleMessages.any((m) => m.id == targetId);

    if (!targetExists) {
      _startOwnerTyping(message);
      return;
    }
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

    const steps = 12;
    const stepDuration = Duration(milliseconds: 35);
    int step = 0;

    void animateStep() {
      if (!state.playing) return;

      step++;
      final progress = step / steps;
      final offset = 80.0 * progress;

      emit(
        state.copyWith(
          swipeOffset: offset,
        ),
      );

      if (step < steps) {
        _timer = Timer(stepDuration, animateStep);
      } else {
        _timer = Timer(const Duration(milliseconds: 180), () {
          if (!state.playing) return;

          emit(
            state.copyWith(
              clearSwipe: true,
              replyPreviewText: message.replyToText,
              replyPreviewSenderName: message.replyToSenderName,
            ),
          );
          _timer = Timer(const Duration(milliseconds: 350), () {
            if (!state.playing) return;
            _startOwnerTyping(message);
          });
        });
      }
    }

    _timer = Timer(const Duration(milliseconds: 300), animateStep);
  }
}
