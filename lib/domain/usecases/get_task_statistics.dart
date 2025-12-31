import 'package:task_management/core/utils/either.dart';
import 'package:task_management/core/errors/failures.dart';
import 'package:task_management/domain/repositories/task_repository.dart';

/// Use case for getting task statistics
/// This encapsulates the business logic for retrieving task statistics
class GetTaskStatisticsUseCase {

  GetTaskStatisticsUseCase(this._repository);
  final TaskRepository _repository;

  /// Executes the use case
  /// Returns [Result<Map<String, int>>] with either statistics or a failure
  Future<Result<Map<String, int>>> call() async {
    try {
      return await _repository.getTaskStatistics();
    } catch (e) {
      return Left(ServerFailure('Failed to get task statistics: ${e.toString()}'));
    }
  }
}
