import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../../presentation/cubit/conversation_replay_state.dart';

class ReplayExportService {
  Future<String> exportVideo({
    required String tempPath,
    required ReplayExportQuality quality,
    String? customFileName,
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

    // Save to Movies/ChatStoryGenerator — visible in Files app
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

    if (savedFile != null && await savedFile.exists()) {
      final length = await savedFile.length();
      if (length < 1000) {
        throw Exception('Exported file too small/corrupted: $length bytes');
      }
    }

    return finalPath;
  }
}
