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

  void handleReplayNotificationBack() {
    final originalProjectId =
        _messages.isNotEmpty ? _messages.first.projectId : null;

    if (originalProjectId == null) {
      return;
    }

    final returnIndex = _replayNotificationMessageCount ?? state.currentIndex;

    final restoredMessages = _messages.take(returnIndex).toList();

    emit(
      state.copyWith(
        screen: ReplayScreen.conversation,
        currentProjectId: originalProjectId,
        visibleMessages: restoredMessages,
        currentIndex: returnIndex,
        playing: true,
        paused: false,
        finished: false,
        typing: false,
        typingPersonId: null,
        onlinePersonId: null,
        keyboardVisible: true,
        emojiKeyboardVisible: false,
        composerText: '',
        replayNotification: null,
      ),
    );

    _playNext();
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
            paused: true,
            finished: false,
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
    if (state.screen == ReplayScreen.conversation &&
        state.currentProjectId != null &&
        state.paused) {
      final originalProjectId =
          _messages.isNotEmpty ? _messages.first.projectId : null;

      if (originalProjectId != null &&
          originalProjectId != state.currentProjectId) {
        notificationCubit.clear();

        emit(
          state.copyWith(
            screen: ReplayScreen.conversation,
            currentProjectId: originalProjectId,
            visibleMessages: _messages,
            playing: true,
            paused: false,
            finished: false,
            replayNotification: null,
          ),
        );

        _playNext();
        return;
      }
    }

    showHome();
  }

  void setReplayStartTime(DateTime startTime) {
    final availableStart = state.availableStartTime;
    final availableEnd = state.availableEndTime;

    if (availableStart == null || availableEnd == null) {
      return;
    }

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
    _replayStartIndex = index + 1;

    final loadedMessages = _messages.take(index + 1).toList();

    emit(
      state.copyWith(
        replayStartMethod: ReplayStartMethod.message,
        replayStartMessageId: selectedMessage.id,
        replayStartTime: selectedMessage.createdAt,
        visibleMessages: loadedMessages,
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
