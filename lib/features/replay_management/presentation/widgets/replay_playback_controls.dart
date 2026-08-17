import 'package:flutter/material.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';

class ReplayPlaybackControls extends StatelessWidget {
  final ConversationReplayState state;
  final ConversationReplayCubit replayCubit;

  const ReplayPlaybackControls({
    super.key,
    required this.state,
    required this.replayCubit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              tooltip: 'Play',
              iconSize: 32,
              icon: const Icon(
                Icons.play_arrow,
              ),
              onPressed: state.playing
                  ? null
                  : () {
                      replayCubit.play();
                    },
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Pause',
              iconSize: 32,
              icon: const Icon(
                Icons.pause,
              ),
              onPressed: state.playing
                  ? () {
                      replayCubit.pause();
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Stop',
              iconSize: 32,
              icon: const Icon(
                Icons.stop,
              ),
              onPressed: () {
                replayCubit.stop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
