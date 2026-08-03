import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/person.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onMessage;

  final bool showAddButton;
  final VoidCallback? onAdd;

  const PersonCard({
    super.key,
    required this.person,
    required this.onDelete,
    required this.onEdit,
    required this.onMessage,
    this.showAddButton = false,
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;

    if (person.avatarPath == null || person.avatarPath!.isEmpty) {
      avatar = CircleAvatar(
        child: Text(person.name[0].toUpperCase()),
      );
    } else if (person.avatarPath!.startsWith('http')) {
      avatar = CachedNetworkImage(
        imageUrl: person.avatarPath!,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => const CircleAvatar(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        errorWidget: (context, url, error) => CircleAvatar(
          child: Text(person.name[0].toUpperCase()),
        ),
      );
    } else {
      avatar = CircleAvatar(
        backgroundImage: FileImage(
          File(person.avatarPath!),
        ),
      );
    }

    return InkWell(
      onTap: onEdit,
      onLongPress: onDelete,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: avatar,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          person.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (showAddButton)
                        TextButton(
                          onPressed: onAdd,
                          child: const Text("Add"),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: onMessage,
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.message_outlined,
                                size: 18,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      if (person.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.verified,
                            color: Colors.blue,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    person.bio?.isNotEmpty == true
                        ? person.bio!
                        : "Hey there! I am using Chat Story Generator.",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
