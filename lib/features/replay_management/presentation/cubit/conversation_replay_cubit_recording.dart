part of 'conversation_replay_cubit.dart';

mixin _RecordingMixin on _ConversationReplayCubitBase, _NavigationMixin {
  final List<ReplayAudioEvent> _recordingAudioEvents = [];
  Stopwatch? _recordingAudioClock;

  void _startRecordingAudioTracking() {
    _recordingAudioEvents.clear();

    _recordingAudioClock = Stopwatch()..start();

    soundService.onSoundPlayed = (sound) {
      final clock = _recordingAudioClock;

      if (clock == null || !clock.isRunning) return;

      _recordingAudioEvents.add(
        ReplayAudioEvent(
          sound: sound,
          offset: clock.elapsed,
        ),
      );
    };
  }

  void _stopRecordingAudioTracking() {
    _recordingAudioClock?.stop();
    _recordingAudioClock = null;
    soundService.onSoundPlayed = null;
  }

  @override
  void onRecordingCompleted(String tempPath) {
    _stopRecordingAudioTracking();

    // ignore: unused_local_variable
    for (final event in _recordingAudioEvents) {}

    if (isClosed) return;
    emit(state.copyWith(
      recordingStatus: ReplayRecordingStatus.recorded,
      recordedTempPath: tempPath,
      clearRecordingError: true,
    ));
  }

  @override
  void onRecordingFailed(String error) {
    _stopRecordingAudioTracking();

    if (isClosed) return;
    emit(state.copyWith(
      recordingStatus: ReplayRecordingStatus.failed,
      recordingError: error,
    ));
  }

  @override
  void setSelectedQuality(ReplayExportQuality quality) {
    emit(state.copyWith(selectedQuality: quality));
  }

  @override
  void resetRecording() {
    emit(state.copyWith(
      recordingStatus: ReplayRecordingStatus.idle,
      clearRecordedTempPath: true,
      clearExportedPath: true,
      clearRecordingError: true,
    ));
  }

  @override
  Future<void> startRecordReplay() async {
    _timer?.cancel();
    _nextNotificationEventIndex = 0;

    if (state.replayStartMethod == ReplayStartMethod.time) {
      if (state.replayStartTime != null) {
        _replayStartIndex = _messages.indexWhere(
          (message) => !message.createdAt.isBefore(state.replayStartTime!),
        );
        if (_replayStartIndex == -1) {
          _replayStartIndex = _messages.length;
        }
      } else {
        _replayStartIndex = 0;
      }
    }

    final replayStartIndex = _replayStartIndex.clamp(0, _messages.length);
    final initialVisibleMessages = _messages.take(replayStartIndex).toList();
    _startRecordingAudioTracking();

    emit(state.copyWith(
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
      recordingStatus: ReplayRecordingStatus.recording,
      clearRecordedTempPath: true,
      clearExportedPath: true,
      clearRecordingError: true,
    ));

    _playNext();
  }

  @override
  Future<void> exportRecordedVideo({String? customFileName}) async {
    final tempPath = state.recordedTempPath;
    if (tempPath == null) return;
    emit(state.copyWith(recordingStatus: ReplayRecordingStatus.exporting));
    try {
      final exportedPath = await exportService.exportVideo(
        tempPath: tempPath,
        quality: state.selectedQuality,
        customFileName: customFileName,
        audioEvents: List<ReplayAudioEvent>.from(_recordingAudioEvents),
      );
      emit(state.copyWith(
          recordingStatus: ReplayRecordingStatus.exported,
          exportedPath: exportedPath));
    } catch (e) {
      emit(state.copyWith(
          recordingStatus: ReplayRecordingStatus.failed,
          recordingError: e.toString()));
    }
  }
}
