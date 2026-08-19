part of 'conversation_replay_cubit.dart';

mixin _NavigationMixin on _ConversationReplayCubitBase {
  void showHome() {
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

  Future<void> openConversationFromNotification({
    required String projectId,
  }) async {
    _pauseDeletionTimer();

    _timer?.cancel();
    notificationCubit.clear();
    final result = await getMessages(projectId).first;

    result.fold(
      (failure) {
        emit(
          state.copyWith(
            screen: ReplayScreen.conversation,
            currentProjectId: projectId,
            visibleMessages: const [],
            currentIndex: 0,
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
      },
      (messages) {
        final visibleMessages = List<Message>.from(messages);

        emit(
          state.copyWith(
            screen: ReplayScreen.conversation,
            currentProjectId: projectId,
            clearReplayNotification: true,
            visibleMessages: visibleMessages,
            currentIndex: visibleMessages.length,
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
      },
    );

    _resumeActiveDeletion();
  }

  void goBackToHome() {
    showHome();
  }

  // ============================================================
  // REPLAY START TIME
  // ============================================================

  void setReplayStartTime(DateTime startTime) {
    final availableStart = state.availableStartTime;
    final availableEnd = state.availableEndTime;

    if (availableStart == null || availableEnd == null) {
      return;
    }

    // Keep the selected time inside the conversation's range.
    var selectedTime = startTime;

    if (selectedTime.isBefore(availableStart)) {
      selectedTime = availableStart;
    }

    if (selectedTime.isAfter(availableEnd)) {
      selectedTime = availableEnd;
    }

    final previousMessages = _messages
        .where(
          (message) => message.createdAt.isBefore(selectedTime),
        )
        .toList();

    // ------------------------------------------------------------
    // FIND THE FIRST MESSAGE THAT SHOULD ACTUALLY BE REPLAYED
    // ------------------------------------------------------------

    var firstReplayIndex = _messages.indexWhere(
      (message) => !message.createdAt.isBefore(selectedTime),
    );

    if (firstReplayIndex == -1) {
      firstReplayIndex = _messages.length;
    }

    emit(
      state.copyWith(
        replayStartMethod: ReplayStartMethod.time,
        replayStartMessageId: null,
        replayStartTime: selectedTime,
        visibleMessages: previousMessages,
        currentIndex: firstReplayIndex,
        playing: false,
        paused: false,
        finished: false,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
      ),
    );
  }

  void setReplayStartMessage(String messageId) {
    final index = _messages.indexWhere(
      (message) => message.id == messageId,
    );

    if (index == -1) {
      return;
    }

    final selectedMessage = _messages[index];

    // The selected message is the last message already visible.
    // Replay begins with the message immediately after it.
    _replayStartIndex = index + 1;

    final loadedMessages = _messages.take(index + 1).toList();

    emit(
      state.copyWith(
        replayStartMethod: ReplayStartMethod.message,
        replayStartMessageId: selectedMessage.id,
        replayStartTime: selectedMessage.createdAt,

        // Show all history through the selected message.
        visibleMessages: loadedMessages,

        // First message to be replayed.
        currentIndex: _replayStartIndex,

        playing: false,
        paused: false,
        finished: false,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
      ),
    );
  }
}
