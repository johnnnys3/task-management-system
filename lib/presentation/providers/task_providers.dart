import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import 'package:task_management/domain/repositories/task_repository.dart';
import 'package:task_management/domain/usecases/get_tasks.dart';
import 'package:task_management/domain/usecases/create_task.dart';
import 'package:task_management/domain/usecases/get_tasks_for_today.dart';
import 'package:task_management/domain/usecases/get_task_statistics.dart';
import 'package:task_management/core/di/injection_container.dart' as di;

/// Provider for TaskRepository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return di.getIt<TaskRepository>();
});

/// Provider for GetTasksUseCase
final getTasksUseCaseProvider = Provider<GetTasksUseCase>((ref) {
  return GetTasksUseCase(ref.watch(taskRepositoryProvider));
});

/// Provider for CreateTaskUseCase
final createTaskUseCaseProvider = Provider<CreateTaskUseCase>((ref) {
  return CreateTaskUseCase(ref.watch(taskRepositoryProvider));
});

/// Provider for GetTasksForTodayUseCase
final getTasksForTodayUseCaseProvider = Provider<GetTasksForTodayUseCase>((ref) {
  return GetTasksForTodayUseCase(ref.watch(taskRepositoryProvider));
});

/// Provider for GetTaskStatisticsUseCase
final getTaskStatisticsUseCaseProvider = Provider<GetTaskStatisticsUseCase>((ref) {
  return GetTaskStatisticsUseCase(ref.watch(taskRepositoryProvider));
});

/// Provider for all tasks state
final tasksProvider = StateNotifierProvider<TasksNotifier, AsyncValue<List<TaskEntity>>>((ref) {
  return TasksNotifier(ref.watch(getTasksUseCaseProvider));
});

/// Provider for today's tasks state
final todaysTasksProvider = StateNotifierProvider<TodaysTasksNotifier, AsyncValue<List<TaskEntity>>>((ref) {
  return TodaysTasksNotifier(ref.watch(getTasksForTodayUseCaseProvider));
});

/// Provider for task statistics state
final taskStatisticsProvider = StateNotifierProvider<TaskStatisticsNotifier, AsyncValue<Map<String, int>>>((ref) {
  return TaskStatisticsNotifier(ref.watch(getTaskStatisticsUseCaseProvider));
});

/// State notifier for managing tasks
class TasksNotifier extends StateNotifier<AsyncValue<List<TaskEntity>>> {

  TasksNotifier(this._getTasksUseCase) : super(const AsyncValue.loading()) {
    _loadTasks();
  }
  final GetTasksUseCase _getTasksUseCase;

  /// Loads all tasks
  Future<void> _loadTasks() async {
    state = const AsyncValue.loading();
    
    final result = await _getTasksUseCase();
    
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (tasks) => AsyncValue.data(tasks),
    );
  }

  /// Refreshes tasks
  Future<void> refresh() async {
    await _loadTasks();
  }

  /// Creates a new task
  Future<void> createTask(TaskEntity task) async {
    // This would need CreateTaskUseCase
    // For now, we'll just refresh the list
    await refresh();
  }
}

/// State notifier for managing today's tasks
class TodaysTasksNotifier extends StateNotifier<AsyncValue<List<TaskEntity>>> {

  TodaysTasksNotifier(this._getTasksForTodayUseCase) : super(const AsyncValue.loading()) {
    _loadTodaysTasks();
  }
  final GetTasksForTodayUseCase _getTasksForTodayUseCase;

  /// Loads today's tasks
  Future<void> _loadTodaysTasks() async {
    state = const AsyncValue.loading();
    
    final result = await _getTasksForTodayUseCase();
    
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (tasks) => AsyncValue.data(tasks),
    );
  }

  /// Refreshes today's tasks
  Future<void> refresh() async {
    await _loadTodaysTasks();
  }
}

/// State notifier for managing task statistics
class TaskStatisticsNotifier extends StateNotifier<AsyncValue<Map<String, int>>> {

  TaskStatisticsNotifier(this._getTaskStatisticsUseCase) : super(const AsyncValue.loading()) {
    _loadStatistics();
  }
  final GetTaskStatisticsUseCase _getTaskStatisticsUseCase;

  /// Loads task statistics
  Future<void> _loadStatistics() async {
    state = const AsyncValue.loading();
    
    final result = await _getTaskStatisticsUseCase();
    
    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (statistics) => AsyncValue.data(statistics),
    );
  }

  /// Refreshes statistics
  Future<void> refresh() async {
    await _loadStatistics();
  }
}

/// Provider for task counts by status
final taskCountsProvider = Provider<AsyncValue<Map<String, int>>>((ref) {
  final tasksAsync = ref.watch(tasksProvider);
  
  return tasksAsync.when(
    data: (tasks) {
      final counts = <String, int>{};
      counts['completed'] = tasks.where((t) => t.status == TaskStatus.completed).length;
      counts['in_progress'] = tasks.where((t) => t.status == TaskStatus.inProgress).length;
      counts['pending'] = tasks.where((t) => t.status == TaskStatus.todo).length;
      counts['total'] = tasks.length;
      return AsyncValue.data(counts);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

/// Provider for tasks due today count
final tasksDueTodayCountProvider = Provider<AsyncValue<int>>((ref) {
  final todaysTasksAsync = ref.watch(todaysTasksProvider);
  
  return todaysTasksAsync.when(
    data: (tasks) => AsyncValue.data(tasks.length),
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});
