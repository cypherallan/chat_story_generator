part of 'conversation_replay_cubit.dart';

mixin _DeletionMixin on _ConversationReplayCubitBase {
  @override
  void _scheduleDeletion(Message originalMessage) {
    // Real time difference between when the message was sent and when it was deleted
    Duration delay;

    if (originalMessage.deletedAt != null) {
      final diff =
          originalMessage.deletedAt!.difference(originalMessage.createdAt);

      // Clamp so the replay stays watchable
      if (diff.inMilliseconds < 1800) {
        delay = const Duration(milliseconds: 2200);
      } else if (diff.inSeconds > 25) {
        delay = Duration(seconds: 7 + _random.nextInt(4)); // 7-10 s max
      } else {
        delay = diff;
      }
    } else {
      delay = const Duration(milliseconds: 2800);
    }

    Timer(delay, () {
      // Only run if we are still on the conversation screen
      if (state.screen != ReplayScreen.conversation) return;

      // IMPORTANT: wait until the current typing action has finished
      // (a real user cannot delete while typing)
      if (state.typing || state.composerText.isNotEmpty) {
        // Try again shortly
        Timer(const Duration(milliseconds: 800), () {
          if (state.screen != ReplayScreen.conversation) return;
          _startVisualDeletion(originalMessage);
        });
        return;
      }

      _startVisualDeletion(originalMessage);
    });
  }

  void _startVisualDeletion(Message originalMessage) {
    // 1. Long-press → select the message
    emit(
      state.copyWith(
        selectedMessageIds: {originalMessage.id},
        deleteIconPressed: false,
        keyboardVisible: false, // hide keyboard while deleting
      ),
    );

    // 2. Let the user see the selection
    Timer(const Duration(milliseconds: 900), () {
      if (state.screen != ReplayScreen.conversation) return;

      // 3. Press the delete icon
      emit(state.copyWith(deleteIconPressed: true));

      // 4. Apply the deletion
      Timer(const Duration(milliseconds: 450), () {
        if (state.screen != ReplayScreen.conversation) return;

        final currentMessages = List<Message>.from(state.visibleMessages);
        final index =
            currentMessages.indexWhere((m) => m.id == originalMessage.id);

        if (index != -1) {
          currentMessages[index] = originalMessage.copyWith(
            text: 'This message was deleted',
            isDeleted: true,
            imagePath: null,
            replyToMessageId: null,
            replyToSenderId: null,
            replyToSenderName: null,
            replyToText: null,
          );
        }

        emit(
          state.copyWith(
            visibleMessages: currentMessages,
            clearSelection: true,
            deleteIconPressed: false,
          ),
        );
      });
    });
  }
}