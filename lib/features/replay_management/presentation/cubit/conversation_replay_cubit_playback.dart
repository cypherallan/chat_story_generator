part of 'conversation_replay_cubit.dart';

mixin _PlaybackMixin on _ConversationReplayCubitBase, _NavigationMixin {
  void play() {
    if (state.playing) {
      return;
    }

    if (state.finished) {
      _timer?.cancel();

      _nextNotificationEventIndex = 0;

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

      final replayStartIndex = _replayStartIndex.clamp(
        0,
        _messages.length,
      );

      final initialVisibleMessages = _messages.take(replayStartIndex).toList();

      emit(
        state.copyWith(
          visibleMessages: initialVisibleMessages,
          currentIndex: replayStartIndex,
          playing: true,
          paused: false,
          finished: false,
          typing: false,
          typingPersonId: null,
          onlinePersonId: null,
          keyboardVisible: true,
          emojiKeyboardVisible: false,
          composerText: '',
          pressedKey: null,
          pressedEmoji: null,
          lastPressedEmoji: null,
          shiftPressed: false,
          clearReplayNotification: true,
        ),
      );

      _playNext();
      return;
    }

    _nextNotificationEventIndex = 0;

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

    if (_nextNotificationEventIndex < _replayNotificationEvents.length) {
      final nextEvent = _replayNotificationEvents[_nextNotificationEventIndex];

      if (state.currentProjectId != null) {
        String sourceProjectId;
        try {
          sourceProjectId = notificationCubit.recordedEvents
              .firstWhere((e) =>
                  e.notification.messageId == nextEvent.notification.messageId)
              .sourceProjectId;
        } catch (_) {
          sourceProjectId = state.currentProjectId!;
        }

        if (sourceProjectId == state.currentProjectId) {
          final playedOfSource = _messages
              .take(state.currentIndex)
              .where((m) => m.projectId == sourceProjectId)
              .length;

          if (playedOfSource == nextEvent.triggerIndex) {
            _replayNotificationEvent(nextEvent);
            return;
          }
        }
      }
    }

    if (state.currentIndex >= _messages.length) {
      if (state.currentIndex >= _messages.length) {
        if (_returnMessages.isNotEmpty && _returnProjectId != null) {
          returnFromNotificationConversation();
          return;
        }

        emit(
          state.copyWith(
            playing: false,
            finished: true,
            typing: false,
            keyboardVisible: true,
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
      return;
    }

    final messageIndex = state.currentIndex;
    final message = _messages[messageIndex];

    if (state.currentProjectId != null &&
        message.projectId != state.currentProjectId) {
      _timer?.cancel();
      emit(state.copyWith(
        visualInteraction: ReplayVisualInteraction.backTap,
        playing: false,
        paused: true,
      ));
      final prev = _messages[messageIndex - 1];
      final realGap = message.createdAt.difference(prev.createdAt);
      final gap = _compressRealGap(realGap);
      final filteredVisible = _visiblePerProject[message.projectId] ??
          _messages
              .take(messageIndex)
              .where((m) => m.projectId == message.projectId)
              .toList();

      _timer = Timer(const Duration(milliseconds: 380), () {
        if (isClosed) return;
        emit(state.copyWith(
          visualInteraction: ReplayVisualInteraction.none,
          screen: ReplayScreen.home,
          highlightedChatProjectId: message.projectId,
          currentProjectId: null,
          visibleMessages: const [],
        ));
        _timer = Timer(const Duration(milliseconds: 350), () {
          if (isClosed) return;
          emit(state.copyWith(
              visualInteraction: ReplayVisualInteraction.chatTap));
          _timer = Timer(const Duration(milliseconds: 380), () {
            if (isClosed) return;
            emit(state.copyWith(
              screen: ReplayScreen.conversation,
              currentProjectId: message.projectId,
              visualInteraction: ReplayVisualInteraction.none,
              clearHighlightedChat: true,
              visibleMessages: filteredVisible,
              typing: false,
              typingPersonId: null,
            ));
            _timer = Timer(gap, () {
              if (isClosed) return;
              emit(state.copyWith(playing: true, paused: false));
              if (message.senderId == _ownerId) {
                _typeOwnerMessage(message);
              } else {
                _typeOtherPersonMessage(message);
              }
            });
          });
        });
      });
      return;
    }

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

  Future<void> _handleReplayNotificationTap(
      ReplayNotificationEvent event) async {
    _timer?.cancel();

    emit(
      state.copyWith(
        visualInteraction: ReplayVisualInteraction.notificationTap,
        replayNotificationInteraction: ReplayNotificationInteraction.tapped,
        playing: false,
        paused: true,
        finished: false,
      ),
    );

    await Future.delayed(const Duration(milliseconds: 350));

    if (isClosed) return;

    notificationCubit.hideNotificationPreserveInteraction();

    await openConversationFromNotification(
      projectId: event.notification.projectId,
      notificationMessageId: event.notification.messageId,
    );
  }

  void _handleReplayNotificationSwipe() {
    _timer?.cancel();

    emit(
      state.copyWith(
        visualInteraction: ReplayVisualInteraction.notificationSwipe,
        replayNotificationInteraction: ReplayNotificationInteraction.swiped,
      ),
    );

    _timer = Timer(
      const Duration(milliseconds: 450),
      () {
        if (isClosed) {
          return;
        }

        notificationCubit.hideNotificationPreserveInteraction();

        emit(
          state.copyWith(
            replayNotification: null,
            visualInteraction: ReplayVisualInteraction.none,
          ),
        );

        _timer = Timer(
          const Duration(milliseconds: 300),
          _playNext,
        );
      },
    );
  }

  void _replayNotificationEvent(ReplayNotificationEvent event) {
    _nextNotificationEventIndex++;

    emit(
      state.copyWith(
        replayNotification: event.notification,
        replayNotificationInteraction: ReplayNotificationInteraction.none,
      ),
    );

    switch (event.interaction) {
      case NotificationInteraction.tapped:
        _timer = Timer(const Duration(seconds: 3), () {
          if (!state.playing) return;
          _handleReplayNotificationTap(event);
        });
        break;

      case NotificationInteraction.swiped:
        _timer = Timer(const Duration(seconds: 3), () {
          if (!state.playing) return;
          _handleReplayNotificationSwipe();
        });
        break;

      case NotificationInteraction.expired:
      case NotificationInteraction.none:
        _timer = Timer(const Duration(seconds: 3), () {
          if (!state.playing) return;

          emit(
            state.copyWith(
              replayNotification: null,
              replayNotificationInteraction:
                  ReplayNotificationInteraction.expired,
            ),
          );

          _timer = Timer(const Duration(milliseconds: 300), _playNext);
        });
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
        keyboardVisible: true,
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

        _visiblePerProject[message.projectId] =
            List<Message>.from(updatedMessages);

        emit(
          state.copyWith(
            typing: false,
            typingPersonId: null,
            visibleMessages: updatedMessages,
            currentIndex: state.currentIndex + 1,
            keyboardVisible: true,
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
