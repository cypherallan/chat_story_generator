import 'dart:async';
import 'dart:math';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';
import 'package:characters/characters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../message_management/domain/entities/message.dart';
import 'conversation_replay_state.dart';
import '../../../notification_management/domain/usecases/get_notifications.dart';
import '../../../notification_management/domain/usecases/get_recorded_notification_events.dart';
import '../../../notification_management/domain/usecases/save_recorded_notification_events.dart';
import '../../../message_management/domain/usecases/get_messages.dart';
import '../../../group_management/domain/usecases/get_projects.dart';
import '../../data/services/replay_export_service.dart';
import 'package:flutter/foundation.dart';
part 'conversation_replay_cubit_navigation.dart';
part 'conversation_replay_cubit_load.dart';
part 'conversation_replay_cubit_playback.dart';
part 'conversation_replay_cubit_owner_typing.dart';
part 'conversation_replay_cubit_swipe_reply.dart';
part 'conversation_replay_cubit_deletion.dart';
part 'conversation_replay_cubit_timing.dart';
part 'conversation_replay_cubit_utils.dart';
part 'conversation_replay_cubit_recording.dart';

abstract class _ConversationReplayCubitBase
    extends Cubit<ConversationReplayState> {
  _ConversationReplayCubitBase({
    required this.notificationCubit,
    required this.getMessages,
    required this.getProjects,
    required this.getNotifications,
    required this.getRecordedNotificationEvents,
    required this.saveRecordedNotificationEvents,
    required this.exportService,
  }) : super(const ConversationReplayState());

  final SimulatedNotificationCubit notificationCubit;
  final GetMessages getMessages;
  final GetProjects getProjects;
  final GetNotifications getNotifications;
  final GetRecordedNotificationEvents getRecordedNotificationEvents;
  final SaveRecordedNotificationEvents saveRecordedNotificationEvents;
  final ReplayExportService exportService;
  List<Person> _persons = [];
  void setPersons(List<Person> persons) {
    _persons = List<Person>.from(persons);
  }

  final List<Message> _messages = [];
  final List<Message> _returnMessages = [];
  final Map<String, List<Message>> _visiblePerProject = {};
  String? _returnProjectId;
  int _returnMessageIndex = 0;
  int _replayStartIndex = 0;
  final Random _random = Random();
  int? _replayNotificationMessageCount;
  List<ReplayNotificationEvent> _replayNotificationEvents = [];
  Map<String, List<Message>> get replayVisiblePerProject =>
      Map.unmodifiable(_visiblePerProject);
  List<Message> _deletionEvents = [];
  int _nextDeletionIndex = 0;
  DateTime? _lastPlayedTime;
  int _nextNotificationEventIndex = 0;
  String _ownerId = '';
  String get ownerId => _ownerId;
  Timer? _timer;
  Timer? _deletionTimer;
  final Map<String, Duration> _deletionElapsed = {};
  DateTime? _deletionStartedAt;
  String? _activeDeletionMessageId;
  void _startVisualDeletion(Message originalMessage);
  void _playNext();
  void _pauseDeletionTimer() {
    _deletionTimer?.cancel();
    _deletionTimer = null;
    if (_activeDeletionMessageId != null && _deletionStartedAt != null) {
      final elapsed = DateTime.now().difference(_deletionStartedAt!);
      _deletionElapsed[_activeDeletionMessageId!] =
          (_deletionElapsed[_activeDeletionMessageId!] ?? Duration.zero) +
              elapsed;
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
  void _resumeActiveDeletion();
  Duration _compressRealGap(Duration real);
  Duration _humanCharacterDelay(
      {required String character, required String? nextCharacter});
  Duration _humanTypingDuration(String text);
  bool _isEmoji(String character);
  void onRecordingCompleted(String tempPath);
  void onRecordingFailed(String error);
  void setSelectedQuality(ReplayExportQuality quality);
  Future<void> startRecordReplay();
  Future<void> exportRecordedVideo();
  void resetRecording();
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
        _UtilsMixin,
        _RecordingMixin {
  ConversationReplayCubit(
      {required super.notificationCubit,
      required super.getMessages,
      required super.getProjects,
      required super.getNotifications,
      required super.getRecordedNotificationEvents,
      required super.saveRecordedNotificationEvents,
      required super.exportService});
  @override
  Future<void> close() {
    _timer?.cancel();
    _disposeDeletionTimer();
    return super.close();
  }
}
