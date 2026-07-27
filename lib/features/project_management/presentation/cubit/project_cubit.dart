import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/project.dart';
import '../../domain/usecases/add_project.dart';
import '../../domain/usecases/delete_project.dart';
import '../../domain/usecases/get_projects.dart';
import '../../domain/usecases/update_project.dart';

part 'project_state.dart';

class ProjectCubit extends Cubit<ProjectState> {
  final GetProjects getProjects;
  final AddProject addProject;
  final UpdateProject updateProject;
  final DeleteProject deleteProject;

  ProjectCubit({
    required this.getProjects,
    required this.addProject,
    required this.updateProject,
    required this.deleteProject,
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
  }) async {
    emit(ProjectLoading());

    final project = Project(
      id: const Uuid().v4(),
      title: title,
      createdAt: DateTime.now(),
      ownerId: ownerId,
      participantIds: participants,
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
}
