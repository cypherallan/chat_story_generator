import 'package:flutter/material.dart';

import '../../../person_management/domain/entities/person.dart';
import '../../../project_management/domain/entities/project.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import '../../../message_management/presentation/widgets/typing_indicator.dart';
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
                if (state.typing)
                  const TypingIndicator(
                    visible: true,
                  ),

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
