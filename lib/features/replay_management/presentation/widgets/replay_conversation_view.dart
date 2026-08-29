import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../group_management/domain/entities/project.dart';
import '../../../message_management/domain/entities/message.dart';
import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import '../../../message_management/presentation/widgets/typing_indicator.dart';
import 'playback_chat_list.dart' as playback_chat_list;
import 'playback_header.dart' as playback_header;
import 'playback_bottom_panel.dart';
import 'replay_playback_controls.dart';
import '../widgets/replay_notification_banner.dart';

class ReplayConversationView extends StatefulWidget {
  final Project project;
  final List<Person> persons;
  final ConversationReplayCubit replayCubit;
  final ConversationReplayState state;
  final VoidCallback onBack;
  const ReplayConversationView(
      {super.key,
      required this.project,
      required this.persons,
      required this.replayCubit,
      required this.state,
      required this.onBack});
  @override
  State<ReplayConversationView> createState() => _ReplayConversationViewState();
}

class _ReplayConversationViewState extends State<ReplayConversationView> {
  final ScrollController _scrollController = ScrollController();
  late WidgetRecorderController _recorderController;
  ReplayExportQuality _currentQ = ReplayExportQuality.high;

  @override
  void initState() {
    super.initState();
    _currentQ = widget.state.selectedQuality;
    _create(_currentQ);
  }

  void _create(ReplayExportQuality q) {
    _currentQ = q;
    debugPrint('[View] _create quality=$q');
    _recorderController = WidgetRecorderController(
      recordAudio: false,
      onComplete: (path) {
        debugPrint(
            '[View] onComplete path=$path -> calling onRecordingCompleted');
        widget.replayCubit.onRecordingCompleted(path);
      },
      onError: (error) {
        debugPrint('[View] onError $error');
        widget.replayCubit.onRecordingFailed(error);
      },
    );
    // SAFE MAPPING - avoid 60FPS crash on your device
    switch (q) {
      case ReplayExportQuality.low:
        _recorderController.applyVideoQuality(
            VideoQuality.low); // 15 FPS 2 Mbps - your old safe fix
        break;
      case ReplayExportQuality.medium:
        _recorderController
            .applyVideoQuality(VideoQuality.medium); // 30 FPS 5 Mbps
        break;
      case ReplayExportQuality.high:
        _recorderController.applyVideoQuality(
            VideoQuality.medium); // use medium for 1080p to avoid crash
        break;
      case ReplayExportQuality.ultra:
        _recorderController
            .applyVideoQuality(VideoQuality.high); // only 4K uses 60 FPS
        break;
    }
  }

  @override
  void dispose() {
    if (_recorderController.isRecording) _recorderController.stop();
    _scrollController.dispose();
    _recorderController.dispose();
    super.dispose();
  }

  void _onSwipeReply(Message m) {}
  void _onReplyTap(String id) {}

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationReplayCubit, ConversationReplayState>(
      listenWhen: (p, c) =>
          p.showDeleteConfirmation != c.showDeleteConfirmation ||
          p.finished != c.finished ||
          p.recordingStatus != c.recordingStatus ||
          p.selectedQuality != c.selectedQuality,
      listener: (context, state) async {
        if (state.selectedQuality != _currentQ && !state.isRecording) {
          debugPrint(
              '[View] quality changed ${_currentQ} -> ${state.selectedQuality}, recreating');
          _recorderController.dispose();
          _create(state.selectedQuality);
        }
        if (state.recordingStatus == ReplayRecordingStatus.recording &&
            !_recorderController.isRecording) {
          debugPrint('[View] status recording -> start()');
          await _recorderController.start();
        }
        // ONLY place that stops - controls no longer stops
        if (state.finished && _recorderController.isRecording) {
          debugPrint('[View] finished=true & isRecording -> stop()');
          await _recorderController.stop();
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut);
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFECE5DD),
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: playback_header.PlaybackHeader(
                  project: widget.project,
                  onBack: widget.replayCubit.goBackToHome,
                  isSelectionMode: state.selectedMessageIds.isNotEmpty,
                  selectedCount: state.selectedMessageIds.length,
                  onClearSelection: () {},
                  deleteIconPressed: state.deleteIconPressed,
                  backTapPressed: state.visualInteraction ==
                      ReplayVisualInteraction.backTap)),
          body: Column(children: [
            Expanded(
                child: WidgetRecorder(
                    controller: _recorderController,
                    child: Stack(children: [
                      Positioned.fill(
                          child: Image.asset('assets/images/chat_wallpaper.png',
                              fit: BoxFit.cover)),
                      SafeArea(
                          top: false,
                          bottom: false,
                          child: Column(children: [
                            Expanded(
                                child: playback_chat_list.PlaybackChatList(
                                    project: widget.project,
                                    scrollController: _scrollController,
                                    selectedMessageIds:
                                        state.selectedMessageIds,
                                    onToggleSelection: (_) {},
                                    onSwipeReply: _onSwipeReply,
                                    onReplyTap: _onReplyTap)),
                            if (state.typing)
                              const TypingIndicator(visible: true),
                            const PlaybackBottomPanel(),
                          ])),
                      if (state.replayNotification != null)
                        Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: ReplayNotificationBanner(
                                notification: state.replayNotification!,
                                interaction:
                                    state.replayNotificationInteraction)),
                    ]))),
            ReplayPlaybackControls(
                state: state,
                replayCubit: widget.replayCubit,
                recorderController: _recorderController),
          ]),
        );
      },
    );
  }
}
