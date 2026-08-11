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

  // ===========================================================================
  // SHARED REPLAY DATA
  // ===========================================================================

  final List<Message> _messages = [];
  final Random _random = Random();

  String _ownerId = '';

  String get ownerId => _ownerId;

  // ===========================================================================
  // PLAYBACK TIMER
  // ===========================================================================

  Timer? _timer;

  // ===========================================================================
  // DELETION TIMING
  //
  // IMPORTANT:
  // Deletion timing is completely separate from the normal playback timer.
  // This allows deletion countdowns to pause when the user leaves the chat.
  // ===========================================================================

  Timer? _deletionTimer;

  /// Active conversation time accumulated for each message.
  ///
  /// Example:
  ///
  /// Message sent at 00:00:00
  /// User leaves at 00:05:00
  ///
  /// Accumulated deletion time = 5 minutes.
  ///
  /// User returns at 06:00:00:
  /// The 55 minutes away from the chat are NOT counted.
  final Map<String, Duration> _deletionElapsed = {};

  /// When the currently active deletion timer started/resumed.
  DateTime? _deletionStartedAt;

  /// The message currently being timed for deletion.
  String? _activeDeletionMessageId;

  // ===========================================================================
  // PLAYBACK
  // ===========================================================================

  void _playNext();

  // ===========================================================================
  // DELETION TIMER HELPERS
  // ===========================================================================

  /// Pauses the deletion timer and stores the amount of active chat time
  /// that has elapsed so far.
  void _pauseDeletionTimer() {
    _deletionTimer?.cancel();
    _deletionTimer = null;

    if (_activeDeletionMessageId != null && _deletionStartedAt != null) {
      final elapsed = DateTime.now().difference(_deletionStartedAt!);

      final id = _activeDeletionMessageId!;

      _deletionElapsed[id] = (_deletionElapsed[id] ?? Duration.zero) + elapsed;
    }

    _deletionStartedAt = null;
  }

  /// Completely clears the deletion timer.
  ///
  /// Used when leaving the replay conversation or when the cubit is closed.
  void _disposeDeletionTimer() {
    _deletionTimer?.cancel();
    _deletionTimer = null;

    _deletionStartedAt = null;
    _activeDeletionMessageId = null;
  }

  // ===========================================================================
  // OWNER TYPING
  // ===========================================================================

  void _typeOwnerMessage(Message message);

  void _startOwnerTyping(Message message);

  // ===========================================================================
  // SWIPE + REPLY
  // ===========================================================================

  void _performSwipeThenType(Message message);

  // ===========================================================================
  // DELETION
  // ===========================================================================

  void _scheduleDeletion(Message originalMessage);
  void _resumeActiveDeletion();

  Duration _humanCharacterDelay({
    required String character,
    required String? nextCharacter,
  });

  Duration _humanTypingDuration(String text);

  // ===========================================================================
  // UTILS
  // ===========================================================================

  bool _isEmoji(String character);
}

// =============================================================================
// PUBLIC CUBIT
// =============================================================================

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
    _disposeDeletionTimer();
    return super.close();
  }
}
