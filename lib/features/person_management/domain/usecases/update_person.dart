import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/person.dart';
import '../repositories/person_repository.dart';

class UpdatePerson implements UseCase<Person, Person> {
  final PersonRepository repository;

  UpdatePerson(this.repository);

  @override
  Future<Either<Failure, Person>> call(Person person) {
    return repository.updatePerson(person);
  }
}
