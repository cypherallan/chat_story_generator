import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // SWIPE TO REPLY (still placeholder – visual is already handled)
  // ===========================================================================

  void _onSwipeReply(Message message) {}

  void _onReplyTap(String messageId) {}

  void _onReplayNotificationTap() {
    widget.replayCubit.notificationCubit.recordTap();
  }

  void _onReplayNotificationSwipe() {
    widget.replayCubit.notificationCubit.recordSwipe();
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    ConversationReplayState state,
  ) async {
    // We expect exactly one message to be selected during
    // the automated replay deletion sequence.
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

    // ---------------------------------------------------------------------------
    // SHOW DELETE CONFIRMATION
    // ---------------------------------------------------------------------------

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

    // ---------------------------------------------------------------------------
    // LET THE DIALOG BE VISIBLE
    // ---------------------------------------------------------------------------
    //
    // This represents the replay pausing long enough for the viewer to see
    // the confirmation dialog before the automated tap occurs.
    //

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

    // ---------------------------------------------------------------------------
    // APPLY DELETE
    // ---------------------------------------------------------------------------

    widget.replayCubit.deleteMessageForMe(message);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

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

        return Scaffold(
          backgroundColor: const Color(0xFFECE5DD),
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: playback_header.PlaybackHeader(
              project: widget.project,
              onBack: widget.onBack,
              isSelectionMode: isSelectionMode,
              selectedCount: selectedIds.length,
              onClearSelection: () {
                // Automated replay controls selection.
                // Manual clearing will be handled later.
              },
              deleteIconPressed: state.deleteIconPressed,
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
                    onTap: _onReplayNotificationTap,
                    onSwipe: _onReplayNotificationSwipe,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
