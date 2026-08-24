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

    // The replay has reached the end.
    // Stop the video recorder automatically.
    if (!oldWidget.state.finished && widget.state.finished) {
      _finishRecording();
    }
  }

  Future<void> _finishRecording() async {
    if (!widget.recorderController.isRecording) {
      return;
    }

    debugPrint('Replay finished — stopping video recording.');

    final path = await widget.recorderController.stop();

    if (path != null) {
      debugPrint('Replay video saved: $path');
    }
  }

  Future<void> _showExportDialog(BuildContext context) async {
    String selectedQuality = '720p';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Export Replay'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Select video quality',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('480p'),
                    subtitle: const Text('480 × 854'),
                    value: '480p',
                    groupValue: selectedQuality,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedQuality = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('720p'),
                    subtitle: const Text('720 × 1280'),
                    value: '720p',
                    groupValue: selectedQuality,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedQuality = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('1080p'),
                    subtitle: const Text('1080 × 1920'),
                    value: '1080p',
                    groupValue: selectedQuality,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedQuality = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();

                    VideoQuality quality;

                    switch (selectedQuality) {
                      case '480p':
                        quality = VideoQuality.low;
                        break;

                      case '1080p':
                        quality = VideoQuality.high;
                        break;

                      case '720p':
                      default:
                        quality = VideoQuality.medium;
                        break;
                    }

                    widget.recorderController.applyVideoQuality(quality);

                    // Reset the replay to its initial state.
                    widget.replayCubit.stop();

                    // Start recording BEFORE replay starts.
                    await widget.recorderController.start();

                    // Now play the replay.
                    widget.replayCubit.play();
                  },
                  child: const Text('Export'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

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
              icon: const Icon(Icons.play_arrow),
              onPressed: state.playing
                  ? null
                  : () {
                      widget.replayCubit.play();
                    },
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Pause',
              iconSize: 32,
              icon: const Icon(Icons.pause),
              onPressed: state.playing
                  ? () {
                      widget.replayCubit.pause();
                    }
                  : null,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Stop',
              iconSize: 32,
              icon: const Icon(Icons.stop),
              onPressed: () {
                widget.replayCubit.stop();
                if (widget.recorderController.isRecording) {
                  widget.recorderController.stop();
                }
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Export replay',
              iconSize: 32,
              icon: const Icon(Icons.download),
              onPressed: state.playing || widget.recorderController.isRecording
                  ? null
                  : () {
                      _showExportDialog(context);
                    },
            ),
          ],
        ),
      ),
    );
  }
}
