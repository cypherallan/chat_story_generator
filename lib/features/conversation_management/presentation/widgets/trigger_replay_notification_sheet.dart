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

  // NEWEST FIRST - using real createdAt
  List<notification_entity.Notification> sorted = List.from(notifications)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  final Map<String, List<notification_entity.Notification>> grouped = {};
  for (var n in sorted) {
    grouped.putIfAbsent(n.projectId, () => []).add(n);
  }

  final folderIds = grouped.keys.toList();

  return showModalBottomSheet<notification_entity.Notification>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) {
          return SafeArea(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                Center(
                    child: Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10)))),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Text('Trigger Replay Notification',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                ...folderIds.map((projectId) {
                  final list = grouped[projectId]!;
                  final group = isGroup(projectId);
                  final pName = projectName(projectId);
                  final folderTitle =
                      group && pName.isNotEmpty ? pName : list.first.senderName;

                  if (list.length == 1) {
                    final n = list.first;
                    return ListTile(
                      leading: Icon(
                          group
                              ? Icons.folder_special_outlined
                              : Icons.person_outline,
                          color: group ? const Color(0xFF25D366) : null),
                      title: Text(folderTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          n.messageText.isEmpty ? 'Photo' : n.messageText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      onTap: () => Navigator.of(sheetContext).pop(n),
                    );
                  }

                  return Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Stack(
                        children: [
                          Icon(Icons.folder_outlined,
                              color: group
                                  ? const Color(0xFF25D366)
                                  : Colors.grey[700]),
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                  color: const Color(0xFF25D366),
                                  borderRadius: BorderRadius.circular(10)),
                              child: Text('${list.length}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      title: Text(folderTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${list.length} notifications - newest first',
                          style: const TextStyle(fontSize: 12)),
                      children: list.map((n) {
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.only(left: 72, right: 20),
                          title: group
                              ? Text(n.senderName,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF25D366),
                                      fontWeight: FontWeight.w600))
                              : null,
                          subtitle: Text(
                              n.messageText.isEmpty ? 'Photo' : n.messageText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          onTap: () => Navigator.of(sheetContext).pop(n),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );
    },
  );
}
