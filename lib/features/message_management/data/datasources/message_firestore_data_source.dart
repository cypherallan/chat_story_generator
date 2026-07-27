import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message_model.dart';

abstract class MessageFirestoreDataSource {
  Stream<List<MessageModel>> getMessages(
    String projectId,
  );

  Future<MessageModel> addMessage(
    MessageModel message,
  );

  Future<void> updateMessage(
    MessageModel message,
  );

  Future<void> deleteMessage(
    String projectId,
    String messageId,
  );
}

class MessageFirestoreDataSourceImpl implements MessageFirestoreDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  MessageFirestoreDataSourceImpl(
    this.firestore,
    this.auth,
  );

  CollectionReference<Map<String, dynamic>> _messagesCollection(
    String projectId,
  ) {
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User is not signed in');
    }

    return firestore
        .collection('users')
        .doc(uid)
        .collection('projects')
        .doc(projectId)
        .collection('messages');
  }

  @override
  Stream<List<MessageModel>> getMessages(
    String projectId,
  ) {
    return _messagesCollection(projectId).orderBy('createdAt').snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => MessageModel.fromJson(
                  doc.data(),
                ),
              )
              .toList(),
        );
  }

  @override
  Future<MessageModel> addMessage(
    MessageModel message,
  ) async {
    await _messagesCollection(message.projectId).doc(message.id).set(
          message.toJson(),
        );

    return message;
  }

  @override
  Future<void> updateMessage(
    MessageModel message,
  ) async {
    await _messagesCollection(message.projectId).doc(message.id).update(
          message.toJson(),
        );
  }

  @override
  Future<void> deleteMessage(
    String projectId,
    String messageId,
  ) async {
    await _messagesCollection(projectId).doc(messageId).delete();
  }
}
