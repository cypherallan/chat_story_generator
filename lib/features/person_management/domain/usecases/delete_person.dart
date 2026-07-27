import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/person_repository.dart';

class DeletePerson implements UseCase<void, String> {
  final PersonRepository repository;
  DeletePerson(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) async {
    return await repository.deletePerson(id);
  }
}
