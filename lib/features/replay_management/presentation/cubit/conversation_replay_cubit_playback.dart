part of 'conversation_replay_cubit.dart';

mixin _PlaybackMixin on _ConversationReplayCubitBase, _NavigationMixin {
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

    _playNext();
  }

  void pause() {
    _timer?.cancel();

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

    // ------------------------------------------------------------
    // REPLAY NOTIFICATION EVENT
    // ------------------------------------------------------------

    if (_replayNotificationMessageCount != null &&
        state.currentIndex == _replayNotificationMessageCount) {
      _replayNotification();
      return;
    }

    // ------------------------------------------------------------
    // REPLAY FINISHED
    // ------------------------------------------------------------

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

    if (message.senderId == _ownerId) {
      _typeOwnerMessage(message);
    } else {
      _typeOtherPersonMessage(message);
    }
  }

  // ============================================================
  // RECORDED TAP
  // ============================================================

  Future<void> _handleReplayNotificationTap() async {
    _timer?.cancel();

    final notification = notificationCubit.currentNotification;

    if (notification == null) {
      return;
    }

    final projectId = notification.projectId;

    emit(
      state.copyWith(
        replayNotification: null,
        replayNotificationInteraction: ReplayNotificationInteraction.tapped,
        playing: false,
        paused: false,
      ),
    );

    await openConversationFromNotification(
      projectId: projectId,
    );
  }

  // ============================================================
  // RECORDED SWIPE
  // ============================================================

  void _handleReplayNotificationSwipe() {
    _timer?.cancel();

    emit(
      state.copyWith(
        replayNotification: null,
        replayNotificationInteraction: ReplayNotificationInteraction.swiped,
      ),
    );

    // The notification was already swiped in the normal
    // conversation. Replay only reproduces that visual result.
    notificationCubit.hideNotificationPreserveInteraction();

    // Continue replay after the notification point.
    emit(
      state.copyWith(
        currentIndex: state.currentIndex + 1,
      ),
    );

    _timer = Timer(
      const Duration(milliseconds: 300),
      _playNext,
    );
  }

  // ============================================================
  // SHOW RECORDED NOTIFICATION
  // ============================================================

  void _replayNotification() {
    final notification = notificationCubit.currentNotification;

    if (notification == null) {
      emit(
        state.copyWith(
          currentIndex: state.currentIndex + 1,
        ),
      );

      _timer = Timer(
        const Duration(milliseconds: 300),
        _playNext,
      );

      return;
    }

    emit(
      state.copyWith(
        replayNotification: notification,
        replayNotificationInteraction: ReplayNotificationInteraction.none,
      ),
    );

    // ------------------------------------------------------------
    // IMPORTANT:
    //
    // We do NOT wait for a user to tap or swipe.
    //
    // The interaction was already recorded in the normal
    // conversation and is reproduced automatically here.
    // ------------------------------------------------------------

    switch (notificationCubit.interaction) {
      case NotificationInteraction.tapped:
        _timer = Timer(
          const Duration(seconds: 3),
          () {
            if (!state.playing) {
              return;
            }

            _handleReplayNotificationTap();
          },
        );
        break;

      case NotificationInteraction.swiped:
        _timer = Timer(
          const Duration(seconds: 3),
          () {
            if (!state.playing) {
              return;
            }

            _handleReplayNotificationSwipe();
          },
        );
        break;

      case NotificationInteraction.expired:
        _timer = Timer(
          const Duration(seconds: 5),
          () {
            if (!state.playing) {
              return;
            }

            emit(
              state.copyWith(
                replayNotification: null,
                replayNotificationInteraction:
                    ReplayNotificationInteraction.expired,
                currentIndex: state.currentIndex + 1,
              ),
            );

            _playNext();
          },
        );
        break;

      case NotificationInteraction.none:
        // No recorded interaction.
        // Treat it like a normal notification that remains
        // visible until it expires.
        _timer = Timer(
          const Duration(seconds: 5),
          () {
            if (!state.playing) {
              return;
            }

            emit(
              state.copyWith(
                replayNotification: null,
                replayNotificationInteraction:
                    ReplayNotificationInteraction.expired,
                currentIndex: state.currentIndex + 1,
              ),
            );

            _playNext();
          },
        );
        break;
    }
  }

  // ============================================================
  // OTHER PERSON MESSAGE
  // ============================================================

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
