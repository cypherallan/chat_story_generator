part of 'conversation_replay_cubit.dart';

mixin _PlaybackMixin on _ConversationReplayCubitBase {
  bool _replayNotificationShown = false;
  void play() {
    if (state.playing || state.finished) {
      return;
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

  @override
  void _playNext() {
    if (!state.playing) {
      return;
    }
    print(
      'REPLAY DEBUG: currentIndex=${state.currentIndex}, '
      'notificationIndex=$_replayNotificationMessageCount, '
      'messages=${_messages.length}',
    );

    // ------------------------------------------------------------
    // REPLAY NOTIFICATION EVENT
    // ------------------------------------------------------------

    if (_replayNotificationMessageCount != null &&
        state.currentIndex == _replayNotificationMessageCount &&
        !_replayNotificationShown) {
      print('REPLAY DEBUG: *** NOTIFICATION TRIGGER REACHED ***');
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

    final message = _messages[state.currentIndex];

    if (message.senderId == _ownerId) {
      _typeOwnerMessage(message);
    } else {
      _typeOtherPersonMessage(message);
    }
  }

  void _replayNotification() {
    print('REPLAY DEBUG: _replayNotification() CALLED');

    _replayNotificationShown = true;

    final notification = notificationCubit.state.notification;

    print(
      'REPLAY DEBUG: notification from SimulatedNotificationCubit = '
      '${notification == null ? 'NULL' : notification.messageText}',
    );

    if (notification == null) {
      print(
        'REPLAY DEBUG: NO SIMULATED NOTIFICATION AVAILABLE — '
        'skipping banner',
      );

      _playNext();
      return;
    }

    print(
      'REPLAY DEBUG: EMITTING replayNotification = '
      '${notification.messageText}',
    );

    emit(
      state.copyWith(
        replayNotification: notification,
        replayNotificationInteraction: ReplayNotificationInteraction.none,
      ),
    );

    print(
      'REPLAY DEBUG: state.replayNotification after emit = '
      '${state.replayNotification?.messageText}',
    );

    _timer = Timer(
      const Duration(seconds: 5),
      () {
        if (!state.playing) {
          return;
        }

        print(
          'REPLAY DEBUG: notification display finished',
        );

        emit(
          state.copyWith(
            replayNotification: null,
            replayNotificationInteraction:
                ReplayNotificationInteraction.expired,
            currentIndex: state.currentIndex,
          ),
        );

        notificationCubit.recordExpired();

        _playNext();
      },
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
