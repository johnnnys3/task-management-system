import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/task_query.dart';

export 'package:task_management/data/task_query.dart' show TaskSortOption;

/// Manages the state of a list of tasks with CRUD operations and filtering
class TaskListNotifier extends ChangeNotifier {
  static final Logger _logger = Logger('TaskListNotifier');
  final TaskStore _taskStore;

  TaskListNotifier({TaskStore? taskStore}) : _taskStore = taskStore ?? TaskDatabase();

  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = false;
  String? _error;
  TaskQuery _query = const TaskQuery();

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get filteredTasks => List.unmodifiable(_filteredTasks);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _query.searchQuery;
  TaskStatus? get statusFilter => _query.statusFilter;
  TaskPriority? get priorityFilter => _query.priorityFilter;
  DateTime? get dueDateFilter => _query.dueDateFilter;
  String? get assignedToFilter => _query.assignedToFilter;
  TaskSortOption get sortOption => _query.sortOption;
  bool get sortAscending => _query.sortAscending;

  // Computed properties
  int get taskCount => _tasks.length;
  int get completedTaskCount => _tasks.where((task) => task.isCompleted).length;
  int get pendingTaskCount => _tasks.where((task) => !task.isCompleted).length;
  int get overdueTaskCount => _tasks.where((task) => task.isOverdue).length;
  int get filteredTaskCount => _filteredTasks.length;

