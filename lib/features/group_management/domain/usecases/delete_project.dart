import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/project_repository.dart';

class DeleteProject {
  final ProjectRepository repository;

  DeleteProject(this.repository);

  Future<Either<Failure, void>> call(
    String id,
  ) async {
    return await repository.deleteProject(id);
  }
}
