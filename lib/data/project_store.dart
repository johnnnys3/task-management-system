import 'package:task_management/models/project.dart';

/// Base exception for all [ProjectStore] operations.
abstract class ProjectStoreException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  ProjectStoreException(this.message, {this.code = 'unknown', this.originalError});

  @override
  String toString() => '$runtimeType: $message';
}

class ProjectNotFoundException extends ProjectStoreException {
  ProjectNotFoundException(String projectId)
      : super('Project not found: $projectId', code: 'project-not-found');
}

class ProjectValidationException extends ProjectStoreException {
  ProjectValidationException(String message)
      : super(message, code: 'validation-error');
}

/// Single interface for all project data access, backed by whichever adapter
/// (Firestore, in-memory, ...) is registered at the app root.
abstract class ProjectStore {
  /// Creates [project], returning its assigned id.
  ///
  /// Throws [ProjectValidationException] if the project fails [Project.validate].
  Future<String> create(Project project);

  /// Updates an existing project.
  ///
  /// Throws [ProjectNotFoundException] if no project with [Project.id] exists.
  /// Throws [ProjectValidationException] if the project fails [Project.validate].
  Future<void> update(Project project);

  /// Deletes the project with the given id.
  ///
  /// Throws [ProjectNotFoundException] if no such project exists.
  Future<void> delete(String projectId);

  /// Fetches all projects.
  Future<List<Project>> fetch();

  /// Streams all projects, re-emitting the full list whenever the
  /// underlying data changes.
  Stream<List<Project>> stream();
}
