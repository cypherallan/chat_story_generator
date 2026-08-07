import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'image_preview_page.dart';
import '../cubit/gallery_cubit.dart';
import '../cubit/gallery_state.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  @override
  void initState() {
    super.initState();

    context.read<GalleryCubit>().loadMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Gallery"),
      ),
      body: BlocBuilder<GalleryCubit, GalleryState>(
        builder: (context, state) {
          if (state is GalleryLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is GalleryPermissionDenied) {
            return const Center(
              child: Text(
                'Gallery permission denied',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (state is GalleryError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (state is GalleryLoaded) {
            return GridView.builder(
              padding: const EdgeInsets.all(2),
              itemCount: state.media.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                final media = state.media[index];

                return GestureDetector(
                  onTap: () async {
                    final File? selectedImage = await Navigator.push<File>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImagePreviewPage(
                          image: File(media.path),
                        ),
                      ),
                    );

                    if (selectedImage != null && context.mounted) {
                      Navigator.pop(context, selectedImage);
                    }
                  },
                  child: Image.file(
                    File(media.path),
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
