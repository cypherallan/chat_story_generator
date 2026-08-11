import 'package:flutter/material.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../project_management/domain/entities/project.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';

import 'playback_chat_list.dart';
import 'playback_header.dart';
import 'playback_bottom_panel.dart';
import 'replay_playback_controls.dart';

class ReplayConversationView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFECE5DD),

      // -----------------------------------------------------------------------
      // WHATSAPP HEADER
      // -----------------------------------------------------------------------
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: PlaybackHeader(
          project: project,
          onBack: onBack,
        ),
      ),

      // -----------------------------------------------------------------------
      // CHAT BODY
      // Wallpaper exists ONLY inside the body.
      // Therefore it cannot appear behind the header.
      // -----------------------------------------------------------------------
      body: Stack(
        children: [
          // ---------------------------------------------------------------
          // CHAT WALLPAPER
          // ---------------------------------------------------------------
          Positioned.fill(
            child: Image.asset(
              'assets/images/chat_wallpaper.png',
              fit: BoxFit.cover,
            ),
          ),

          // ---------------------------------------------------------------
          // CHAT CONTENT
          // ---------------------------------------------------------------
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                // ---------------------------------------------------------
                // MESSAGES
                // ---------------------------------------------------------
                Expanded(
                  child: PlaybackChatList(
                    project: project,
                    scrollController: ScrollController(),
                  ),
                ),

                // ---------------------------------------------------------
                // TYPING INDICATOR
                // ---------------------------------------------------------
                if (state.typing) const ReplayTypingIndicator(),

                // ---------------------------------------------------------
                // COMPOSER + KEYBOARD
                // ---------------------------------------------------------
                const PlaybackBottomPanel(),

                // ---------------------------------------------------------
                // PLAY / PAUSE / STOP
                // ---------------------------------------------------------
                ReplayPlaybackControls(
                  state: state,
                  replayCubit: replayCubit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// REPLAY TYPING INDICATOR
// =============================================================================

class ReplayTypingIndicator extends StatefulWidget {
  const ReplayTypingIndicator({
    super.key,
  });

  @override
  State<ReplayTypingIndicator> createState() => _ReplayTypingIndicatorState();
}

class _ReplayTypingIndicatorState extends State<ReplayTypingIndicator> {
  int _dotCount = 1;

  @override
  void initState() {
    super.initState();
    _animateDots();
  }

  Future<void> _animateDots() async {
    while (mounted) {
      await Future.delayed(
        const Duration(milliseconds: 350),
      );

      if (!mounted) return;

      setState(() {
        _dotCount++;

        if (_dotCount > 3) {
          _dotCount = 1;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        4,
        16,
        8,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTypingAvatar(),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '.' * _dotCount,
                style: const TextStyle(
                  fontSize: 20,
                  height: 0.8,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingAvatar() {
    return const CircleAvatar(
      radius: 16,
      child: Icon(
        Icons.person,
        size: 18,
      ),
    );
  }
}
