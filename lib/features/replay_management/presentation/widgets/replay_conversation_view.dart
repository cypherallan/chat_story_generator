import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
import '../../../person_management/domain/entities/person.dart';
import '../../../group_management/domain/entities/project.dart';
import '../../../message_management/domain/entities/message.dart';
import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';
import '../../../message_management/presentation/widgets/typing_indicator.dart';
import 'playback_chat_list.dart' as playback_chat_list;
import 'playback_header.dart' as playback_header;
import 'playback_bottom_panel.dart';
import '../widgets/replay_notification_banner.dart';

class ReplayConversationView extends StatefulWidget {
  final Project project;
  final List<Person> persons;
  final ConversationReplayCubit replayCubit;
  final ConversationReplayState state;
  final VoidCallback onBack;
  final WidgetRecorderController recorderController;
  const ReplayConversationView(
      {super.key,
      required this.project,
      required this.persons,
      required this.replayCubit,
      required this.state,
      required this.onBack,
      required this.recorderController});
  @override
  State<ReplayConversationView> createState() => _ReplayConversationViewState();
}

class _ReplayConversationViewState extends State<ReplayConversationView> {
  final ScrollController _scrollController = ScrollController();
  void _onSwipeReply(Message m) {}
  void _onReplyTap(String id) {}

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConversationReplayCubit, ConversationReplayState>(
      listenWhen: (p, c) =>
          (!p.showDeleteConfirmation && c.showDeleteConfirmation) ||
          (!p.finished && c.finished),
      listener: (context, state) {
        if (state.finished) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients)
              _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut);
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFECE5DD),
          appBar: PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: playback_header.PlaybackHeader(
                  project: widget.project,
                  onBack: widget.replayCubit.goBackToHome,
                  isSelectionMode: state.selectedMessageIds.isNotEmpty,
                  selectedCount: state.selectedMessageIds.length,
                  onClearSelection: () {},
                  deleteIconPressed: state.deleteIconPressed,
                  backTapPressed: state.visualInteraction ==
                      ReplayVisualInteraction.backTap)),
          body: Stack(children: [
            Positioned.fill(
                child: Image.asset('assets/images/chat_wallpaper.png',
                    fit: BoxFit.cover)),
            SafeArea(
                top: false,
                bottom: false,
                child: Column(children: [
                  Expanded(
                      child: playback_chat_list.PlaybackChatList(
                          project: widget.project,
                          scrollController: _scrollController,
                          selectedMessageIds: state.selectedMessageIds,
                          onToggleSelection: (_) {},
                          onSwipeReply: _onSwipeReply,
                          onReplyTap: _onReplyTap)),
                  if (state.typing) const TypingIndicator(visible: true),
                  const PlaybackBottomPanel(),
                ])),
            if (state.replayNotification != null)
              Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ReplayNotificationBanner(
                      notification: state.replayNotification!,
                      interaction: state.replayNotificationInteraction)),
          ]),
        );
      },
    );
  }
}
