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

    // -------------------------------------------------------------------------
    // RESUME DELETION TIMING
    // -------------------------------------------------------------------------
    //
    // If a message was already being timed for deletion before the user
    // left the conversation, resume that timer now.
    //
    // The time spent away from the conversation is therefore ignored.
    //

    _resumeActiveDeletion();
  }

  void goBackToHome() {
    showHome();
  }
}
