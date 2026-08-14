import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/replay_notification_model.dart';

abstract class ReplayNotificationFirestoreDataSource {
  Future<List<ReplayNotificationModel>> getNotifications();

  Future<ReplayNotificationModel> addNotification(
    ReplayNotificationModel notification,
  );

  Future<ReplayNotificationModel> updateNotification(
    ReplayNotificationModel notification,
  );

  Future<void> deleteNotification(
    String id,
  );

  Future<void> deleteNotifications(
    List<String> ids,
  );
}

class ReplayNotificationFirestoreDataSourceImpl
    implements ReplayNotificationFirestoreDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ReplayNotificationFirestoreDataSourceImpl(
    this.firestore,
    this.auth,
  );

  CollectionReference<Map<String, dynamic>> get _notificationsCollection {
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User is not signed in');
    }

    return firestore
        .collection('users')
        .doc(uid)
        .collection('replay_notifications');
  }

  @override
  Future<List<ReplayNotificationModel>> getNotifications() async {
    final snapshot = await _notificationsCollection.get();

    return snapshot.docs
        .map(
          (doc) => ReplayNotificationModel.fromJson(
            doc.data(),
          ),
        )
        .toList();
  }

  @override
  Future<ReplayNotificationModel> addNotification(
    ReplayNotificationModel notification,
  ) async {
    await _notificationsCollection
        .doc(notification.id)
        .set(notification.toJson());

    return notification;
  }

  @override
  Future<ReplayNotificationModel> updateNotification(
    ReplayNotificationModel notification,
  ) async {
    await _notificationsCollection
        .doc(notification.id)
        .update(notification.toJson());

    return notification;
  }

  @override
  Future<void> deleteNotification(
    String id,
  ) async {
    await _notificationsCollection.doc(id).delete();
  }

  @override
  Future<void> deleteNotifications(
    List<String> ids,
  ) async {
    final batch = firestore.batch();

    for (final id in ids) {
      batch.delete(
        _notificationsCollection.doc(id),
      );
    }

    await batch.commit();
  }
}
