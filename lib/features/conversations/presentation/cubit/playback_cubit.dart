import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../message_management/domain/entities/playback_state.dart';

class PlaybackCubit extends Cubit<PlaybackState> {
  PlaybackCubit() : super(PlaybackState.stopped);

  void play() {
    emit(PlaybackState.playing);
  }

  void pause() {
    emit(PlaybackState.paused);
  }

  void stop() {
    emit(PlaybackState.stopped);
  }

  bool get isPlaying => state == PlaybackState.playing;

  bool get isPaused => state == PlaybackState.paused;

  bool get isStopped => state == PlaybackState.stopped;
}
