import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/person.dart';
import '../../domain/repositories/person_repository.dart';
import '../datasources/person_local_data_source.dart';
import '../models/person_model.dart';

class PersonRepositoryImpl implements PersonRepository {
  final PersonLocalDataSource localDataSource;

  PersonRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, List<Person>>> getPersons() async {
    try {
      final persons = await localDataSource.getPersons();
      return Right(persons);
    } catch (e) {
      return Left(CacheFailure('Failed to load persons: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Person>> addPerson(Person person) async {
    try {
      final model = PersonModel.fromEntity(person);
      final result = await localDataSource.addPerson(model);
      return Right(result);
    } catch (e) {
      return Left(CacheFailure('Failed to add person: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deletePerson(String id) async {
    try {
      await localDataSource.deletePerson(id);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure('Failed to delete person: ${e.toString()}'));
    }
  }
}
