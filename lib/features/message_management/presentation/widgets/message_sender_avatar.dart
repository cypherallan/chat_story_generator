import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../person_management/domain/entities/person.dart';

class MessageSenderAvatar extends StatelessWidget {
  final Person sender;
  final bool isLastInGroup;

  const MessageSenderAvatar({
    super.key,
    required this.sender,
    required this.isLastInGroup,
  });

  ImageProvider? _getAvatarImage() {
    final avatarPath = sender.avatarPath;

    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }

    if (avatarPath.startsWith('http://') || avatarPath.startsWith('https://')) {
      return CachedNetworkImageProvider(avatarPath);
    }

    // Local Windows/device paths are intentionally not loaded here.
    // They are not valid network URLs.
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final avatarImage = _getAvatarImage();

    return SizedBox(
      width: 42,
      child: isLastInGroup
          ? CircleAvatar(
              radius: 16,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? Text(
                      sender.name.isNotEmpty
                          ? sender.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontSize: 13),
                    )
                  : null,
            )
          : null,
    );
  }
}
