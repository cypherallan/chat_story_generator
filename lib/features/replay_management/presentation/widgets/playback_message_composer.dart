import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import 'blinking_cursor.dart';

class PlaybackMessageComposer extends StatelessWidget {
  final String text;
  final bool keyboardVisible;

  const PlaybackMessageComposer({
    super.key,
    required this.text,
    required this.keyboardVisible,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationReplayCubit, ConversationReplayState>(
      buildWhen: (prev, curr) =>
          prev.composerText != curr.composerText ||
          prev.replyPreviewText != curr.replyPreviewText ||
          prev.replyPreviewSenderName != curr.replyPreviewSenderName,
      builder: (context, state) {
        final hasText = state.composerText.isNotEmpty;
        final hasReply = state.replyPreviewText != null;

        return Material(
          color: const Color(0xffF0F2F5),
          elevation: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ---------------------------------------------------------------
              // REPLY PREVIEW (WhatsApp style)
              // ---------------------------------------------------------------
              if (hasReply)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(
                        color: Color(0xff25D366),
                        width: 4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.replyPreviewSenderName ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xff25D366),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.replyPreviewText!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),

              // ---------------------------------------------------------------
              // COMPOSER ROW
              // ---------------------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.emoji_emotions_outlined,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Row(
                                children: [
                                  if (state.composerText.isNotEmpty)
                                    Flexible(
                                      child: Text(
                                        state.composerText,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  const BlinkingCursor(),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.attach_file,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.camera_alt,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xff25D366),
                      child: Icon(
                        hasText ? Icons.send : Icons.mic,
                        color: Colors.white,
                      ),
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
