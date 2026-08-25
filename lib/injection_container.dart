import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'features/person_management/domain/usecases/update_person.dart';
import 'core/auth/auth_service.dart';
import 'core/storage/firebase_storage_service.dart';
import 'features/replay_management/presentation/cubit/conversation_replay_cubit.dart';
import 'features/person_management/data/datasources/person_firestore_data_source.dart';
import 'features/person_management/data/repositories/person_repository_impl.dart';

import 'features/person_management/domain/repositories/person_repository.dart';
import 'features/person_management/domain/usecases/add_person.dart';
import 'features/person_management/domain/usecases/delete_person.dart';
import 'features/person_management/domain/usecases/get_persons.dart';
import 'features/notification_management/presentation/cubit/simulated_notification_cubit.dart';
import 'features/person_management/presentation/cubit/person_cubit.dart';

import 'features/project_management/data/datasources/project_firestore_data_source.dart';
import 'features/project_management/data/repositories/project_repository_impl.dart';

import 'features/project_management/domain/repositories/project_repository.dart';

import 'features/project_management/domain/usecases/add_project.dart';
import 'features/project_management/domain/usecases/get_projects.dart';
import 'features/project_management/domain/usecases/delete_project.dart';
import 'features/project_management/domain/usecases/update_project.dart';

import 'features/project_management/presentation/cubit/project_cubit.dart';

import 'features/message_management/data/datasources/message_firestore_data_source.dart';
import 'features/message_management/data/repositories/message_repository_impl.dart';

import 'features/message_management/domain/repositories/message_repository.dart';

import 'features/message_management/domain/usecases/add_message.dart';
import 'features/message_management/domain/usecases/get_messages.dart';
import 'features/message_management/domain/usecases/update_message.dart';
import 'features/message_management/domain/usecases/delete_message.dart';

import 'features/message_management/presentation/cubit/message_cubit.dart';
import 'features/project_management/domain/usecases/delete_projects.dart';

import 'features/notification_management/data/datasources/notification_firestore_data_source.dart';

import 'features/notification_management/data/repositories/notification_repository_impl.dart';

import 'features/notification_management/domain/repositories/notification_repository.dart';
import 'features/notification_management/domain/usecases/add_notification.dart';
import 'features/notification_management/domain/usecases/delete_notification.dart';
import 'features/notification_management/domain/usecases/get_notifications.dart';
import 'features/notification_management/domain/usecases/update_notification.dart';
import 'features/notification_management/domain/usecases/get_recorded_notification_events.dart';
import 'features/notification_management/domain/usecases/save_recorded_notification_events.dart';
import 'features/replay_management/data/services/replay_export_service.dart';
import 'features/notification_management/presentation/cubit/notification_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Firebase
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);

  // Services
  sl.registerLazySingleton(() => AuthService(sl()));
  sl.registerLazySingleton(() => FirebaseStorageService(sl()));
  sl.registerLazySingleton(() => ReplayExportService());

  // Data Source
  sl.registerLazySingleton<PersonFirestoreDataSource>(
    () => PersonFirestoreDataSourceImpl(sl()),
  );

  sl.registerLazySingleton<ProjectFirestoreDataSource>(
    () => ProjectFirestoreDataSourceImpl(
      sl(),
      sl(),
    ),
  );

  sl.registerLazySingleton<MessageFirestoreDataSource>(
    () => MessageFirestoreDataSourceImpl(
      sl(),
      sl(),
    ),
  );

  sl.registerLazySingleton<NotificationFirestoreDataSource>(
    () => NotificationFirestoreDataSourceImpl(
      sl(),
      sl(),
    ),
  );

  // register person
  sl.registerLazySingleton(() => UpdatePerson(sl()));

  // Repository
  sl.registerLazySingleton<PersonRepository>(
    () => PersonRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<ProjectRepository>(
    () => ProjectRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(
      sl(),
    ),
  );

  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      sl(),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetPersons(sl()));
  sl.registerLazySingleton(() => AddPerson(sl()));
  sl.registerLazySingleton(() => DeletePerson(sl()));

  sl.registerLazySingleton(() => GetProjects(sl()));
  sl.registerLazySingleton(() => AddProject(sl()));
  sl.registerLazySingleton(() => UpdateProject(sl()));
  sl.registerLazySingleton(() => DeleteProject(sl()));
  sl.registerLazySingleton(() => DeleteProjects(sl()));

  sl.registerLazySingleton(() => GetMessages(sl()));
  sl.registerLazySingleton(() => AddMessage(sl()));
  sl.registerLazySingleton(() => UpdateMessage(sl()));
  sl.registerLazySingleton(() => DeleteMessage(sl()));

  sl.registerLazySingleton(
    () => GetNotifications(
      sl(),
    ),
  );

  sl.registerLazySingleton(
    () => GetRecordedNotificationEvents(
      sl(),
    ),
  );

  sl.registerLazySingleton(
    () => SaveRecordedNotificationEvents(
      sl(),
    ),
  );

  sl.registerLazySingleton(
    () => AddNotification(
      sl(),
    ),
  );

  sl.registerLazySingleton(
    () => UpdateNotification(
      sl(),
    ),
  );

  sl.registerLazySingleton(
    () => DeleteNotification(
      sl(),
    ),
  );

  // Cubit
  // Person Cubit
  sl.registerFactory(
    () => PersonCubit(
      getPersons: sl(),
      addPerson: sl(),
      updatePerson: sl(),
      deletePerson: sl(),
      storageService: sl(),
    ),
  );

  // Project Cubit
  sl.registerFactory(
    () => ProjectCubit(
      getProjects: sl(),
      addProject: sl(),
      updateProject: sl(),
      deleteProject: sl(),
      deleteProjects: sl(),
    ),
  );

  // Message Cubit
  sl.registerFactory(
    () => MessageCubit(
      getMessages: sl(),
      addMessage: sl(),
      updateMessage: sl(),
      deleteMessage: sl(),
      getProjects: sl(),
      updateProject: sl(),
      storageService: sl(),
    ),
  );

  // Conversation Replay Cubit
   // Conversation Replay Cubit
  sl.registerFactory(
    () => ConversationReplayCubit(
      notificationCubit: sl<SimulatedNotificationCubit>(),
      getMessages: sl<GetMessages>(),
      getProjects: sl<GetProjects>(),
      getNotifications: sl<GetNotifications>(),
      getRecordedNotificationEvents: sl<GetRecordedNotificationEvents>(),
      saveRecordedNotificationEvents: sl<SaveRecordedNotificationEvents>(),
      exportService: sl<ReplayExportService>(),
    ),
  );

  sl.registerLazySingleton(
    () => SimulatedNotificationCubit(
      saveRecordedNotificationEvents: sl<SaveRecordedNotificationEvents>(),
      getRecordedNotificationEvents: sl<GetRecordedNotificationEvents>(),
    ),
  );

  sl.registerFactory(
    () => NotificationCubit(
      getNotifications: sl(),
      addNotification: sl(),
      updateNotificationUseCase: sl(),
      deleteNotification: sl(),
      simulatedNotificationCubit: sl<SimulatedNotificationCubit>(),
    ),
  );
}
