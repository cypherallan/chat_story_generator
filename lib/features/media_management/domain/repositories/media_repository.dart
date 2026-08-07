import '../entities/media_item.dart';

abstract class MediaRepository {
  Future<List<MediaItem>> loadMedia();
}
