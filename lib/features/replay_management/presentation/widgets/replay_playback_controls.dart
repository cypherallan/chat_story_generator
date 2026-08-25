import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:widget_recorder_plus/widget_recorder_plus.dart';
import 'package:open_filex/open_filex.dart';
import '../cubit/conversation_replay_cubit.dart';
import '../cubit/conversation_replay_state.dart';

class ReplayPlaybackControls extends StatefulWidget {
  final ConversationReplayState state;
  final ConversationReplayCubit replayCubit;
  final WidgetRecorderController recorderController;
  const ReplayPlaybackControls(
      {super.key,
      required this.state,
      required this.replayCubit,
      required this.recorderController});

  @override
  State<ReplayPlaybackControls> createState() => _ReplayPlaybackControlsState();
}

class _ReplayPlaybackControlsState extends State<ReplayPlaybackControls> {
  // keep ref to progress dialog
  BuildContext? _exportDialogContext;
  Timer? _progressTimer;
  double _exportProgress = 0;

  @override
  void didUpdateWidget(covariant ReplayPlaybackControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.state.finished && widget.state.finished) _finishRecording();

    // RECORDING -> recorded
    if (oldWidget.state.recordingStatus != ReplayRecordingStatus.recorded &&
        widget.state.recordingStatus == ReplayRecordingStatus.recorded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showPostRecordExportDialog(context);
      });
    }

    // EXPORTING
    if (oldWidget.state.recordingStatus != ReplayRecordingStatus.exporting &&
        widget.state.recordingStatus == ReplayRecordingStatus.exporting) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showExportingDialog(context);
      });
    }

    // EXPORTED SUCCESS
    if (oldWidget.state.recordingStatus != ReplayRecordingStatus.exported &&
        widget.state.recordingStatus == ReplayRecordingStatus.exported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _closeExportingDialog();
        _showExportSuccessDialog(context, widget.state.exportedPath!);
      });
    }

    // FAILED
    if (oldWidget.state.recordingStatus != ReplayRecordingStatus.failed &&
        widget.state.recordingStatus == ReplayRecordingStatus.failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _closeExportingDialog();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Export failed: ${widget.state.recordingError}'),
              backgroundColor: Colors.red),
        );
      });
    }
  }

  Future<void> _finishRecording() async {
    if (!widget.recorderController.isRecording) return;
    try {
      await widget.recorderController.stop();
    } catch (e) {
      widget.replayCubit.onRecordingFailed(e.toString());
    }
  }

  void _showExportingDialog(BuildContext context) {
    _exportProgress = 0;
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (_exportProgress < 90) {
        setState(() => _exportProgress += 2);
        if (_exportDialogContext != null) {
          (_exportDialogContext! as Element).markNeedsBuild();
        }
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _exportDialogContext = dialogContext;
        return StatefulBuilder(builder: (ctx, setDialogState) {
          // Rebuild dialog on progress
          _progressTimer?.cancel();
          _progressTimer =
              Timer.periodic(const Duration(milliseconds: 200), (_) {
            if (_exportProgress < 90) {
              setDialogState(() => _exportProgress += 1.5);
            }
          });
          return AlertDialog(
            title: const Text('Exporting video...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(value: _exportProgress / 100),
                const SizedBox(height: 12),
                Text('${_exportProgress.toStringAsFixed(0)}%'),
                const SizedBox(height: 8),
                const Text('Saving to Movies/ChatStoryGenerator',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        });
      },
    );
  }

  void _closeExportingDialog() {
    _progressTimer?.cancel();
    if (_exportDialogContext != null &&
        Navigator.of(_exportDialogContext!).canPop()) {
      Navigator.of(_exportDialogContext!).pop();
    }
    _exportDialogContext = null;
  }

  Future<void> _showExportSuccessDialog(
      BuildContext context, String path) async {
    setState(() => _exportProgress = 100);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Export Successful')
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Video saved at:'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8)),
                child: SelectableText(path,
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ),
              const SizedBox(height: 12),
              const Text(
                  'You can find it in Files > Movies > ChatStoryGenerator',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close')),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Open'),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final file = File(path);
                if (await file.exists()) {
                  await OpenFilex.open(path);
                } else {
                  // If path is Gallery virtual path, try open gallery
                  await OpenFilex.open(path);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRecordDialog(BuildContext context) async {
    String selectedQuality = '480p';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text('Record Replay'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              RadioListTile<String>(
                  title: const Text('480p - safe'),
                  value: '480p',
                  groupValue: selectedQuality,
                  onChanged: (v) => setState(() => selectedQuality = v!)),
              RadioListTile<String>(
                  title: const Text('720p'),
                  value: '720p',
                  groupValue: selectedQuality,
                  onChanged: (v) => setState(() => selectedQuality = v!)),
              RadioListTile<String>(
                  title: const Text('1080p'),
                  value: '1080p',
                  groupValue: selectedQuality,
                  onChanged: (v) => setState(() => selectedQuality = v!)),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    ReplayExportQuality q = selectedQuality == '480p'
                        ? ReplayExportQuality.low
                        : selectedQuality == '1080p'
                            ? ReplayExportQuality.high
                            : ReplayExportQuality.medium;
                    widget.replayCubit.setSelectedQuality(q);
                    await widget.replayCubit.startRecordReplay();
                    await widget.recorderController.start();
                  },
                  child: const Text('Record')),
            ],
          );
        });
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
              'Temp saved:\n${widget.state.recordedTempPath}\n\nExport to device?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Later')),
            FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  widget.replayCubit.exportRecordedVideo();
                },
                child: const Text('Export to Gallery')),
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
    final isExporting =
        state.recordingStatus == ReplayRecordingStatus.exporting;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade300))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton(
              iconSize: 32,
              icon: const Icon(Icons.play_arrow),
              onPressed: state.playing || isRecording || isExporting
                  ? null
                  : () => widget.replayCubit.play()),
          const SizedBox(width: 8),
          IconButton(
              iconSize: 32,
              icon: const Icon(Icons.pause),
              onPressed:
                  state.playing ? () => widget.replayCubit.pause() : null),
          const SizedBox(width: 8),
          IconButton(
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
                isRecording
                    ? Icons.videocam
                    : isExporting
                        ? Icons.hourglass_top
                        : Icons.fiber_manual_record,
                color: isRecording ? Colors.red : null),
            label: Text(isRecording
                ? 'Recording...'
                : isExporting
                    ? 'Exporting ${_exportProgress.toInt()}%'
                    : 'Record Replay'),
            onPressed: state.playing || isRecording || isExporting
                ? null
                : () => _showRecordDialog(context),
          ),
        ]),
      ),
    );
  }
}
