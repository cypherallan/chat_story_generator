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

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
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
                // During automated replay we ignore manual clear
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
                        onToggleSelection: (_) {}, // driven by cubit
                        onSwipeReply: _onSwipeReply,
                        onReplyTap: _onReplyTap,
                      ),
                    ),
                    if (state.typing) const TypingIndicator(visible: true),
                    const PlaybackBottomPanel(),
                    ReplayPlaybackControls(
                      state: state,
                      replayCubit: widget.replayCubit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
