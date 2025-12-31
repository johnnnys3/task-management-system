import 'package:task_management/core/utils/either.dart';
import 'package:task_management/domain/entities/task_entity.dart';

/// Repository interface for task operations
/// This defines the contract for task data operations in the domain layer
abstract class TaskRepository {
  /// Gets all tasks
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getTasks();

  /// Gets a stream of all tasks for real-time updates
  /// Returns [Stream<List<TaskEntity>>] that emits lists of tasks
  Stream<List<TaskEntity>> getTasksStream();

  /// Gets a task by ID
  /// Returns [Result<TaskEntity>] with either the task or a failure
  Future<Result<TaskEntity>> getTaskById(String id);

  /// Creates a new task
  /// Returns [Result<String>] with either the task ID or a failure
  Future<Result<String>> createTask(TaskEntity task);

  /// Updates an existing task
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> updateTask(TaskEntity task);

  /// Deletes a task
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> deleteTask(String id);

  /// Gets tasks for a specific date
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getTasksForDate(DateTime date);

  /// Gets tasks for a specific date range
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getTasksForDateRange(DateTime startDate, DateTime endDate);

  /// Gets tasks for a specific project
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getTasksForProject(String projectId);

  /// Gets a stream of tasks for a specific project
  /// Returns [Stream<List<TaskEntity>>] that emits lists of tasks
  Stream<List<TaskEntity>> getTasksForProjectStream(String projectId);

  /// Gets tasks assigned to a specific user
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getTasksForUser(String userId);

  /// Gets a stream of tasks assigned to a specific user
  /// Returns [Stream<List<TaskEntity>>] that emits lists of tasks
  Stream<List<TaskEntity>> getTasksForUserStream(String userId);

  /// Searches tasks by title or description
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> searchTasks(String query);

  /// Gets tasks by status
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getTasksByStatus(String status);

  /// Gets tasks by priority
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getTasksByPriority(String priority);

  /// Gets tasks due today
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getTasksDueToday();

  /// Gets overdue tasks
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getOverdueTasks();

  /// Gets tasks due soon (within specified days)
  /// Returns [Result<List<TaskEntity>>] with either a list of tasks or a failure
  Future<Result<List<TaskEntity>>> getTasksDueSoon({int days = 3});

  /// Updates multiple tasks in a batch
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> batchUpdateTasks(List<TaskEntity> tasks);

  /// Deletes multiple tasks in a batch
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> batchDeleteTasks(List<String> taskIds);

  /// Gets task statistics
  /// Returns [Result<Map<String, int>>] with either statistics or a failure
  Future<Result<Map<String, int>>> getTaskStatistics();

  /// Gets task statistics for a specific project
  /// Returns [Result<Map<String, int>>] with either statistics or a failure
  Future<Result<Map<String, int>>> getTaskStatisticsForProject(String projectId);

  /// Gets task statistics for a specific user
  /// Returns [Result<Map<String, int>>] with either statistics or a failure
  Future<Result<Map<String, int>>> getTaskStatisticsForUser(String userId);
}
