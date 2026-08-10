import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../project_management/domain/entities/project.dart';
import '../../../person_management/presentation/cubit/person_cubit.dart';
import '../../../message_management/presentation/cubit/message_cubit.dart';
import '../../../project_management/presentation/cubit/project_cubit.dart';

import '../widgets/conversation_app_bar.dart';
import '../../../replay_management/presentation/pages/conversation_playback_page.dart';
import '../../../replay_management/presentation/cubit/conversation_replay_cubit.dart';
import 'conversation_page_body.dart';

class ConversationPage extends StatefulWidget {
  final Project project;

  const ConversationPage({
    super.key,
    required this.project,
  });

  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final GlobalKey<ConversationPageBodyState> _bodyKey =
      GlobalKey<ConversationPageBodyState>();

  // Local mirrors so the AppBar can rebuild
  Set<String> _typingPersonIds = {};
  bool _otherPersonTyping = false;
  Set<String> _selectedMessageIds = {};
  bool _isSelectionMode = false;

  void _onBodyChanged() {
    final body = _bodyKey.currentState;
    if (body == null) return;

    setState(() {
      _typingPersonIds = Set.from(body.typingPersonIds);
      _otherPersonTyping = body.otherPersonTyping;
      _selectedMessageIds = Set.from(body.selectedMessageIds);
      _isSelectionMode = body.isSelectionMode;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final body = _bodyKey.currentState;
      if (body != null) {
        context.read<PersonCubit>().setPersonOnline(body.selectedSenderId);
      }
      context.read<ProjectCubit>().clearUnreadCount(widget.project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) return;
        final body = _bodyKey.currentState;
        if (body != null) {
          context.read<PersonCubit>().setPersonOffline(body.selectedSenderId);
        }
        await context.read<ProjectCubit>().loadProjects();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: ConversationAppBar(
          project: widget.project,
          isSelectionMode: _isSelectionMode,
          selectedCount: _selectedMessageIds.length,
          typingPersonIds: _typingPersonIds,
          otherPersonTyping: _otherPersonTyping,
          onClearSelection: () =>
              _bodyKey.currentState?.clearMessageSelection(),
          onPreviewPressed: () {
            final state = context.read<MessageCubit>().state;
            if (state is! MessageLoaded) return;

            final personCubit = context.read<PersonCubit>();
            final messageCubit = context.read<MessageCubit>();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: personCubit),
                    BlocProvider.value(value: messageCubit),
                    BlocProvider(create: (_) => ConversationReplayCubit()),
                  ],
                  child: ConversationPlaybackPage(
                    project: widget.project,
                    messages: state.messages,
                  ),
                ),
              ),
            );
          },
          selectedMessageIds: _selectedMessageIds,
          onReplySelected: (message) {
            _bodyKey.currentState?.setReplyingTo(message);
          },
          onReactionSelected: (messageId, emoji) {
            context.read<MessageCubit>().toggleReaction(
                  messageId: messageId,
                  userId: widget.project.ownerId,
                  emoji: emoji,
                );
          },
          onDeleteSelected: () async {
            await _bodyKey.currentState?.deleteSelectedMessages();
          },
        ),
        body: ConversationPageBody(
          key: _bodyKey,
          project: widget.project,
          onChanged: _onBodyChanged,
        ),
      ),
    );
  }
}
