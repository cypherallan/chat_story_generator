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
      showTouches: false,
      onComplete: (path) {
        debugPrint('Replay video saved: $path');
      },
      onError: (error) {
        debugPrint('Replay video export error: $error');
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _recorderController.dispose();
    super.dispose();
  }

  void _onSwipeReply(Message message) {}

  void _onReplyTap(String messageId) {}

  Future<void> _showDeleteDialog(
    BuildContext context,
    ConversationReplayState state,
  ) async {
    if (state.selectedMessageIds.isEmpty) {
      return;
    }

    final messageId = state.selectedMessageIds.first;

    Message? selectedMessage;

    for (final message in state.visibleMessages) {
      if (message.id == messageId) {
        selectedMessage = message;
        break;
      }
    }

    if (selectedMessage == null) {
      return;
    }

    final message = selectedMessage;

    final dialogFuture = showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete message'),
          content: const Text(
            'Delete this message?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete for me'),
            ),
          ],
        );
      },
    );

    await Future.delayed(
      const Duration(milliseconds: 900),
    );

    if (!mounted) {
      return;
    }

    if (widget.replayCubit.state.screen != ReplayScreen.conversation) {
      return;
    }

    Navigator.of(context, rootNavigator: true).pop(true);

    await dialogFuture;

    if (!mounted) {
      return;
    }

    if (widget.replayCubit.state.screen != ReplayScreen.conversation) {
      return;
    }

    widget.replayCubit.deleteMessageForMe(message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationReplayCubit, ConversationReplayState>(
      listenWhen: (previous, current) =>
          !previous.showDeleteConfirmation && current.showDeleteConfirmation,
      listener: (context, state) {
        _showDeleteDialog(context, state);
      },
      builder: (context, state) {
        final selectedIds = state.selectedMessageIds;
        final isSelectionMode = selectedIds.isNotEmpty;

        return WidgetRecorder(
          controller: _recorderController,
          child: Scaffold(
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
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/chat_wallpaper.png',
                    fit: BoxFit.cover,
                  ),
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
                        const TypingIndicator(
                          visible: true,
                        ),
                      const PlaybackBottomPanel(),
                      ReplayPlaybackControls(
                        state: state,
                        replayCubit: widget.replayCubit,
                        recorderController: _recorderController,
                      ),
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
        );
      },
    );
  }
}
