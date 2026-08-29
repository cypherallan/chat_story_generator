import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
import '../../../../injection_container.dart' as di;
import '../../../message_management/domain/usecases/get_messages.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../group_management/domain/entities/project.dart';
import '../../../group_management/presentation/cubit/group_cubit.dart';
import '../../../group_management/domain/usecases/get_projects.dart';
import '../../../notification_management/domain/usecases/get_recorded_notification_events.dart';
import '../../../notification_management/domain/usecases/save_recorded_notification_events.dart';
import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import '../widgets/replay_conversation_view.dart';
import '../widgets/replay_home_view.dart';
import '../../../notification_management/presentation/cubit/simulated_notification_cubit.dart';
import '../../../notification_management/domain/usecases/get_notifications.dart';
import '../widgets/replay_start_selection.dart';
import '../../../../core/services/sound_service.dart';
import '../../data/services/replay_export_service.dart';
import '../../../message_management/domain/entities/message.dart';
import '../widgets/replay_playback_controls.dart';

class ConversationPlaybackPage extends StatefulWidget {
  final String ownerId;
  final SimulatedNotificationCubit notificationCubit;
  const ConversationPlaybackPage(
      {super.key, required this.ownerId, required this.notificationCubit});
  @override
  State<ConversationPlaybackPage> createState() =>
      _ConversationPlaybackPageState();
}

class _ConversationPlaybackPageState extends State<ConversationPlaybackPage> {
  late final ConversationReplayCubit _replayCubit;
  late WidgetRecorderController _recorderController;
  ReplayExportQuality _currentQ = ReplayExportQuality.high;

  @override
  void initState() {
    super.initState();
    _replayCubit = ConversationReplayCubit(
      notificationCubit: widget.notificationCubit,
      getMessages: di.sl<GetMessages>(),
      getProjects: di.sl<GetProjects>(),
      getNotifications: di.sl<GetNotifications>(),
      getRecordedNotificationEvents: di.sl<GetRecordedNotificationEvents>(),
      saveRecordedNotificationEvents: di.sl<SaveRecordedNotificationEvents>(),
      exportService: di.sl<ReplayExportService>(),
      soundService: di.sl<SoundService>(),
    );
    _replayCubit.showHome();
    _createController(_currentQ);
  }

  void _createController(ReplayExportQuality q) {
    _currentQ = q;
    _recorderController = WidgetRecorderController(
      recordAudio: false,
      onComplete: (p) {
        debugPrint('[Parent] onComplete $p');
        _replayCubit.onRecordingCompleted(p);
      },
      onError: (e) {
        debugPrint('[Parent] onError $e');
        _replayCubit.onRecordingFailed(e);
      },
    );
    // ALWAYS low for this device, ignore user choice to prevent OOM
    _recorderController.applyVideoQuality(VideoQuality.low); // 15 FPS, 2 Mbps
    _recorderController.fps = 10; // even lower than your old 15 fix
    debugPrint('[Parent] forced low quality 10 FPS to avoid OOM');
  }

