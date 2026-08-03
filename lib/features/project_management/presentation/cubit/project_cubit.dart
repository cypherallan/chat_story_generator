import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/project.dart';
import '../../domain/usecases/add_project.dart';
import '../../domain/usecases/delete_project.dart';
import '../../domain/usecases/delete_projects.dart';
import '../../domain/usecases/get_projects.dart';
import '../../domain/usecases/update_project.dart';

part 'project_state.dart';

class ProjectCubit extends Cubit<ProjectState> {
  final GetProjects getProjects;
  final AddProject addProject;
  final UpdateProject updateProject;
  final DeleteProject deleteProject;
  final DeleteProjects deleteProjects;

  ProjectCubit({
    required this.getProjects,
    required this.addProject,
    required this.updateProject,
    required this.deleteProject,
    required this.deleteProjects,
  }) : super(ProjectInitial());

  Future<void> loadProjects() async {
    emit(ProjectLoading());

    final result = await getProjects();

    result.fold(
      (failure) => emit(ProjectError(failure.message)),
      (projects) => emit(ProjectLoaded(projects)),
    );
  }

  Future<void> createProject({
    required String title,
    required String ownerId,
    required List<String> participants,
    String? groupImagePath,
  }) async {
    emit(ProjectLoading());

    final project = Project(
      id: const Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
      ownerId: ownerId,
      participantIds: participants,
      groupImagePath: groupImagePath,
    );

    final result = await addProject(project);

    result.fold(
      (failure) => emit(ProjectError(failure.message)),
      (_) async {
        emit(ProjectSaved());
        await loadProjects();
      },
    );
  }

  Future<Project> openOrCreatePrivateChat({
    required String ownerId,
    required String contactId,
    required String contactName,
  }) async {
    final result = await getProjects();

    return await result.fold(
      (_) async {
        throw Exception("Unable to load chats");
      },
      (projects) async {
        for (final project in projects) {
          if (project.ownerId != ownerId) continue;

          if (project.participantIds.length != 2) continue;

          final containsOwner = project.participantIds.contains(ownerId);
          final containsContact = project.participantIds.contains(contactId);

          if (containsOwner && containsContact) {
            return project;
          }
        }

        final project = Project(
          id: const Uuid().v4(),
          title: contactName,
          createdAt: DateTime.now(),
          ownerId: ownerId,
          participantIds: [
            ownerId,
            contactId,
          ],
        );

        final save = await addProject(project);

        return save.fold(
          (_) => throw Exception("Unable to create chat"),
          (_) => project,
        );
      },
    );
  }

  Future<void> editProject(Project project) async {
    emit(ProjectLoading());

    final result = await updateProject(project);

    result.fold(
      (failure) => emit(ProjectError(failure.message)),
      (_) async {
        emit(ProjectSaved());
        await loadProjects();
      },
    );
  }

  Future<void> removeProject(String id) async {
    emit(ProjectLoading());

    final result = await deleteProject(id);

    result.fold(
      (failure) => emit(ProjectError(failure.message)),
      (_) => loadProjects(),
    );
  }

  Future<void> removeProjects(
    List<String> ids,
  ) async {
    emit(ProjectLoading());

    final result = await deleteProjects(ids);

    result.fold(
      (failure) => emit(ProjectError(failure.message)),
      (_) => loadProjects(),
    );
  }
}
