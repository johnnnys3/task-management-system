import 'package:task_management/models/task.dart';

/// Base exception for all [TaskStore] operations.
abstract class TaskStoreException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  TaskStoreException(this.message, {this.code = 'unknown', this.originalError});

  @override
  String toString() => '$runtimeType: $message';
}

class TaskNotFoundException extends TaskStoreException {
  TaskNotFoundException(String taskId)
      : super('Task not found: $taskId', code: 'task-not-found');
}

class TaskValidationException extends TaskStoreException {
  TaskValidationException(String message)
      : super(message, code: 'validation-error');
}

/// Single interface for all task data access, backed by whichever adapter
/// (Firestore, in-memory, ...) is registered at the app root.
abstract class TaskStore {
  /// Creates [task], returning its assigned id.
  ///
  /// Throws [TaskValidationException] if the task fails [Task.validate].
  Future<String> create(Task task);

  /// Updates an existing task.
  ///
  /// Throws [TaskNotFoundException] if no task with [Task.id] exists.
  /// Throws [TaskValidationException] if the task fails [Task.validate].
  Future<void> update(Task task);

  /// Deletes the task with the given id.
  ///
  /// Throws [TaskNotFoundException] if no such task exists.
  Future<void> delete(String taskId);

  /// Fetches tasks matching all of the given (optional) filters.
  Future<List<Task>> fetch({
    String? userId,
    String? projectId,
    TaskStatus? status,
    DateTime? date,
    DateTime? dueDate,
    String? searchQuery,
  });

  /// Streams tasks matching all of the given (optional) filters, re-emitting
  /// the full matching list whenever the underlying data changes.
  Stream<List<Task>> stream({
    String? userId,
    String? projectId,
    TaskStatus? status,
    DateTime? date,
    DateTime? dueDate,
    String? searchQuery,
  });
}
