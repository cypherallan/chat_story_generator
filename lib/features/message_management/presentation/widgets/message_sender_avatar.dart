import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../person_management/domain/entities/person.dart';

class MessageSenderAvatar extends StatelessWidget {
  final Person sender;
  final bool isFirstInGroup;

  const MessageSenderAvatar({
    super.key,
    required this.sender,
    required this.isFirstInGroup,
  });

  ImageProvider? _getAvatarImage() {
    final avatarPath = sender.avatarPath;

    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }

    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return CachedNetworkImageProvider(avatarPath);
    }

    try {
      final file = File(avatarPath);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!isFirstInGroup) {
      return const SizedBox(width: 42);
    }

    final avatarImage = _getAvatarImage();

    return SizedBox(
      width: 42,
      child: CircleAvatar(
        radius: 16,
        backgroundImage: avatarImage,
        child: avatarImage == null
            ? Text(
                sender.name.isNotEmpty ? sender.name[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 13),
              )
            : null,
      ),
    );
  }
}
