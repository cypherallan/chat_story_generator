part of 'conversation_replay_cubit.dart';

mixin _RecordingMixin on _ConversationReplayCubitBase, _NavigationMixin {
  void onRecordingCompleted(String tempPath) {
    if (isClosed) return;
    emit(state.copyWith(
      recordingStatus: ReplayRecordingStatus.recorded,
      recordedTempPath: tempPath,
      clearRecordingError: true,
    ));
  }

  void onRecordingFailed(String error) {
    if (isClosed) return;
    emit(state.copyWith(
      recordingStatus: ReplayRecordingStatus.failed,
      recordingError: error,
    ));
  }

  void setSelectedQuality(ReplayExportQuality quality) {
    emit(state.copyWith(selectedQuality: quality));
  }

  void resetRecording() {
    emit(state.copyWith(
      recordingStatus: ReplayRecordingStatus.idle,
      clearRecordedTempPath: true,
      clearExportedPath: true,
      clearRecordingError: true,
    ));
  }

  /// Called when user presses "Record Replay"
  /// This resets replay to beginning and sets recording status to recording.
  /// The UI (WidgetRecorderController) should start actual capture right after calling this.
  Future<void> startRecordReplay() async {
    _timer?.cancel();
    _nextNotificationEventIndex = 0;

    // Same reset logic as play() when finished
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

    // Reset recording state + restart replay
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
      // recording
      recordingStatus: ReplayRecordingStatus.recording,
      clearRecordedTempPath: true,
      clearExportedPath: true,
      clearRecordingError: true,
    ));

    _playNext();
  }

  /// Called by UI after WidgetRecorder gives temp path, to export to user storage with quality
  Future<void> exportRecordedVideo() async {
    final tempPath = state.recordedTempPath;
    if (tempPath == null) return;

    emit(state.copyWith(recordingStatus: ReplayRecordingStatus.exporting));

    try {
      final exportedPath = await exportService.exportVideo(
        tempPath: tempPath,
        quality: state.selectedQuality,
      );
      emit(state.copyWith(
        recordingStatus: ReplayRecordingStatus.exported,
        exportedPath: exportedPath,
      ));
    } catch (e) {
      emit(state.copyWith(
        recordingStatus: ReplayRecordingStatus.failed,
        recordingError: e.toString(),
      ));
    }
  }
}
