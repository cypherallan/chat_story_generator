import 'package:flutter/material.dart';

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
  State<ReplayConversationView> createState() =>
      _ReplayConversationViewState();
}

class _ReplayConversationViewState extends State<ReplayConversationView> {
  final ScrollController _scrollController = ScrollController();

  final Set<String> _selectedMessageIds = {};

  bool get _isSelectionMode => _selectedMessageIds.isNotEmpty;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // MESSAGE SELECTION
  // ===========================================================================

  void _toggleMessageSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
      } else {
        _selectedMessageIds.add(messageId);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessageIds.clear();
    });
  }

  // ===========================================================================
  // SWIPE TO REPLY
  // ===========================================================================

  void _onSwipeReply(Message message) {
    // Replay does not modify the actual conversation.
    //
    // MessageBubble handles the visual swipe animation itself.
    //
    // This callback is intentionally left as a placeholder for now.
  }

  // ===========================================================================
  // REPLY PREVIEW TAP
  // ===========================================================================

  void _onReplyTap(String messageId) {
    // Placeholder for now.
    //
    // Later we can make replay scroll to the original
    // replied-to message.
  }

  // ===========================================================================
  // HEADER
  // ===========================================================================

  Widget _buildHeader() {
    return playback_header.PlaybackHeader(
      project: widget.project,
      onBack: widget.onBack,
      isSelectionMode: _isSelectionMode,
      selectedCount: _selectedMessageIds.length,
      onClearSelection: _clearSelection,
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),

      // -----------------------------------------------------------------------
      // WHATSAPP HEADER
      //
      // The header is completely separate from the wallpaper.
      // -----------------------------------------------------------------------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: _buildHeader(),
      ),

      // -----------------------------------------------------------------------
      // CHAT BODY
      // -----------------------------------------------------------------------
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // CHAT WALLPAPER
          // -------------------------------------------------------------------
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat_wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),

          // -------------------------------------------------------------------
          // CHAT CONTENT
          // -------------------------------------------------------------------
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                // -----------------------------------------------------------------
                // MESSAGES
                // -----------------------------------------------------------------
                Expanded(
                  child: playback_chat_list.PlaybackChatList(
                    project: widget.project,
                    scrollController: _scrollController,
                    selectedMessageIds: _selectedMessageIds,
                    onToggleSelection: _toggleMessageSelection,
                    onSwipeReply: _onSwipeReply,
                    onReplyTap: _onReplyTap,
                  ),
                ),

                // -----------------------------------------------------------------
                // TYPING INDICATOR
                // -----------------------------------------------------------------
                if (widget.state.typing)
                  const TypingIndicator(
                    visible: true,
                  ),

                // -----------------------------------------------------------------
                // COMPOSER + KEYBOARD
                // -----------------------------------------------------------------
                const PlaybackBottomPanel(),

                // -----------------------------------------------------------------
                // PLAY / PAUSE / STOP
                // -----------------------------------------------------------------
                ReplayPlaybackControls(
                  state: widget.state,
                  replayCubit: widget.replayCubit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}