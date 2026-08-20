import 'package:flutter/material.dart';

import '../../../notification_management/domain/entities/notification.dart'
    as notification_entity;

Future<notification_entity.Notification?> showTriggerReplayNotificationSheet(
  BuildContext context,
  List<notification_entity.Notification> notifications,
) {
  return showModalBottomSheet<notification_entity.Notification>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Trigger Replay Notification',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ...notifications.map(
              (notification) {
                return ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(
                    notification.senderName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    notification.messageText.isEmpty
                        ? 'Photo'
                        : notification.messageText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop(notification);
                  },
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
