import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../project_management/domain/entities/project.dart';
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

  const ReplayConversationView({
    super.key,
    required this.project,
    required this.persons,
    required this.replayCubit,
    required this.state,
    required this.onBack,
  });

  @override
  State<ReplayConversationView> createState() => _ReplayConversationViewState();
}

class _ReplayConversationViewState extends State<ReplayConversationView> {
  final ScrollController _scrollController = ScrollController();
  late final WidgetRecorderController _recorderController;

  @override
  void initState() {
    super.initState();
    _recorderController = WidgetRecorderController(
      recordAudio: false,
      onComplete: (path) {
        widget.replayCubit.onRecordingCompleted(path);
      },
      onError: (error) {
        widget.replayCubit.onRecordingFailed(error);
      },
    );

    // CRASH FIX: default is 60fps = huge RAM. Set to 15fps = 4x smaller
    _recorderController.fps = 15;

    Future.delayed(const Duration(seconds: 90), () {
      if (mounted && _recorderController.isRecording) {
        _recorderController.stop();
      }
    });
  }

  @override
  void dispose() {
    if (_recorderController.isRecording) {
      _recorderController.stop();
    }
    _scrollController.dispose();
    _recorderController.dispose();
    super.dispose();
  }

  void _onSwipeReply(Message message) {}
  void _onReplyTap(String messageId) {}

  Future<void> _showDeleteDialog(
      BuildContext context, ConversationReplayState state) async {
    if (state.selectedMessageIds.isEmpty) return;
    final messageId = state.selectedMessageIds.first;
    Message? selectedMessage;
    for (final message in state.visibleMessages) {
      if (message.id == messageId) {
        selectedMessage = message;
        break;
      }
    }
    if (selectedMessage == null) return;
    final message = selectedMessage;
    final dialogFuture = showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text('Delete this message?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete for me')),
          ],
        );
      },
    );
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    if (widget.replayCubit.state.screen != ReplayScreen.conversation) return;
    Navigator.of(context, rootNavigator: true).pop(true);
    await dialogFuture;
    if (!mounted) return;
    if (widget.replayCubit.state.screen != ReplayScreen.conversation) return;
    widget.replayCubit.deleteMessageForMe(message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationReplayCubit, ConversationReplayState>(
      listenWhen: (previous, current) =>
          (!previous.showDeleteConfirmation &&
              current.showDeleteConfirmation) ||
          (!previous.finished && current.finished),
      listener: (context, state) {
        if (state.showDeleteConfirmation) {
          _showDeleteDialog(context, state);
        }
        if (state.finished) {
          // Keep last message visible, don't blank screen
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      },
      builder: (context, state) {
        final selectedIds = state.selectedMessageIds;
        final isSelectionMode = selectedIds.isNotEmpty;

        return Scaffold(
          backgroundColor: const Color(0xFFECE5DD),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: playback_header.PlaybackHeader(
              project: widget.project,
              onBack: widget.replayCubit.goBackToHome,
              isSelectionMode: isSelectionMode,
              selectedCount: selectedIds.length,
              onClearSelection: () {},
              deleteIconPressed: state.deleteIconPressed,
              backTapPressed:
                  state.visualInteraction == ReplayVisualInteraction.backTap,
            ),
          ),
          // RECORD ONLY CONVERSATION CONTENT - NOT CONTROLS
          body: Column(
            children: [
              Expanded(
                child: WidgetRecorder(
                  controller: _recorderController,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset('assets/images/chat_wallpaper.png',
                            fit: BoxFit.cover),
                      ),
                      SafeArea(
                        top: false,
                        bottom: false,
                        child: Column(
                          children: [
                            Expanded(
                              child: playback_chat_list.PlaybackChatList(
                                project: widget.project,
                                scrollController: _scrollController,
                                selectedMessageIds: selectedIds,
                                onToggleSelection: (_) {},
                                onSwipeReply: _onSwipeReply,
                                onReplyTap: _onReplyTap,
                              ),
                            ),
                            if (state.typing)
                              const TypingIndicator(visible: true),
                            const PlaybackBottomPanel(),
                          ],
                        ),
                      ),
                      if (state.replayNotification != null)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: ReplayNotificationBanner(
                            notification: state.replayNotification!,
                            interaction: state.replayNotificationInteraction,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // CONTROLS OUTSIDE RECORDER - WILL NOT APPEAR IN VIDEO
              ReplayPlaybackControls(
                state: state,
                replayCubit: widget.replayCubit,
                recorderController: _recorderController,
              ),
            ],
          ),
        );
      },
    );
  }
}
