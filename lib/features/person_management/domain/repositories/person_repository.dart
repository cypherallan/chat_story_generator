import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/person.dart';

abstract class PersonRepository {
  Future<Either<Failure, List<Person>>> getPersons();
  Future<Either<Failure, Person>> addPerson(Person person);
  Future<Either<Failure, void>> deletePerson(String id);
}
