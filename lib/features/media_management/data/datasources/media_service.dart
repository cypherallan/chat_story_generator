import '../../domain/entities/media_item.dart';

abstract class MediaService {
  Future<List<MediaItem>> loadMedia();
}
