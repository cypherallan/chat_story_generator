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

  Future<void> openConversationFromNotification({
    required String projectId,
  }) async {
    _pauseDeletionTimer();

    _timer?.cancel();

    // The notification interaction has already been recorded.
    notificationCubit.clear();

    // Load the actual messages belonging to the target conversation.
    //
    // This is important because the notification may belong to a
    // completely different conversation from the one currently being
    // replayed.
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

            // Show the complete existing conversation.
            visibleMessages: visibleMessages,

            // Tapping a notification opens the chat normally.
            // It must NOT start/restart replay.
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

    // ------------------------------------------------------------
    // BUILD THE CONVERSATION HISTORY
    // ------------------------------------------------------------
    //
    // Messages before the selected replay time already existed in
    // the conversation. They should therefore be visible immediately
    // when replay starts, but they must NOT be replayed/typed again.
    //
    // Example:
    //
    // 17:37  -> visible immediately
    // 18:21  -> replay starts here
    // 18:22  -> streamed
    // 18:23  -> streamed
    // 18:23  -> streamed
    // 18:35  -> streamed
    //
    // _messages remains the COMPLETE conversation. We only prepare
    // visibleMessages here.
    // ------------------------------------------------------------

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
        replayStartTime: selectedTime,

        // Show the messages that existed before replay began.
        visibleMessages: previousMessages,

        // Replay starts at the first message at/after the
        // selected time.
        currentIndex: firstReplayIndex,

        // The replay has not finished simply because we changed
        // the starting point.
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
