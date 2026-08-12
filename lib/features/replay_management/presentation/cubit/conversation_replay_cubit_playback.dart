part of 'conversation_replay_cubit.dart';

mixin _PlaybackMixin on _ConversationReplayCubitBase {
  void play() {
    if (state.playing || state.finished) {
      return;
    }

    emit(
      state.copyWith(
        playing: true,
        paused: false,
        keyboardVisible: true,
        emojiKeyboardVisible: false,
      ),
    );

    final projectId = state.currentProjectId;

    if (projectId != null) {
      _startBackgroundReplay(projectId);
    }

    _playNext();
  }

  void pause() {
    _timer?.cancel();
    _backgroundTimer?.cancel();
    _backgroundTimer = null;

    emit(
      state.copyWith(
        playing: false,
        paused: true,
        typing: false,
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
      ),
    );
  }

  void stop() {
    _timer?.cancel();
    _backgroundTimer?.cancel();
    _backgroundTimer = null;

    _backgroundTimeline.clear();
    _backgroundIndex = 0;

    emit(
      const ConversationReplayState(
        keyboardVisible: false,
      ),
    );
  }

  @override
  void _playNext() {
    if (!state.playing) {
      return;
    }

    if (state.currentIndex >= _messages.length) {
      emit(
        state.copyWith(
          playing: false,
          finished: true,
          typing: false,
          keyboardVisible: false,
          emojiKeyboardVisible: false,
          composerText: '',
          pressedKey: null,
          pressedEmoji: null,
          lastPressedEmoji: null,
          shiftPressed: false,
        ),
      );

      return;
    }

    final message = _messages[state.currentIndex];

    // ============================================================
    // FOREGROUND CHAT
    //
    // Messages belonging to the currently open conversation are
    // replayed normally inside that conversation.
    // ============================================================

    if (message.projectId == state.currentProjectId) {
      if (message.senderId == _ownerId) {
        _typeOwnerMessage(message);
      } else {
        _typeOtherPersonMessage(message);
      }

      return;
    }

    // ============================================================
    // BACKGROUND CHAT
    //
    // A message belonging to another conversation must NOT appear
    // inside the currently open chat.
    //
    // Instead, simulate an incoming notification using the actual
    // message data.
    // ============================================================

    _showBackgroundNotification(message);
  }

  void _showBackgroundNotification(Message message) {
    if (!state.playing) {
      return;
    }

    // Never generate an incoming notification for the owner.
    if (message.senderId == _ownerId) {
      _advanceBackgroundMessage();
      return;
    }

    notificationCubit.showNotification(
      projectId: message.projectId,
      senderId: message.senderId,
      senderName: message.senderId,
      messageText: message.text,
      imagePath: message.imagePath,
    );

    _advanceBackgroundMessage();
  }

  void _advanceBackgroundMessage() {
    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
      ),
    );

    _timer = Timer(
      const Duration(milliseconds: 650),
      _playNext,
    );
  }

  void _typeOtherPersonMessage(Message message) {
    final delay = _humanTypingDuration(
      message.originalText ?? message.text,
    );

    emit(
      state.copyWith(
        typing: true,
        typingPersonId: message.senderId,
        onlinePersonId: message.senderId,
        keyboardVisible: false,
        emojiKeyboardVisible: false,
        composerText: '',
        pressedKey: null,
        pressedEmoji: null,
        lastPressedEmoji: null,
        shiftPressed: false,
      ),
    );

    _timer = Timer(
      delay,
      () {
        if (!state.playing) {
          return;
        }

        final messageToShow = message.isDeleted
            ? message.copyWith(
                text: message.originalText ?? message.text,
                isDeleted: false,
              )
            : message;

        final updatedMessages = List<Message>.from(
          state.visibleMessages,
        )..add(messageToShow);

        emit(
          state.copyWith(
            typing: false,
            typingPersonId: null,
            visibleMessages: updatedMessages,
            currentIndex: state.currentIndex + 1,
          ),
        );

        if (message.isDeleted) {
          _scheduleDeletion(message);
        }

        _timer = Timer(
          const Duration(milliseconds: 650),
          _playNext,
        );
      },
    );
  }
}
