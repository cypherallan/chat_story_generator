import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/project.dart';
import '../repositories/project_repository.dart';

class AddProject implements UseCase<Project, Project> {
  final ProjectRepository repository;

  AddProject(this.repository);

  @override
  Future<Either<Failure, Project>> call(Project project) async {
    return await repository.addProject(project);
  }
}
