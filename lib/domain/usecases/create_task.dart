import 'package:task_management/core/utils/either.dart';
import 'package:task_management/core/errors/failures.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import 'package:task_management/domain/repositories/task_repository.dart';

/// Use case for creating a new task
/// This encapsulates the business logic for task creation
class CreateTaskUseCase {

  CreateTaskUseCase(this._repository);
  final TaskRepository _repository;

  /// Executes the use case
  /// Returns [Result<String>] with either the task ID or a failure
  Future<Result<String>> call(TaskEntity task) async {
    // Validate task data
    final validationError = _validateTask(task);
    if (validationError != null) {
      return Left(validationError);
    }

    try {
      return await _repository.createTask(task);
    } catch (e) {
      return Left(ServerFailure('Failed to create task: ${e.toString()}'));
    }
  }

  /// Validates task data
  ValidationFailure? _validateTask(TaskEntity task) {
    if (task.title.trim().isEmpty) {
      return const ValidationFailure('Task title is required');
    }
    if (task.title.trim().length < 3) {
      return const ValidationFailure('Task title must be at least 3 characters');
    }
    if (task.title.trim().length > 200) {
      return const ValidationFailure('Task title must be less than 200 characters');
    }
    if (task.description.trim().isEmpty) {
      return const ValidationFailure('Task description is required');
    }
    if (task.description.trim().length < 10) {
      return const ValidationFailure('Task description must be at least 10 characters');
    }
    if (task.description.trim().length > 1000) {
      return const ValidationFailure('Task description must be less than 1000 characters');
    }
    return null;
  }
}
