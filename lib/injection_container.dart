import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'features/person_management/domain/usecases/update_person.dart';
import 'core/auth/auth_service.dart';
import 'core/storage/firebase_storage_service.dart';

import 'features/person_management/data/datasources/person_firestore_data_source.dart';
import 'features/person_management/data/repositories/person_repository_impl.dart';

import 'features/person_management/domain/repositories/person_repository.dart';
import 'features/person_management/domain/usecases/add_person.dart';
import 'features/person_management/domain/usecases/delete_person.dart';
import 'features/person_management/domain/usecases/get_persons.dart';

import 'features/person_management/presentation/cubit/person_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Firebase
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  // Services
  sl.registerLazySingleton(() => AuthService(sl()));
  sl.registerLazySingleton(() => FirebaseStorageService(sl()));

  // Data Source
  sl.registerLazySingleton<PersonFirestoreDataSource>(
    () => PersonFirestoreDataSourceImpl(sl()),
  );
  // register person
  sl.registerLazySingleton(() => UpdatePerson(sl()));

  // Repository
  sl.registerLazySingleton<PersonRepository>(
    () => PersonRepositoryImpl(sl()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetPersons(sl()));
  sl.registerLazySingleton(() => AddPerson(sl()));
  sl.registerLazySingleton(() => DeletePerson(sl()));

  // Cubit
  sl.registerFactory(
    () => PersonCubit(
      getPersons: sl(),
      addPerson: sl(),
      updatePerson: sl(),
      deletePerson: sl(),
      storageService: sl(),
    ),
  );
}
