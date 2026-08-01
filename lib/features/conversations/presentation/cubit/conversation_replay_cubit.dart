import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../message_management/domain/entities/message.dart';

part 'conversation_replay_state.dart';

class ConversationReplayCubit extends Cubit<ConversationReplayState> {
  ConversationReplayCubit()
      : super(
          const ConversationReplayState(),
        );

  List<Message> _messages = [];

  Timer? _timer;

  void load(List<Message> messages) {
    _messages = messages;

    emit(
      const ConversationReplayState(
        visibleMessages: [],
      ),
    );
  }

  void play() {
    if (state.playing || state.finished) return;

    emit(
      state.copyWith(
        playing: true,
        paused: false,
      ),
    );

    _next();
  }

  void pause() {
    _timer?.cancel();

    emit(
      state.copyWith(
        playing: false,
        paused: true,
      ),
    );
  }

  void stop() {
    _timer?.cancel();

    emit(
      const ConversationReplayState(
        visibleMessages: [],
        currentIndex: 0,
        playing: false,
        paused: false,
        finished: false,
        typing: false,
      ),
    );
  }

  void _next() {
    if (!state.playing) return;

    final nextIndex = state.currentIndex;

    if (nextIndex >= _messages.length) {
      emit(
        state.copyWith(
          playing: false,
          finished: true,
          typing: false,
          onlinePersonId: null,
        ),
      );
      return;
    }

    final message = _messages[nextIndex];

    emit(
      state.copyWith(
        onlinePersonId: message.senderId,
        typing: true,
        typingPersonId: message.senderId,
      ),
    );

    final delay = _typingDelay(message.text);

    _timer = Timer(delay, () {
      final updated = List<Message>.from(state.visibleMessages)..add(message);

      emit(
        state.copyWith(
          typing: false,
          typingPersonId: null,
          visibleMessages: updated,
          currentIndex: nextIndex + 1,
        ),
      );

      _timer = Timer(
        const Duration(milliseconds: 700),
        _next,
      );
    });
  }

  Duration _typingDelay(String text) {
    if (text.length < 25) {
      return const Duration(seconds: 2);
    }

    if (text.length < 80) {
      return const Duration(seconds: 3);
    }

    return const Duration(seconds: 5);
  }
}
