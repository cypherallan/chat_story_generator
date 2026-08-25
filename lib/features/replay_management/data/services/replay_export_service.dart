import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../../presentation/cubit/conversation_replay_state.dart';

class ReplayExportService {
  Future<String> exportVideo({
    required String tempPath,
    required ReplayExportQuality quality,
  }) async {
    final tempFile = File(tempPath);
    if (!await tempFile.exists()) {
      throw Exception('Temp video not found: $tempPath');
    }

    // Ensure extension is .mp4 (widget_recorder_plus sometimes saves .mp4 anyway)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'chat_story_${timestamp}_${quality.name}.mp4';

    // 1. Request gallery permission (required for Android 13+)
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    final isAuth = ps.isAuth || ps.hasAccess;
    if (!isAuth) {
      throw Exception(
          'Gallery permission denied. Please allow Photos/Videos permission.');
    }

    // 2. Save to Movies/ChatStoryGenerator via MediaStore - THIS APPEARS IN FILE MANAGER
    // On Android, relativePath = Movies/ChatStoryGenerator will create:
    // /storage/emulated/0/Movies/ChatStoryGenerator/chat_story_xxx.mp4
    // This IS visible in Files app > Movies
    final AssetEntity? entity = await PhotoManager.editor.saveVideo(
      tempFile,
      title: fileName,
      relativePath: 'Movies/ChatStoryGenerator',
    );

    if (entity == null) {
      throw Exception('Failed to save to gallery via MediaStore');
    }

    final File? savedFile = await entity.file;
    final String finalPath =
        savedFile?.path ?? 'Gallery: Movies/ChatStoryGenerator/$fileName';

    // Verify it's playable mp4
    if (savedFile != null && await savedFile.exists()) {
      final length = await savedFile.length();
      if (length < 1000) {
        throw Exception('Exported file too small/corrupted: $length bytes');
      }
    }

    return finalPath;
  }
}
