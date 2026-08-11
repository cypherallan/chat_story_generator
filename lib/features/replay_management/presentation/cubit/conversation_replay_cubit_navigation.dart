part of 'conversation_replay_cubit.dart';

mixin _NavigationMixin on _ConversationReplayCubitBase {
  void showHome() {
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
  }

  void goBackToHome() {
    showHome();
  }
}
