import 'dart:async';
import 'dart:math';

import 'package:characters/characters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../message_management/domain/entities/message.dart';
import 'conversation_replay_state.dart';

part 'conversation_replay_cubit_navigation.dart';
part 'conversation_replay_cubit_load.dart';
part 'conversation_replay_cubit_playback.dart';
part 'conversation_replay_cubit_owner_typing.dart';
part 'conversation_replay_cubit_swipe_reply.dart';
part 'conversation_replay_cubit_deletion.dart';
part 'conversation_replay_cubit_timing.dart';
part 'conversation_replay_cubit_utils.dart';

abstract class _ConversationReplayCubitBase
    extends Cubit<ConversationReplayState> {
  _ConversationReplayCubitBase() : super(const ConversationReplayState());

  final List<Message> _messages = [];
  final Random _random = Random();

  Timer? _timer;

  String _ownerId = '';

  String get ownerId => _ownerId;

  void _playNext();

  void _typeOwnerMessage(Message message);
  void _startOwnerTyping(Message message);

  void _performSwipeThenType(Message message);

  void _scheduleDeletion(Message originalMessage);
  Duration _humanCharacterDelay({
    required String character,
    required String? nextCharacter,
  });
  Duration _humanTypingDuration(String text);

  bool _isEmoji(String character);
}
class ConversationReplayCubit extends _ConversationReplayCubitBase
    with
        _NavigationMixin,
        _LoadMixin,
        _PlaybackMixin,
        _OwnerTypingMixin,
        _SwipeReplyMixin,
        _DeletionMixin,
        _TimingMixin,
        _UtilsMixin {
  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
