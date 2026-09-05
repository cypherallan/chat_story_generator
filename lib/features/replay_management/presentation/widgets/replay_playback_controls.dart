import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
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
  BuildContext? _exportCtx;

  @override
  void didUpdateWidget(covariant ReplayPlaybackControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    final wasRecorded =
        oldWidget.state.recordingStatus == ReplayRecordingStatus.recorded;

    final isRecorded =
        widget.state.recordingStatus == ReplayRecordingStatus.recorded;

    final wasExporting =
        oldWidget.state.recordingStatus == ReplayRecordingStatus.exporting;

    final isExporting =
        widget.state.recordingStatus == ReplayRecordingStatus.exporting;

    final wasExported =
        oldWidget.state.recordingStatus == ReplayRecordingStatus.exported;

    final isExported =
        widget.state.recordingStatus == ReplayRecordingStatus.exported;

    final wasFailed =
        oldWidget.state.recordingStatus == ReplayRecordingStatus.failed;

    final isFailed =
        widget.state.recordingStatus == ReplayRecordingStatus.failed;

    // Recording has genuinely completed.
    if (!wasRecorded && isRecorded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPostRecordDialog();
      });
    }

    // Export started.
    if (!wasExporting && isExporting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showExportingDialog();
      });
    }

    // Export completed.
    if (!wasExported && isExported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _closeExporting();

        final path = widget.state.exportedPath;
        if (path != null) {
          _showSuccess(path);
        }
      });
    }

    // Export/recording failed.
    if (!wasFailed && isFailed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _closeExporting();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.state.recordingError ?? 'Recording/export failed.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  /// Called when the user presses PLAY.
  ///
  /// This is the preview decision:
  /// - No  -> replay only
  /// - Yes -> recording + replay
  Future<void> _showPlayOptionsDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        title: const Text('Replay'),
        content: const Text(
          'Would you like to record this conversation as well?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();

              // IMPORTANT:
              // This is replay-only. The recorder is never started.
              widget.replayCubit.play();
            },
            child: const Text('No, just replay'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dCtx).pop();

              // Start recording immediately before starting
              // the replay so the beginning is not missed.
              await _startRecordingReplay();
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  /// Starts the recorder first, then starts the replay.
  ///
  /// This replaces the old quality-selection flow.
  Future<void> _startRecordingReplay() async {
    if (!mounted) return;

    try {
      debugPrint('[Replay] Preparing recording timeline');

      widget.replayCubit.prepareRecordingAudioTracking();

      debugPrint('[Replay] Starting recorder after audio timeline');

      if (!widget.recorderController.isRecording) {
        await widget.recorderController.start();
      }

      if (!widget.recorderController.isRecording) {
        debugPrint(
          '[Replay] Recorder did not start. Recording will not begin.',
        );
        return;
      }

      debugPrint('[Replay] Recorder started successfully');

      // The Cubit changes its state to "recording" and starts
      // the replay from the selected conversation/start point.
      await widget.replayCubit.startRecordReplay();

      debugPrint('[Replay] Recording + replay started');
    } catch (e) {
      debugPrint('[Replay] Failed to start recording: $e');

      if (widget.recorderController.isRecording) {
        await widget.recorderController.stop();
      }

      widget.replayCubit.onRecordingFailed(e.toString());
    }
  }

  /// Shows while the actual export operation is running.
  ///
  /// We deliberately don't display a fake percentage because
  /// ReplayExportService currently doesn't provide real progress.
  void _showExportingDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        _exportCtx = dCtx;

        return const AlertDialog(
          title: Text('Saving video...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Please wait while your video is saved.',
              ),
            ],
          ),
        );
      },
    );
  }

  void _closeExporting() {
    if (_exportCtx != null) {
      final navigator = Navigator.of(_exportCtx!);

      if (navigator.canPop()) {
        navigator.pop();
      }
    }

    _exportCtx = null;
  }

  /// Shown after the recording has finished and the recorder
  /// has returned the temporary MP4 file.
  Future<void> _showPostRecordDialog() async {
    if (!mounted) return;

    final tempPath = widget.state.recordedTempPath;

    if (tempPath == null || tempPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording completed, but no video file was produced.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    debugPrint('[Replay] Recording completed: $tempPath');

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text('Recording Complete'),
            ),
          ],
        ),
        content: const Text(
          'Would you like to download/save the recorded video?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
            },
            child: const Text('No'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Yes'),
            onPressed: () {
              Navigator.of(dCtx).pop();
              widget.replayCubit.exportRecordedVideo();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccess(String path) async {
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text('Video Saved'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Video saved at:'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                path,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dCtx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow),
            label: const Text('Open'),
            onPressed: () async {
              Navigator.of(dCtx).pop();
              await OpenFilex.open(path);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;

    final isRec = s.recordingStatus == ReplayRecordingStatus.recording;

    final isExp = s.recordingStatus == ReplayRecordingStatus.exporting;

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
              iconSize: 32,
              icon: const Icon(Icons.play_arrow),
              onPressed:
                  s.playing || isRec || isExp ? null : _showPlayOptionsDialog,
            ),

            const SizedBox(width: 8),

            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.pause),
              onPressed: s.playing ? () => widget.replayCubit.pause() : null,
            ),

            const SizedBox(width: 8),

            IconButton(
              iconSize: 32,
              icon: const Icon(Icons.stop),
              onPressed: () async {
                widget.replayCubit.stop();

                if (widget.recorderController.isRecording) {
                  await widget.recorderController.stop();
                }

                widget.replayCubit.resetRecording();
              },
            ),

            const SizedBox(width: 12),

            // Recording indicator/button remains visible.
            FilledButton.icon(
              icon: Icon(
                isRec
                    ? Icons.videocam
                    : isExp
                        ? Icons.hourglass_top
                        : Icons.fiber_manual_record,
                color: isRec ? Colors.red : null,
              ),
              label: Text(
                isRec
                    ? 'Recording...'
                    : isExp
                        ? 'Saving...'
                        : 'Record Replay',
              ),
              onPressed:
                  s.playing || isRec || isExp ? null : _showPlayOptionsDialog,
            ),
          ],
        ),
      ),
    );
  }
}
