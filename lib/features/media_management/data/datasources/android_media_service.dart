import 'package:photo_manager/photo_manager.dart';

import '../../domain/entities/media_item.dart';
import 'media_service.dart';

class AndroidMediaService implements MediaService {
  @override
  Future<List<MediaItem>> loadMedia() async {
    final permission = await PhotoManager.requestPermissionExtend();

    if (!permission.isAuth) {
      return [];
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
    );

    if (albums.isEmpty) {
      return [];
    }

    final assets = await albums.first.getAssetListPaged(
      page: 0,
      size: 300,
    );

    final List<MediaItem> media = [];

    for (final asset in assets) {
      final file = await asset.file;

      if (file != null) {
        media.add(
          MediaItem(
            id: asset.id,
            path: file.path,
          ),
        );
      }
    }

    return media;
  }
}