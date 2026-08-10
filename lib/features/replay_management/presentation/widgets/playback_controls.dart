import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/conversation_replay_cubit.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
      builder: (context, state) {
        return FloatingActionButton(
          child: Icon(
            state.playing ? Icons.pause : Icons.play_arrow,
          ),
          onPressed: () {
            final cubit = context.read<ConversationReplayCubit>();

            if (state.playing) {
              cubit.pause();
            } else {
              cubit.play();
            }
          },
        );
      },
    );
  }
}
