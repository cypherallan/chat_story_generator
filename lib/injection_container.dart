import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/person_management/data/datasources/person_local_data_source.dart';
import 'features/person_management/data/repositories/person_repository_impl.dart';
import 'features/person_management/domain/repositories/person_repository.dart';
import 'features/person_management/domain/usecases/add_person.dart';
import 'features/person_management/domain/usecases/delete_person.dart';
import 'features/person_management/domain/usecases/get_persons.dart';
import 'features/person_management/presentation/cubit/person_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton<PersonLocalDataSource>(
    () => PersonLocalDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PersonRepository>(
    () => PersonRepositoryImpl(sl()),
  );

  sl.registerLazySingleton(() => GetPersons(sl()));
  sl.registerLazySingleton(() => AddPerson(sl()));
  sl.registerLazySingleton(() => DeletePerson(sl()));

  sl.registerFactory(
    () => PersonCubit(
      getPersons: sl(),
      addPerson: sl(),
      deletePerson: sl(),
    ),
  );
}