  /// Loads all tasks from the database
  Future<void> loadTasks() async {
    _setLoading(true);
    try {
      final tasks = await _taskStore.fetch();
      _tasks = tasks;
      _applyFiltersAndSort();
      _clearError();
      _logger.info('Loaded ${tasks.length} tasks');
    } catch (e, stackTrace) {
      _setError('Failed to load tasks: $e');
      _logger.severe('Error loading tasks', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Loads tasks for a specific project
  Future<void> loadTasksForProject(String projectId) async {
    _setLoading(true);
    try {
      final tasks = await _taskStore.fetch(projectId: projectId);
      _tasks = tasks;
      _applyFiltersAndSort();
      _clearError();
      _logger.info('Loaded ${tasks.length} tasks for project $projectId');
    } catch (e, stackTrace) {
      _setError('Failed to load project tasks: $e');
      _logger.severe('Error loading project tasks', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Loads tasks for a specific user
  Future<void> loadTasksForUser(String userId) async {
    _setLoading(true);
    try {
      final tasks = await _taskStore.fetch(userId: userId);
      _tasks = tasks;
      _applyFiltersAndSort();
      _clearError();
      _logger.info('Loaded ${tasks.length} tasks for user $userId');
    } catch (e, stackTrace) {
      _setError('Failed to load user tasks: $e');
      _logger.severe('Error loading user tasks', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Adds a new task to the list and database
  Future<void> addTask(Task task) async {
    try {
      _validateTask(task);
      final taskId = await _taskStore.create(task);
      final newTask = task.copyWith(id: taskId);
      _tasks.add(newTask);
      _applyFiltersAndSort();
      _clearError();
      _logger.info('Added task: ${newTask.id}');
    } catch (e, stackTrace) {
      _setError('Failed to add task: $e');
      _logger.severe('Error adding task', e, stackTrace);
      rethrow;
    }
  }

  /// Updates an existing task
  Future<void> updateTask(Task task) async {
    try {
      _validateTask(task);
      await _taskStore.update(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        _applyFiltersAndSort();
        _clearError();
        _logger.info('Updated task: ${task.id}');
      } else {
        throw Exception('Task not found in list');
      }
    } catch (e, stackTrace) {
      _setError('Failed to update task: $e');
      _logger.severe('Error updating task', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a task
  Future<void> deleteTask(String taskId) async {
    try {
      if (taskId.isEmpty) {
        throw ArgumentError('Task ID is required');
      }
      
      await _taskStore.delete(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      _applyFiltersAndSort();
      _clearError();
      _logger.info('Deleted task: $taskId');
    } catch (e, stackTrace) {
      _setError('Failed to delete task: $e');
      _logger.severe('Error deleting task', e, stackTrace);
      rethrow;
    }
  }

  /// Toggles task completion status
  Future<void> toggleTaskCompletion(String taskId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.isCompleted 
          ? task.copyWith(isCompleted: false, status: TaskStatus.todo)
          : task.markAsCompleted();
      
      await updateTask(updatedTask);
    } catch (e, stackTrace) {
      _setError('Failed to toggle task completion: $e');
      _logger.severe('Error toggling task completion', e, stackTrace);
      rethrow;
    }
  }

  /// Updates task status
  Future<void> updateTaskStatus(String taskId, TaskStatus newStatus) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.withStatus(newStatus);
      await updateTask(updatedTask);
    } catch (e, stackTrace) {
      _setError('Failed to update task status: $e');
      _logger.severe('Error updating task status', e, stackTrace);
      rethrow;
    }
  }

  /// Assigns a task to a user
  Future<void> assignTask(String taskId, String userId) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final updatedTask = task.withAssignedUser(userId);
      await updateTask(updatedTask);
    } catch (e, stackTrace) {
      _setError('Failed to assign task: $e');
      _logger.severe('Error assigning task', e, stackTrace);
      rethrow;
    }
  }

  /// Sets search query and applies filters
  void setSearchQuery(String query) {
    _query = _query.copyWith(searchQuery: query.toLowerCase().trim());
    _applyFiltersAndSort();
  }

  /// Sets status filter
  void setStatusFilter(TaskStatus? status) {
    _query = _query.copyWith(statusFilter: status, clearStatusFilter: status == null);
    _applyFiltersAndSort();
  }

  /// Sets priority filter
  void setPriorityFilter(TaskPriority? priority) {
    _query = _query.copyWith(priorityFilter: priority, clearPriorityFilter: priority == null);
    _applyFiltersAndSort();
  }

  /// Sets due date filter
  void setDueDateFilter(DateTime? date) {
    _query = _query.copyWith(dueDateFilter: date, clearDueDateFilter: date == null);
    _applyFiltersAndSort();
  }

  /// Sets assigned to filter
  void setAssignedToFilter(String? userId) {
    _query = _query.copyWith(assignedToFilter: userId, clearAssignedToFilter: userId == null);
    _applyFiltersAndSort();
  }

  /// Clears all filters
  void clearFilters() {
    _query = TaskQuery(sortOption: _query.sortOption, sortAscending: _query.sortAscending);
    _applyFiltersAndSort();
  }

  /// Sets sort option
  void setSortOption(TaskSortOption option, {bool? ascending}) {
    _query = _query.copyWith(sortOption: option, sortAscending: ascending ?? _query.sortAscending);
    _applyFiltersAndSort();
  }

  /// Toggles sort direction
  void toggleSortDirection() {
    _query = _query.copyWith(sortAscending: !_query.sortAscending);
    _applyFiltersAndSort();
  }

  /// Refreshes the task list
  Future<void> refresh() async {
    await loadTasks();
  }

  /// Clears all tasks (for testing or reset)
  void clearAllTasks() {
    _tasks.clear();
    _filteredTasks.clear();
    notifyListeners();
    _logger.info('Cleared all tasks');
  }

  /// Applies all filters and sorting to the task list
  void _applyFiltersAndSort() {
    _filteredTasks = _query.apply(_tasks);
    notifyListeners();
  }

  /// Validates task before adding/updating
  void _validateTask(Task task) {
    final titleError = Task.validateTitle(task.title);
    if (titleError != null) {
      throw ArgumentError(titleError);
    }
    
    final descriptionError = Task.validateDescription(task.description);
    if (descriptionError != null) {
      throw ArgumentError(descriptionError);
    }
    
    final dueDateError = Task.validateDueDate(task.dueDate);
    if (dueDateError != null) {
      throw ArgumentError(dueDateError);
    }
  }

  /// Sets loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Sets error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clears error message
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _logger.info('TaskListNotifier disposed');
    super.dispose();
  }
}
