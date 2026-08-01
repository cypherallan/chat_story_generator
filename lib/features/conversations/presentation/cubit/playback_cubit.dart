import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../message_management/domain/entities/message.dart';

part 'playback_state.dart';

class PlaybackCubit extends Cubit<PlaybackState> {
  PlaybackCubit() : super(const PlaybackState());

  Timer? _timer;

  List<Message> _allMessages = [];

  int _currentIndex = 0;

  void loadMessages(List<Message> messages) {
    _allMessages = messages;
    _currentIndex = 0;

    emit(
      state.copyWith(
        visibleMessages: [],
        isPlaying: false,
        isTyping: false,
      ),
    );
  }

  void play() {
    if (_allMessages.isEmpty) return;

    emit(
      state.copyWith(
        isPlaying: true,
      ),
    );

    _playNext();
  }

  void pause() {
    _timer?.cancel();

    emit(
      state.copyWith(
        isPlaying: false,
      ),
    );
  }

  void stop() {
    _timer?.cancel();

    _currentIndex = 0;

    emit(
      state.copyWith(
        visibleMessages: [],
        isPlaying: false,
        isTyping: false,
      ),
    );
  }

  void _playNext() {
    if (_currentIndex >= _allMessages.length) {
      emit(
        state.copyWith(
          isPlaying: false,
          isTyping: false,
        ),
      );
      return;
    }

    final nextMessage = _allMessages[_currentIndex];

    emit(
      state.copyWith(
        isTyping: true,
      ),
    );

    final delay = Duration(
      milliseconds: 900 + (nextMessage.text.length * 35),
    );

    _timer = Timer(delay, () {
      final updated = List<Message>.from(state.visibleMessages)
        ..add(nextMessage);

      emit(
        state.copyWith(
          visibleMessages: updated,
          isTyping: false,
        ),
      );

      _currentIndex++;

      if (state.isPlaying) {
        _playNext();
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
