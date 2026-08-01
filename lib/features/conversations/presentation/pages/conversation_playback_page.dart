import 'package:flutter/material.dart';

import '../../../message_management/domain/entities/message.dart';
import '../../../project_management/domain/entities/project.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../conversations/presentation/cubit/conversation_replay_cubit.dart';

import '../widgets/playback_header.dart';
import '../widgets/playback_chat_list.dart';
import '../widgets/playback_controls.dart';
import '../widgets/playback_bottom_panel.dart';

class ConversationPlaybackPage extends StatefulWidget {
  final Project project;
  final List<Message> messages;

  const ConversationPlaybackPage({
    super.key,
    required this.project,
    required this.messages,
  });

  @override
  State<ConversationPlaybackPage> createState() =>
      _ConversationPlaybackPageState();
}

class _ConversationPlaybackPageState extends State<ConversationPlaybackPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final replayCubit = context.read<ConversationReplayCubit>();

    replayCubit.load(
      widget.messages,
      widget.project.ownerId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const PlaybackControls(),
      appBar: AppBar(
        titleSpacing: 0,
        title: PlaybackHeader(
          project: widget.project,
        ),
      ),
      body: Column(children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/chat_wallpaper.png',
                  fit: BoxFit.cover,
                ),
              ),
              PlaybackChatList(
                project: widget.project,
                scrollController: _scrollController,
              ),
            ],
          ),
        ),
        const PlaybackBottomPanel(),
      ]),
    );
  }
}
