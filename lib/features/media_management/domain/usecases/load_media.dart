import '../entities/media_item.dart';
import '../repositories/media_repository.dart';

class LoadMedia {
  final MediaRepository repository;

  LoadMedia(this.repository);

  Future<List<MediaItem>> call() {
    return repository.loadMedia();
  }
}
