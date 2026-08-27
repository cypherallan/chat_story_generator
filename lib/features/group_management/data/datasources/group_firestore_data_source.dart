import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group_model.dart';

abstract class GroupFirestoreDataSource {
  Future<List<GroupModel>> getProjects();

  Future<GroupModel> addProject(
    GroupModel project,
  );

  Future<GroupModel> updateProject(
    GroupModel project,
  );

  Future<void> deleteProject(
    String id,
  );

  Future<void> deleteProjects(
    List<String> ids,
  );
}

class GroupFirestoreDataSourceImpl implements GroupFirestoreDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  GroupFirestoreDataSourceImpl(
    this.firestore,
    this.auth,
  );

  CollectionReference<Map<String, dynamic>> get _projectsCollection {
    final uid = auth.currentUser?.uid;

    if (uid == null) {
      throw Exception('User is not signed in');
    }

    return firestore.collection('users').doc(uid).collection('projects');
  }

  @override
  Future<List<GroupModel>> getProjects() async {
    final snapshot = await _projectsCollection.get();

    return snapshot.docs
        .map(
          (doc) => GroupModel.fromJson(
            doc.data(),
          ),
        )
        .toList();
  }

  @override
  Future<GroupModel> addProject(
    GroupModel project,
  ) async {
    await _projectsCollection.doc(project.id).set(
          project.toJson(),
        );

    return project;
  }

  @override
  Future<GroupModel> updateProject(
    GroupModel project,
  ) async {
    try {
      await _projectsCollection.doc(project.id).set(
            project.toJson(),
            SetOptions(merge: true),
          );
      return project;
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }

  @override
  Future<void> deleteProject(
    String id,
  ) async {
    await deleteProjects([id]);
  }

  @override
  Future<void> deleteProjects(
    List<String> ids,
  ) async {
    final batch = firestore.batch();

    for (final id in ids) {
      final projectRef = _projectsCollection.doc(id);

      final messages = await projectRef.collection('messages').get();

      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(projectRef);
    }

    await batch.commit();
  }
}