  @override
  void dispose() {
    if (_recorderController.isRecording) _recorderController.stop();
    _recorderController.dispose();
    _replayCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 4,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<GroupCubit>(
                create: (_) => di.sl<GroupCubit>()..loadProjects()),
            BlocProvider<PersonCubit>(
                create: (_) => di.sl<PersonCubit>()..loadPersons()),
            BlocProvider<SimulatedNotificationCubit>.value(
                value: widget.notificationCubit),
            BlocProvider<ConversationReplayCubit>.value(value: _replayCubit),
          ],
          child: BlocConsumer<ConversationReplayCubit, ConversationReplayState>(
            listenWhen: (p, c) =>
                p.selectedQuality != c.selectedQuality ||
                p.recordingStatus != c.recordingStatus ||
                p.finished != c.finished,
            listener: (ctx, state) async {
              if (state.selectedQuality != _currentQ && !state.isRecording) {
                debugPrint(
                    '[Parent] quality change ${_currentQ} -> ${state.selectedQuality}');
                _recorderController.dispose();
                _createController(state.selectedQuality);
              }
              if (state.recordingStatus == ReplayRecordingStatus.recording &&
                  !_recorderController.isRecording) {
                debugPrint('[Parent] start recording');
                await _recorderController.start();
              }
              // ONLY stop when replay truly finished (not intermediate home)
              if (state.finished && _recorderController.isRecording) {
                debugPrint('[Parent] finished=true -> stop recording');
                await _recorderController.stop();
              }
            },
            builder: (context, replayState) {
              if (replayState.isRecording) {
                PaintingBinding.instance.imageCache.clear();
                PaintingBinding.instance.imageCache.clearLiveImages();
              }
              final content = replayState.screen == ReplayScreen.conversation
                  ? _buildConversation(context, replayState)
                  : _buildHome(context, replayState);
              // WidgetRecorder wraps EVERYTHING (home + conversation) - controls outside, not recorded
              return Scaffold(
                body: Column(children: [
                  Expanded(
                      child: WidgetRecorder(
                          controller: _recorderController, child: content)),
                  ReplayPlaybackControls(
                      state: replayState,
                      replayCubit: _replayCubit,
                      recorderController: _recorderController),
                ]),
              );
            },
          ),
        ));
  }

  Widget _buildHome(BuildContext context, ConversationReplayState replayState) {
    final personState = context.watch<PersonCubit>().state;
    final projectState = context.watch<GroupCubit>().state;
    if (personState is! PersonLoaded || projectState is! ProjectLoaded)
      return const Center(child: CircularProgressIndicator());
    return ReplayHomeView(
      projects: projectState.projects,
      ownerId: widget.ownerId,
      highlightedProjectId: replayState.highlightedChatProjectId,
      isChatTapPressed:
          replayState.visualInteraction == ReplayVisualInteraction.chatTap,
      onChatTap: (project) => _openReplayConversation(context, project),
    );
  }

  Widget _buildConversation(
      BuildContext context, ConversationReplayState replayState) {
    final projectId = replayState.currentProjectId;
    if (projectId == null)
      return const Center(child: Text('Conversation not selected.'));
    final projectState = context.watch<GroupCubit>().state;
    final personState = context.watch<PersonCubit>().state;
    if (projectState is! ProjectLoaded || personState is! PersonLoaded)
      return const Center(child: CircularProgressIndicator());
    Project? project;
    for (final item in projectState.projects) {
      if (item.id == projectId) {
        project = item;
        break;
      }
    }
    if (project == null) return const Center(child: Text('Project not found.'));
    return ReplayConversationView(
      project: project, persons: personState.persons, replayCubit: _replayCubit,
      state: replayState,
      recorderController: _recorderController, // pass parent controller
      onBack: () {
        context.read<SimulatedNotificationCubit>().clear();
        _replayCubit.showHome();
      },
    );
  }

  Future<void> _openReplayConversation(
      BuildContext context, Project project) async {
    final personState = context.read<PersonCubit>().state;
    if (personState is! PersonLoaded) return;
    final projectsResult = await di.sl<GetProjects>()();
    if (!mounted) return;
    projectsResult.fold(
        (f) => ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(f.message))),
        (allProjects) async {
      final List<Message> allMessages = [];
      for (final p in allProjects.where((p) => p.ownerId == widget.ownerId)) {
        final res = await di.sl<GetMessages>()(p.id).first;
        res.fold((_) {}, (msgs) => allMessages.addAll(msgs));
      }
      allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      final clickedMessages =
          allMessages.where((m) => m.projectId == project.id).toList();
      if (clickedMessages.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('This conversation has no messages to replay.')));
        return;
      }
      _replayCubit.load(
          allMessages, widget.ownerId, personState.persons, project.id);
      final selection =
          await showReplayStartSelection(context, allMessages, project.id);
      if (!mounted || selection == null) return;
      if (selection.choice == ReplayStartChoice.time) {
        final t = selection.startTime;
        if (t != null) _replayCubit.setReplayStartTime(t);
      } else {
        final mid = selection.messageId;
        if (mid != null) _replayCubit.setReplayStartMessage(mid);
      }
      _replayCubit.openConversationViaHome(project.id);
    });
  }
}
