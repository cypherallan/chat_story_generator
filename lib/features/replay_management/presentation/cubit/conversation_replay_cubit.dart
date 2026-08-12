import 'dart:async';
import 'dart:math';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';
import 'package:characters/characters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../message_management/domain/entities/message.dart';
import 'conversation_replay_state.dart';

import '../../../message_management/domain/usecases/get_messages.dart';
import '../../../project_management/domain/usecases/get_projects.dart';

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
  _ConversationReplayCubitBase({
    required this.notificationCubit,
    required this.getMessages,
    required this.getProjects,
  }) : super(const ConversationReplayState());

  final SimulatedNotificationCubit notificationCubit;
  final GetMessages getMessages;
  final GetProjects getProjects;
  List<Person> _persons = [];
  void setPersons(List<Person> persons) {
    _persons = List<Person>.from(persons);
  }

  // ===========================================================================
  // SHARED REPLAY DATA
  // ===========================================================================

  final List<Message> _messages = [];
  final Map<String, List<Message>> _backgroundMessages = {};

  final Random _random = Random();

  String _ownerId = '';

  String get ownerId => _ownerId;
  Timer? _timer;
  Timer? _backgroundTimer;

  final List<Message> _backgroundTimeline = [];

  int _backgroundIndex = 0;

  DateTime? _backgroundReplayStartedAt;
  Timer? _deletionTimer;
  final Map<String, Duration> _deletionElapsed = {};
  DateTime? _deletionStartedAt;
  String? _activeDeletionMessageId;

  void _playNext();
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

  void _disposeDeletionTimer() {
    _deletionTimer?.cancel();
    _deletionTimer = null;

    _deletionStartedAt = null;
    _activeDeletionMessageId = null;
  }

  void _prepareBackgroundTimeline(String foregroundProjectId) {
    _backgroundTimeline
      ..clear()
      ..addAll(
        _backgroundMessages.values.expand((messages) => messages).where(
              (message) => message.projectId != foregroundProjectId,
            ),
      );

    _backgroundTimeline.sort(
      (a, b) => a.createdAt.compareTo(b.createdAt),
    );

    _backgroundIndex = 0;
  }

  void _startBackgroundReplay(String foregroundProjectId) {
    _backgroundTimer?.cancel();

    _prepareBackgroundTimeline(foregroundProjectId);

    if (_backgroundTimeline.isEmpty) {
      return;
    }

    _backgroundReplayStartedAt = DateTime.now();

    _backgroundTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) {
        if (state.screen != ReplayScreen.conversation ||
            !state.playing ||
            _backgroundReplayStartedAt == null) {
          return;
        }

        if (_backgroundIndex >= _backgroundTimeline.length) {
          _backgroundTimer?.cancel();
          _backgroundTimer = null;
          return;
        }

        final elapsed = DateTime.now().difference(_backgroundReplayStartedAt!);

        final message = _backgroundTimeline[_backgroundIndex];

        final firstMessage = _backgroundTimeline.first;

        final targetTime = message.createdAt.difference(firstMessage.createdAt);

        if (elapsed >= targetTime) {
          _backgroundIndex++;

          _handleBackgroundMessage(message);
        }
      },
    );
  }

  void _handleBackgroundMessage(Message message) {
    if (!state.playing) {
      return;
    }

    // A background message belongs to another conversation.
    // Therefore it must NEVER be added to the currently visible chat.

    notificationCubit.showNotification(
      projectId: message.projectId,
      senderId: message.senderId,
      senderName: _getSenderName(message.senderId),
      senderAvatarPath: _getSenderAvatar(message.senderId),
      messageText: message.text,
      imagePath: message.imagePath,
    );
  }

  String _getSenderName(String senderId) {
    for (final person in _persons) {
      if (person.id == senderId) {
        return person.name;
      }
    }

    return 'Unknown';
  }

  String? _getSenderAvatar(String senderId) {
    for (final person in _persons) {
      if (person.id == senderId) {
        return person.avatarPath;
      }
    }

    return null;
  }

  void _typeOwnerMessage(Message message);
  void _startOwnerTyping(Message message);
  void _performSwipeThenType(Message message);
  void _scheduleDeletion(Message originalMessage);
  void _resumeActiveDeletion();

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
  ConversationReplayCubit({
    required SimulatedNotificationCubit notificationCubit,
    required GetMessages getMessages,
    required GetProjects getProjects,
  }) : super(
          notificationCubit: notificationCubit,
          getMessages: getMessages,
          getProjects: getProjects,
        );

  @override
  Future<void> close() {
    _timer?.cancel();
    _backgroundTimer?.cancel();
    _disposeDeletionTimer();
    return super.close();
  }
}
