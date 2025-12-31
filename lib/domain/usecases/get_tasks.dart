import 'package:task_management/core/utils/either.dart';
import 'package:task_management/core/errors/failures.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import 'package:task_management/domain/repositories/task_repository.dart';

/// Use case for getting all tasks
/// This encapsulates the business logic for retrieving tasks
class GetTasksUseCase {

  GetTasksUseCase(this._repository);
  final TaskRepository _repository;

  /// Executes the use case
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> call() async {
    try {
      return await _repository.getTasks();
    } catch (e) {
      return Left(ServerFailure('Failed to get tasks: ${e.toString()}'));
    }
  }
}
