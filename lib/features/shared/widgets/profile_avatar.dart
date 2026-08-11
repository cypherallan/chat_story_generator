import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imagePath;
  final String name;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.imagePath,
    required this.name,
    this.radius = 25,
  });

  @override
  Widget build(BuildContext context) {
    final path = imagePath?.trim();

    final fallbackLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';

    Widget fallback() {
      return CircleAvatar(
        radius: radius,
        child: Text(
          fallbackLetter,
          style: TextStyle(
            fontSize: radius * 0.8,
          ),
        ),
      );
    }

    // -------------------------------------------------------------------------
    // NO IMAGE
    // -------------------------------------------------------------------------

    if (path == null || path.isEmpty) {
      return fallback();
    }

    // -------------------------------------------------------------------------
    // NETWORK IMAGE
    // -------------------------------------------------------------------------

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: path,
        imageBuilder: (context, imageProvider) {
          return CircleAvatar(
            radius: radius,
            backgroundImage: imageProvider,
          );
        },
        placeholder: (context, url) {
          return fallback();
        },
        errorWidget: (context, url, error) {
          return fallback();
        },
      );
    }

    // -------------------------------------------------------------------------
    // LOCAL IMAGE
    // -------------------------------------------------------------------------

    final file = File(path);

    return FutureBuilder<bool>(
      future: file.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return fallback();
        }

        if (snapshot.data != true) {
          return fallback();
        }

        return CircleAvatar(
          radius: radius,
          backgroundImage: FileImage(file),
        );
      },
    );
  }
}
