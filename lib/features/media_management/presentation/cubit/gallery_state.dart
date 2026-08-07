import '../../domain/entities/media_item.dart';

abstract class GalleryState {
  const GalleryState();
}

class GalleryLoading extends GalleryState {
  const GalleryLoading();
}

class GalleryLoaded extends GalleryState {
  final List<MediaItem> media;

  const GalleryLoaded(this.media);
}

class GalleryPermissionDenied extends GalleryState {
  const GalleryPermissionDenied();
}

class GalleryError extends GalleryState {
  final String message;

  const GalleryError(this.message);
}
