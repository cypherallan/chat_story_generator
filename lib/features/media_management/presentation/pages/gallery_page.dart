import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool _loading = true;
  bool _hasPermission = false;
  List<AssetEntity> _media = [];
  AssetPathEntity? _album;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    if (Platform.isWindows) {
      setState(() {
        _hasPermission = true;
        _loading = false;
      });

      await _loadGallery();
      return;
    }

    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();

    debugPrint("Permission: ${permission.isAuth}");
    debugPrint("State: $permission");

    if (!mounted) return;

    setState(() {
      _hasPermission = permission.hasAccess;
      _loading = false;
    });

    if (_hasPermission) {
      await _loadGallery();
    }
  }

  Future<void> _loadGallery() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
    );

    if (albums.isEmpty) return;

    _album = albums.first;

    final media = await _album!.getAssetListPaged(
      page: 0,
      size: 100,
    );

    if (!mounted) return;

    setState(() {
      _media = media;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_hasPermission) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'Gallery permission denied',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Gallery"),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(2),
        itemCount: _media.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          return FutureBuilder(
            future: _media[index].thumbnailDataWithSize(
              const ThumbnailSize(300, 300),
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Container(
                  color: Colors.grey.shade900,
                );
              }

              return GestureDetector(
                onTap: () async {
                  final file = await _media[index].file;
                  Navigator.pop(context, file);
                },
                child: Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
