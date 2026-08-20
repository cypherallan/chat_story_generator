import 'dart:async';
import 'dart:math';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';
import 'package:characters/characters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../message_management/domain/entities/message.dart';
import 'conversation_replay_state.dart';
import '../../../notification_management/domain/usecases/get_notifications.dart';
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
    required this.getNotifications,
  }) : super(const ConversationReplayState());

  final SimulatedNotificationCubit notificationCubit;
  final GetMessages getMessages;
  final GetProjects getProjects;
  final GetNotifications getNotifications;
  List<Person> _persons = [];
  void setPersons(List<Person> persons) {
    _persons = List<Person>.from(persons);
  }

  final List<Message> _messages = [];
  final List<Message> _returnMessages = [];
  String? _returnProjectId;
  int _returnMessageIndex = 0;
  int? _returnNotificationMessageCount;
  int _replayStartIndex = 0;

  final Random _random = Random();

  int? _replayNotificationMessageCount;

  String _ownerId = '';

  String get ownerId => _ownerId;
  Timer? _timer;
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
    required GetNotifications getNotifications,
  }) : super(
          notificationCubit: notificationCubit,
          getMessages: getMessages,
          getProjects: getProjects,
          getNotifications: getNotifications,
        );

  @override
  Future<void> close() {
    _timer?.cancel();
    _disposeDeletionTimer();
    return super.close();
  }
}
