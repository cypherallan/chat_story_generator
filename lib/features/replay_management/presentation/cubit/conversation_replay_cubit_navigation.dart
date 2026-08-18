part of 'conversation_replay_cubit.dart';

mixin _NavigationMixin on _ConversationReplayCubitBase {
  void showHome() {
    // Leaving the conversation pauses deletion timing.
    //
    // IMPORTANT:
    // Time spent on the home screen must NOT count toward
    // the deletion delay.
    _pauseDeletionTimer();

    _timer?.cancel();

    emit(
      state.copyWith(
        screen: ReplayScreen.home,
        currentProjectId: null,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
        keyboardVisible: false,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftPressed: false,
      ),
    );
  }

  void openConversation(String projectId) {
    // If we are leaving one conversation and opening another,
    // stop counting active deletion time.
    _pauseDeletionTimer();

    _timer?.cancel();

    emit(
      state.copyWith(
        screen: ReplayScreen.conversation,
        currentProjectId: projectId,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
        keyboardVisible: false,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftPressed: false,
      ),
    );

    _resumeActiveDeletion();
  }

  void openConversationFromNotification({
    required String projectId,
    required List<Message> messages,
  }) {
    _pauseDeletionTimer();

    _timer?.cancel();

    notificationCubit.clear();

    final visibleMessages = List<Message>.from(messages);

    emit(
      state.copyWith(
        screen: ReplayScreen.conversation,
        currentProjectId: projectId,

        // Open directly at the notification point.
        // No replay animation or typing.
        visibleMessages: visibleMessages,
        currentIndex: _messages.length,
        playing: false,
        paused: false,
        finished: true,

        typing: false,
        typingPersonId: null,
        onlinePersonId: null,

        keyboardVisible: false,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftPressed: false,
      ),
    );
  }

  void goBackToHome() {
    showHome();
  }
}
