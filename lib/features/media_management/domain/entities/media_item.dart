class MediaItem {
  final String id;
  final String path;
  final bool isVideo;

  const MediaItem({
    required this.id,
    required this.path,
    this.isVideo = false,
  });
}
