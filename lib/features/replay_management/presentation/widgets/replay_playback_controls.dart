import 'dart:async';
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
  BuildContext? _exportCtx;
  Timer? _timer;
  double _progress = 0;

  @override
  void didUpdateWidget(covariant ReplayPlaybackControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    // STOP removed here - view handles it only now

    final wasFinished = oldWidget.state.finished;
    final isFinished = widget.state.finished;
    final wasRecorded =
        oldWidget.state.recordingStatus == ReplayRecordingStatus.recorded;
    final isRecorded =
        widget.state.recordingStatus == ReplayRecordingStatus.recorded;

    // Case 1: normal path - status became recorded
    if (!wasRecorded && isRecorded) {
      debugPrint('[Replay] recordingStatus -> recorded, showing export dialog');
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showPostRecordDialog());
    }
    // Case 2: fallback - replay finished and we have a temp file but status didn't flip yet (race fix)
    else if (!wasFinished && isFinished && widget.state.hasRecordedVideo) {
      debugPrint(
          '[Replay] finished + hasRecordedVideo fallback, showing export dialog path=${widget.state.recordedTempPath}');
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showPostRecordDialog());
    }

    if (oldWidget.state.recordingStatus != ReplayRecordingStatus.exporting &&
        widget.state.recordingStatus == ReplayRecordingStatus.exporting) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _showExportingDialog());
    }
    if (oldWidget.state.recordingStatus != ReplayRecordingStatus.exported &&
        widget.state.recordingStatus == ReplayRecordingStatus.exported) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _closeExporting();
        _showSuccess(widget.state.exportedPath!);
      });
    }
    if (oldWidget.state.recordingStatus != ReplayRecordingStatus.failed &&
        widget.state.recordingStatus == ReplayRecordingStatus.failed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _closeExporting();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Export failed: ${widget.state.recordingError}'),
            backgroundColor: Colors.red));
      });
    }
  }

  // PLAY -> Would you like to record?
  Future<void> _showPlayOptionsDialog() async {
    await showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
              title: const Text('Replay'),
              content:
                  const Text('Would you like to record this replay as well?'),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.of(dCtx).pop();
                      widget.replayCubit.play();
                    },
                    child: const Text('No, just replay')),
                FilledButton(
                    onPressed: () {
                      Navigator.of(dCtx).pop();
                      _showQualityDialog();
                    },
                    child: const Text('Yes')),
              ],
            ));
  }

  Future<void> _showQualityDialog() async {
    ReplayExportQuality selected = widget.state.selectedQuality;
    await showDialog(
        context: context,
        builder: (dCtx) => StatefulBuilder(
            builder: (c, setS) => AlertDialog(
                  title: const Text('Record replay - Choose quality'),
                  content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: ReplayExportQuality.values
                          .map((q) => RadioListTile<ReplayExportQuality>(
                              title: Text(q.label),
                              subtitle: Text(q.resolutionNote,
                                  style: const TextStyle(fontSize: 11)),
                              value: q,
                              groupValue: selected,
                              onChanged: (v) => setS(() => selected = v!)))
                          .toList()),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(dCtx).pop(),
                        child: const Text('Cancel')),
                    FilledButton(
                        onPressed: () async {
                          Navigator.of(dCtx).pop();
                          debugPrint(
                              '[Replay] set quality $selected and startRecordReplay');
                          widget.replayCubit.setSelectedQuality(selected);
                          await widget.replayCubit.startRecordReplay();
                          if (!widget.recorderController.isRecording) {
                            debugPrint('[Replay] recorderController.start()');
                            await widget.recorderController.start();
                          }
                        },
                        child: const Text('Record & Play')),
                  ],
                )));
  }

  void _showExportingDialog() {
    _progress = 0;
    _timer?.cancel();
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dCtx) {
          _exportCtx = dCtx;
          return StatefulBuilder(builder: (c, setD) {
            _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
              if (_progress < 90) setD(() => _progress += 1.5);
            });
            return AlertDialog(
                title: const Text('Exporting video...'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  LinearProgressIndicator(value: _progress / 100),
                  const SizedBox(height: 12),
                  Text('${_progress.toStringAsFixed(0)}%'),
                ]));
          });
        });
  }

  void _closeExporting() {
    _timer?.cancel();
    if (_exportCtx != null && Navigator.of(_exportCtx!).canPop())
      Navigator.of(_exportCtx!).pop();
    _exportCtx = null;
  }

  Future<void> _showSuccess(String path) async {
    setState(() => _progress = 100);
    await showDialog(
        context: context,
        builder: (dCtx) => AlertDialog(
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
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'monospace'))),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(),
                    child: const Text('Close')),
                FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Open'),
                    onPressed: () async {
                      Navigator.of(dCtx).pop();
                      await OpenFilex.open(path);
                    })
              ],
            ));
  }

  Future<void> _showPostRecordDialog() async {
    if (!mounted) return;
    debugPrint(
        '[Replay] _showPostRecordDialog path=${widget.state.recordedTempPath}');
    final ctrl = TextEditingController(
        text:
            'chat_story_${widget.state.selectedQuality.name}_${DateTime.now().millisecondsSinceEpoch}');
    await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dCtx) => AlertDialog(
              title: const Text('Recording Completed'),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Would you like to export to gallery?'),
                    const SizedBox(height: 12),
                    Text('Temp: ${widget.state.recordedTempPath}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                    const SizedBox(height: 16),
                    const Text('Video name:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                        controller: ctrl,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            suffixText: '.mp4'),
                        autofocus: true),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dCtx).pop(),
                    child: const Text('No')),
                FilledButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Yes'),
                    onPressed: () {
                      final n = ctrl.text.trim();
                      Navigator.of(dCtx).pop();
                      widget.replayCubit.exportRecordedVideo(customFileName: n);
                    }),
              ],
            ));
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade300))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(
                iconSize: 32,
                icon: const Icon(Icons.play_arrow),
                onPressed: s.playing || isRec || isExp
                    ? null
                    : () => _showPlayOptionsDialog()),
            const SizedBox(width: 8),
            IconButton(
                iconSize: 32,
                icon: const Icon(Icons.pause),
                onPressed: s.playing ? () => widget.replayCubit.pause() : null),
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
                    isRec
                        ? Icons.videocam
                        : isExp
                            ? Icons.hourglass_top
                            : Icons.fiber_manual_record,
                    color: isRec ? Colors.red : null),
                label: Text(isRec
                    ? 'Recording...'
                    : isExp
                        ? 'Exporting ${_progress.toInt()}%'
                        : 'Record Replay'),
                onPressed: s.playing || isRec || isExp
                    ? null
                    : () => _showQualityDialog()),
          ]),
        ));
  }
}
