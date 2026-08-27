import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/project_model.dart';

abstract class ProjectFirestoreDataSource {
  Future<List<ProjectModel>> getProjects();

  Future<ProjectModel> addProject(
    ProjectModel project,
  );

  Future<ProjectModel> updateProject(
    ProjectModel project,
  );

  Future<void> deleteProject(
    String id,
  );

  Future<void> deleteProjects(
    List<String> ids,
  );
}

class ProjectFirestoreDataSourceImpl implements ProjectFirestoreDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ProjectFirestoreDataSourceImpl(
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
  Future<List<ProjectModel>> getProjects() async {
    final snapshot = await _projectsCollection.get();

    return snapshot.docs
        .map(
          (doc) => ProjectModel.fromJson(
            doc.data(),
          ),
        )
        .toList();
  }

  @override
  Future<ProjectModel> addProject(
    ProjectModel project,
  ) async {
    await _projectsCollection.doc(project.id).set(
          project.toJson(),
        );

    return project;
  }

  @override
  Future<ProjectModel> updateProject(
    ProjectModel project,
  ) async {
    await _projectsCollection.doc(project.id).update(
          project.toJson(),
        );

    return project;
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
