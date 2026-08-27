import 'package:flutter/material.dart';
import '../../../group_management/domain/entities/project.dart';
import '../../../notification_management/domain/entities/notification.dart'
    as notification_entity;

Future<notification_entity.Notification?> showTriggerReplayNotificationSheet(
  BuildContext context,
  List<notification_entity.Notification> notifications,
  List<Project> projects,
) {
  bool isGroup(String projectId) {
    try {
      return projects
              .firstWhere((p) => p.id == projectId)
              .participantIds
              .length >
          2;
    } catch (_) {
      return false;
    }
  }

  String projectName(String projectId) {
    try {
      return projects.firstWhere((p) => p.id == projectId).title;
    } catch (_) {
      return '';
    }
  }

  return showModalBottomSheet<notification_entity.Notification>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Trigger Replay Notification',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            ...notifications.map((notification) {
              final group = isGroup(notification.projectId);
              final pName = projectName(notification.projectId);

              return ListTile(
                leading: Icon(
                    group ? Icons.group_outlined : Icons.person_outline,
                    color: group ? const Color(0xFF25D366) : null),
                title: Text(
                  group && pName.isNotEmpty ? pName : notification.senderName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (group)
                      Text(
                        notification.senderName,
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF25D366),
                            fontWeight: FontWeight.w600),
                      ),
                    if (group) const SizedBox(height: 2),
                    Text(
                      notification.messageText.isEmpty
                          ? 'Photo'
                          : notification.messageText,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                isThreeLine: group,
                onTap: () => Navigator.of(sheetContext).pop(notification),
              );
            }),
          ],
        ),
      );
    },
  );
}
