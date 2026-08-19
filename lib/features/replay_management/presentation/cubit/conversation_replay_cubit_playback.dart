part of 'conversation_replay_cubit.dart';

mixin _PlaybackMixin on _ConversationReplayCubitBase {
  bool _replayNotificationShown = false;
  StreamSubscription? _notificationInteractionSubscription;

  void play() {
    if (state.playing || state.finished) {
      return;
    }

    _replayNotificationShown = false;

    _notificationInteractionSubscription?.cancel();

    _notificationInteractionSubscription = notificationCubit.stream.listen((_) {
      if (!state.playing) {
        return;
      }

      switch (notificationCubit.interaction) {
        case NotificationInteraction.tapped:
          _handleReplayNotificationTap();
          break;

        case NotificationInteraction.swiped:
          _handleReplayNotificationSwipe();
          break;

        case NotificationInteraction.none:
        case NotificationInteraction.expired:
          break;
      }
    });

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

    _notificationInteractionSubscription?.cancel();
    _notificationInteractionSubscription = null;

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

    final message = _messages[state.currentIndex];

    if (message.senderId == _ownerId) {
      _typeOwnerMessage(message);
    } else {
      _typeOtherPersonMessage(message);
    }
  }

  void _handleReplayNotificationTap() {
    _timer?.cancel();

    emit(
      state.copyWith(
        replayNotification: null,
        replayNotificationInteraction: ReplayNotificationInteraction.tapped,
      ),
    );

    // The actual opening of the referenced conversation
    // will be connected in the next step.
    _notificationInteractionSubscription?.cancel();
    _notificationInteractionSubscription = null;
  }

  void _handleReplayNotificationSwipe() {
    _timer?.cancel();

    emit(
      state.copyWith(
        replayNotification: null,
        replayNotificationInteraction: ReplayNotificationInteraction.swiped,
      ),
    );

    notificationCubit.hideNotification();

    _notificationInteractionSubscription?.cancel();
    _notificationInteractionSubscription = null;

    // Continue replay from the message after the notification point.
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

  void _replayNotification() {
    _replayNotificationShown = true;

    final notification = notificationCubit.state.notification;

    if (notification == null) {
      _playNext();
      return;
    }

    emit(
      state.copyWith(
        replayNotification: notification,
        replayNotificationInteraction: ReplayNotificationInteraction.none,
      ),
    );

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
