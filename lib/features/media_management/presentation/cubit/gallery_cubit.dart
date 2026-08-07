import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/load_media.dart';
import 'gallery_state.dart';

class GalleryCubit extends Cubit<GalleryState> {
  final LoadMedia loadMediaUseCase;

  GalleryCubit(this.loadMediaUseCase) : super(const GalleryLoading());

  Future<void> loadMedia() async {
    emit(const GalleryLoading());

    try {
      final media = await loadMediaUseCase();

      if (media.isEmpty) {
        emit(const GalleryPermissionDenied());
        return;
      }

      emit(GalleryLoaded(media));
    } catch (e) {
      emit(GalleryError(e.toString()));
    }
  }
}
