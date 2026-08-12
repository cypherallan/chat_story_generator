import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MessageImageContent extends StatelessWidget {
  final String imagePath;
  final String text;
  final bool isDeleted;

  const MessageImageContent({
    super.key,
    required this.imagePath,
    required this.text,
    required this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: imagePath.startsWith('http')
              ? CachedNetworkImage(
                  imageUrl: imagePath,
                  width: 250,
                  fit: BoxFit.cover,
                  memCacheWidth: 750,
                  maxWidthDiskCache: 750,
                  placeholder: (context, url) => Container(
                    width: 250,
                    height: 250,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 250,
                    height: 250,
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                    ),
                  ),
                )
              : Image.file(
                  File(imagePath),
                  width: 250,
                  cacheWidth: 750,
                  fit: BoxFit.cover,
                ),
        ),
        if (text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
              top: 6,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.3,
                color: isDeleted ? Colors.grey : Colors.black87,
                fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
      ],
    );
  }
}
