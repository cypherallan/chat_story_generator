import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

abstract class NotificationFirestoreDataSource {
  Future<List<NotificationModel>> getNotifications();

  Future<NotificationModel> addNotification(
    NotificationModel notification,
  );

  Future<void> updateNotification(
    NotificationModel notification,
  );

  Future<void> deleteNotification(
    String notificationId,
  );
}

class NotificationFirestoreDataSourceImpl
    implements NotificationFirestoreDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  NotificationFirestoreDataSourceImpl(
    this.firestore,
    this.auth,
  );

  CollectionReference<Map<String, dynamic>> _notificationsCollection() {
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User is not signed in');
    }

    return firestore.collection('users').doc(uid).collection('notifications');
  }

  @override
  Future<List<NotificationModel>> getNotifications() async {
    final snapshot = await _notificationsCollection().get();

    return snapshot.docs
        .map(
          (doc) => NotificationModel.fromJson({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();
  }

  @override
  Future<NotificationModel> addNotification(
    NotificationModel notification,
  ) async {
    await _notificationsCollection()
        .doc(notification.id)
        .set(notification.toJson());

    return notification;
  }

  @override
  Future<void> updateNotification(
    NotificationModel notification,
  ) async {
    await _notificationsCollection()
        .doc(notification.id)
        .update(notification.toJson());
  }

  @override
  Future<void> deleteNotification(
    String notificationId,
  ) async {
    await _notificationsCollection().doc(notificationId).delete();
  }
}
