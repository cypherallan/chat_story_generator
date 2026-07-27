import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_firestore_data_source.dart';
import '../models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectFirestoreDataSource firestoreDataSource;

  ProjectRepositoryImpl(
    this.firestoreDataSource,
  );

  @override
  Future<Either<Failure, List<Project>>> getProjects() async {
    try {
      final projects = await firestoreDataSource.getProjects();

      return Right(projects);
    } catch (e) {
      return Left(
        CacheFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, Project>> addProject(
    Project project,
  ) async {
    try {
      final model = ProjectModel.fromEntity(project);

      final result = await firestoreDataSource.addProject(model);

      return Right(result);
    } catch (e) {
      return Left(
        CacheFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteProject(
    String id,
  ) async {
    try {
      await firestoreDataSource.deleteProject(id);

      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure(e.toString()),
      );
    }
  }

  @override
  Future<Either<Failure, Project>> updateProject(
    Project project,
  ) async {
    try {
      final model = ProjectModel.fromEntity(project);

      final result = await firestoreDataSource.updateProject(model);

      return Right(result);
    } catch (e) {
      return Left(
        CacheFailure(e.toString()),
      );
    }
  }
}
