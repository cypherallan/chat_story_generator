part of 'conversation_replay_cubit.dart';

mixin _PlaybackMixin on _ConversationReplayCubitBase, _NavigationMixin {
  bool _replayNotificationShown = false;

  void play() {
    if (state.playing || state.finished) {
      return;
    }
    if (state.replayStartMethod == ReplayStartMethod.time) {
      if (state.replayStartTime != null) {
        _replayStartIndex = _messages.indexWhere(
          (message) => !message.createdAt.isBefore(
            state.replayStartTime!,
          ),
        );

        if (_replayStartIndex == -1) {
          _replayStartIndex = _messages.length;
        }
      } else {
        _replayStartIndex = 0;
      }
    }
    _replayNotificationShown = false;

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

  Duration _replayMessageGap(
    Message previous,
    Message current,
  ) {
    final originalGap = current.createdAt.difference(
      previous.createdAt,
    );

    if (originalGap.isNegative || originalGap == Duration.zero) {
      return Duration.zero;
    }

    final seconds = originalGap.inMilliseconds / 1000.0;

    var replaySeconds = 0.8 + (log(seconds + 1) * 1.2);

    replaySeconds = max(replaySeconds, 0.8);
    replaySeconds = min(replaySeconds, 6.0);

    return Duration(
      milliseconds: (replaySeconds * 1000).round(),
    );
  }

  @override
  void _playNext() {
    if (!state.playing) {
      return;
    }

    if (state.currentIndex < _replayStartIndex) {
      emit(
        state.copyWith(
          currentIndex: _replayStartIndex,
        ),
      );
    }

    if (_replayNotificationMessageCount != null &&
        state.currentIndex == _replayNotificationMessageCount &&
        !_replayNotificationShown) {
      _replayNotification();
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

    final messageIndex = state.currentIndex;
    final message = _messages[messageIndex];

    Duration gap;

    if (messageIndex == 0) {
      gap = Duration.zero;
    } else {
      final previousMessage = _messages[messageIndex - 1];

      gap = _replayMessageGap(
        previousMessage,
        message,
      );
    }

    _timer = Timer(
      gap,
      () {
        if (!state.playing) {
          return;
        }

        if (message.senderId == _ownerId) {
          _typeOwnerMessage(message);
        } else {
          _typeOtherPersonMessage(message);
        }
      },
    );
  }

  Future<void> _handleReplayNotificationTap() async {
    _timer?.cancel();

    final notification = notificationCubit.currentNotification;

    if (notification == null) {
      return;
    }

    emit(
      state.copyWith(
        replayNotification: null,
        replayNotificationInteraction: ReplayNotificationInteraction.tapped,
        playing: false,
        paused: true,
        finished: false,
      ),
    );

    notificationCubit.hideNotificationPreserveInteraction();

    await openConversationFromNotification(
      projectId: notification.projectId,
    );

    // Reproduce the back-arrow press that happened in the
    // original conversation automatically.
    _timer = Timer(
      const Duration(seconds: 3),
      () {
        if (isClosed) return;

        handleReplayNotificationBack();
      },
    );
  }

  void _handleReplayNotificationSwipe() {
    _timer?.cancel();

    emit(
      state.copyWith(
        replayNotification: null,
        replayNotificationInteraction: ReplayNotificationInteraction.swiped,
      ),
    );
    notificationCubit.hideNotificationPreserveInteraction();

    _timer = Timer(
      const Duration(milliseconds: 300),
      _playNext,
    );
  }

  void _replayNotification() {
    _replayNotificationShown = true;

    final notification = notificationCubit.currentNotification;

    if (notification == null) {
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
      case NotificationInteraction.none:
        _timer = Timer(
          const Duration(seconds: 3),
          () {
            if (!state.playing) {
              return;
            }

            emit(
              state.copyWith(
                replayNotification: null,
                replayNotificationInteraction:
                    ReplayNotificationInteraction.expired,
              ),
            );

            _timer = Timer(
              const Duration(milliseconds: 300),
              _playNext,
            );
          },
        );
        break;
    }
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
