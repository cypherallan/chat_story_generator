import 'dart:io';

import '../../domain/entities/media_item.dart';
import 'media_service.dart';

class WindowsMediaService implements MediaService {
  @override
  @override
  Future<List<MediaItem>> loadMedia() async {
    final pictures = Directory(
      "${Platform.environment['USERPROFILE']}\\Pictures",
    );

    if (!pictures.existsSync()) {
      return [];
    }

    return pictures
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          final path = file.path.toLowerCase();

          return path.endsWith('.jpg') ||
              path.endsWith('.jpeg') ||
              path.endsWith('.png') ||
              path.endsWith('.webp');
        })
        .map(
          (file) => MediaItem(
            id: file.path,
            path: file.path,
          ),
        )
        .toList();
  }
}
