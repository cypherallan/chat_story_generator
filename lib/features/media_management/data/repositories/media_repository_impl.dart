import '../../domain/entities/media_item.dart';
import '../../domain/repositories/media_repository.dart';
import '../datasources/media_service.dart';

class MediaRepositoryImpl implements MediaRepository {
  final MediaService mediaService;

  MediaRepositoryImpl(this.mediaService);

  @override
  Future<List<MediaItem>> loadMedia() {
    return mediaService.loadMedia();
  }
}
