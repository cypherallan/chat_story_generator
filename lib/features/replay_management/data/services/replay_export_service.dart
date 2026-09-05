import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../presentation/cubit/conversation_replay_state.dart';

class ReplayAudioEvent {
  final String sound;
  final Duration offset;

  const ReplayAudioEvent({
    required this.sound,
    required this.offset,
  });
}

class ReplayExportService {
  Future<String> exportVideo({
    required String tempPath,
    required ReplayExportQuality quality,
    String? customFileName,
    List<ReplayAudioEvent> audioEvents = const [],
  }) async {
    final tempFile = File(tempPath);
    if (!await tempFile.exists()) {
      throw Exception('Temp video not found: $tempPath');
    }

    // Custom name handling
    String fileName = customFileName?.trim() ?? '';
    if (fileName.isEmpty) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      fileName = 'chat_story_${timestamp}_${quality.name}.mp4';
    }
    if (!fileName.toLowerCase().endsWith('.mp4')) {
      fileName = '$fileName.mp4';
    }

    // Request VIDEO permission explicitly (fixes your "Images only" bug)
    final PermissionState ps = await PhotoManager.requestPermissionExtend(
      requestOption: const PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.video,
          mediaLocation: true,
        ),
      ),
    );

    final isAuth = ps.isAuth || ps.hasAccess;
    if (!isAuth) {
      throw Exception(
          'Gallery permission denied. Please allow Videos permission in Settings > Apps > Chat Story Generator > Permissions');
    }

    final videoWithAudioPath = await _addAudioToVideo(
      videoPath: tempFile.path,
      audioEvents: audioEvents,
    );

    final videoWithAudioFile = File(videoWithAudioPath);

    if (!await videoWithAudioFile.exists()) {
      throw Exception('Audio-enhanced video was not created.');
    }

    // Save to Movies/ChatStoryGenerator — visible in Files app
    final AssetEntity? entity = await PhotoManager.editor.saveVideo(
      videoWithAudioFile,
      title: fileName,
      relativePath: 'Movies/ChatStoryGenerator',
    );

    if (entity == null) {
      throw Exception('Failed to save to gallery via MediaStore');
    }

    final File? savedFile = await entity.file;
    final String finalPath =
        savedFile?.path ?? 'Gallery: Movies/ChatStoryGenerator/$fileName';

    if (savedFile != null && await savedFile.exists()) {
      final length = await savedFile.length();
      if (length < 1000) {
        throw Exception('Exported file too small/corrupted: $length bytes');
      }
    }

    return finalPath;
  }

  Future<String> _addAudioToVideo({
    required String videoPath,
    required List<ReplayAudioEvent> audioEvents,
  }) async {
    if (audioEvents.isEmpty) {
      return videoPath;
    }

    final tempDir = await getTemporaryDirectory();

    final soundAssets = <String, String>{
      'send': 'assets/sounds/message-sent.wav',
      'receive': 'assets/sounds/incoming.aac',
      'notification': 'assets/sounds/notification.wav',
      'keyPress': 'assets/sounds/keypress.wav',
    };

    final assetPaths = <String, String>{};

    for (final entry in soundAssets.entries) {
      final extension = entry.value.split('.').last;

      final outputFile = File(
        '${tempDir.path}/chat_story_${entry.key}_sound.$extension',
      );

      final data = await rootBundle.load(entry.value);
      await outputFile.writeAsBytes(
        data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        ),
        flush: true,
      );

      assetPaths[entry.key] = outputFile.path;
    }

    final outputPath =
        '${tempDir.path}/chat_story_audio_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final inputs = <String>[
      '-i',
      _quote(videoPath),
    ];

    final filterParts = <String>[];
    final mixLabels = <String>[];

    for (var i = 0; i < audioEvents.length; i++) {
      final event = audioEvents[i];
      final soundPath = assetPaths[event.sound];

      if (soundPath == null) continue;

      inputs.addAll([
        '-i',
        _quote(soundPath),
      ]);

      final delay = max(0, event.offset.inMilliseconds - 800);

      filterParts.add(
        '[${i + 1}:a]adelay=${delay}|${delay}[a$i]',
      );

      mixLabels.add('[a$i]');
    }

    if (mixLabels.isEmpty) {
      return videoPath;
    }

    final filterComplex = '${filterParts.join(';')};'
        '${mixLabels.join()}'
        'amix=inputs=${mixLabels.length}:duration=longest:normalize=0,'
        'apad[aout]';

    final command = [
      ...inputs,
      '-filter_complex',
      _quote(filterComplex),
      '-map',
      '0:v:0',
      '-map',
      _quote('[aout]'),
      '-c:v',
      'copy',
      '-c:a',
      'aac',
      '-b:a',
      '192k',
      '-ar',
      '44100',
      '-ac',
      '2',
      '-shortest',
      '-y',
      _quote(outputPath),
    ].join(' ');

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    final logs = await session.getAllLogsAsString();

    if (!ReturnCode.isSuccess(returnCode)) {
      throw Exception(
        'FFmpeg audio mux failed.\n$logs',
      );
    }

    final outputFile = File(outputPath);

    if (!await outputFile.exists()) {
      throw Exception('FFmpeg output video was not created.');
    }

    final length = await outputFile.length();

    if (length < 1000) {
      throw Exception(
        'FFmpeg output video is too small/corrupted: $length bytes',
      );
    }

    return outputPath;
  }

  String _quote(String value) {
    return '"${value.replaceAll('"', r'\"')}"';
  }
}
