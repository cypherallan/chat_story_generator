import 'package:flutter/material.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';

import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';

class ReplayPlaybackControls extends StatefulWidget {
  final ConversationReplayState state;
  final ConversationReplayCubit replayCubit;
  final WidgetRecorderController recorderController;

  const ReplayPlaybackControls({
    super.key,
    required this.state,
    required this.replayCubit,
    required this.recorderController,
  });

  @override
  State<ReplayPlaybackControls> createState() => _ReplayPlaybackControlsState();
}

class _ReplayPlaybackControlsState extends State<ReplayPlaybackControls> {
  @override
  void didUpdateWidget(covariant ReplayPlaybackControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.state.finished && widget.state.finished) {
      _finishRecording();
    }
    if (oldWidget.state.recordingStatus != ReplayRecordingStatus.recorded &&
        widget.state.recordingStatus == ReplayRecordingStatus.recorded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recorded: ${widget.state.recordedTempPath}')),
        );
        _showPostRecordExportDialog(context);
      });
    }
  }

  Future<void> _finishRecording() async {
    if (!widget.recorderController.isRecording) return;
    debugPrint('Replay finished — stopping video recording.');
    try {
      await widget.recorderController.stop();
    } catch (e) {
      debugPrint('Stop error: $e');
      widget.replayCubit.onRecordingFailed(e.toString());
    }
  }

  Future<void> _showRecordDialog(BuildContext context) async {
    String selectedQuality = '480p'; // Default to 480p to prevent crash

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Record Replay'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                      'Long chats can crash on high quality. Use 480p for safety.'),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('480p - safe (recommended)'),
                    value: '480p',
                    groupValue: selectedQuality,
                    onChanged: (v) => setState(() => selectedQuality = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('720p - medium (may crash if >30 msgs)'),
                    value: '720p',
                    groupValue: selectedQuality,
                    onChanged: (v) => setState(() => selectedQuality = v!),
                  ),
                  RadioListTile<String>(
                    title: const Text('1080p - high (very likely crash)'),
                    value: '1080p',
                    groupValue: selectedQuality,
                    onChanged: (v) => setState(() => selectedQuality = v!),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel')),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();

                    ReplayExportQuality exportQuality;
                    switch (selectedQuality) {
                      case '480p':
                        exportQuality = ReplayExportQuality.low;
                        break;
                      case '1080p':
                        exportQuality = ReplayExportQuality.high;
                        break;
                      default:
                        exportQuality = ReplayExportQuality.medium;
                    }

                    widget.replayCubit.setSelectedQuality(exportQuality);

                    // REMOVED applyVideoQuality — it doesn't exist and crashes app
                    await widget.replayCubit.startRecordReplay();
                    await widget.recorderController.start();
                  },
                  child: const Text('Record'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPostRecordExportDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Recording Finished'),
          content: Text(
              'Video saved temp at:\n${widget.state.recordedTempPath}\n\nExport to device storage?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Later')),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.replayCubit.exportRecordedVideo();
              },
              child: const Text('Export to Gallery'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isRecording =
        state.recordingStatus == ReplayRecordingStatus.recording;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                tooltip: 'Play - Preview',
                iconSize: 32,
                icon: const Icon(Icons.play_arrow),
                onPressed: state.playing || isRecording
                    ? null
                    : () => widget.replayCubit.play()),
            const SizedBox(width: 8),
            IconButton(
                tooltip: 'Pause',
                iconSize: 32,
                icon: const Icon(Icons.pause),
                onPressed:
                    state.playing ? () => widget.replayCubit.pause() : null),
            const SizedBox(width: 8),
            IconButton(
                tooltip: 'Stop',
                iconSize: 32,
                icon: const Icon(Icons.stop),
                onPressed: () {
                  widget.replayCubit.stop();
                  widget.replayCubit.resetRecording();
                  if (widget.recorderController.isRecording)
                    widget.recorderController.stop();
                }),
            const SizedBox(width: 12),
            FilledButton.icon(
                icon: Icon(
                    isRecording ? Icons.videocam : Icons.fiber_manual_record,
                    color: isRecording ? Colors.red : null),
                label: Text(isRecording ? 'Recording...' : 'Record Replay'),
                onPressed: state.playing || isRecording
                    ? null
                    : () => _showRecordDialog(context)),
          ],
        ),
      ),
    );
  }
}
