import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'package:task_management/data/task_store.dart';

/// Manages the state of a list of tasks with CRUD operations and filtering
class TaskListNotifier extends ChangeNotifier {
  static final Logger _logger = Logger('TaskListNotifier');
  final TaskStore _taskStore;

  TaskListNotifier({TaskStore? taskStore}) : _taskStore = taskStore ?? TaskDatabase();

  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  TaskStatus? _statusFilter;
  TaskPriority? _priorityFilter;
  DateTime? _dueDateFilter;
  String? _assignedToFilter;
  TaskSortOption _sortOption = TaskSortOption.dueDate;
  bool _sortAscending = true;

  // Getters
  List<Task> get tasks => List.unmodifiable(_tasks);
  List<Task> get filteredTasks => List.unmodifiable(_filteredTasks);
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  TaskStatus? get statusFilter => _statusFilter;
  TaskPriority? get priorityFilter => _priorityFilter;
  DateTime? get dueDateFilter => _dueDateFilter;
  String? get assignedToFilter => _assignedToFilter;
  TaskSortOption get sortOption => _sortOption;
  bool get sortAscending => _sortAscending;

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
    _searchQuery = query.toLowerCase().trim();
    _applyFiltersAndSort();
  }

  /// Sets status filter
  void setStatusFilter(TaskStatus? status) {
    _statusFilter = status;
    _applyFiltersAndSort();
  }

  /// Sets priority filter
  void setPriorityFilter(TaskPriority? priority) {
    _priorityFilter = priority;
    _applyFiltersAndSort();
  }

  /// Sets due date filter
  void setDueDateFilter(DateTime? date) {
    _dueDateFilter = date;
    _applyFiltersAndSort();
  }

  /// Sets assigned to filter
  void setAssignedToFilter(String? userId) {
    _assignedToFilter = userId;
    _applyFiltersAndSort();
  }

  /// Clears all filters
  void clearFilters() {
    _searchQuery = '';
    _statusFilter = null;
    _priorityFilter = null;
    _dueDateFilter = null;
    _assignedToFilter = null;
    _applyFiltersAndSort();
  }

  /// Sets sort option
  void setSortOption(TaskSortOption option, {bool? ascending}) {
    _sortOption = option;
    _sortAscending = ascending ?? _sortAscending;
    _applyFiltersAndSort();
  }

  /// Toggles sort direction
  void toggleSortDirection() {
    _sortAscending = !_sortAscending;
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
    _filteredTasks = List.from(_tasks);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredTasks = _filteredTasks.where((task) =>
          task.title.toLowerCase().contains(_searchQuery) ||
          task.description.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    // Apply status filter
    if (_statusFilter != null) {
      _filteredTasks = _filteredTasks.where((task) =>
          task.status == _statusFilter
      ).toList();
    }

    // Apply priority filter
    if (_priorityFilter != null) {
      _filteredTasks = _filteredTasks.where((task) =>
          task.priority == _priorityFilter
      ).toList();
    }

    // Apply due date filter
    if (_dueDateFilter != null) {
      final filterDate = DateTime(_dueDateFilter!.year, _dueDateFilter!.month, _dueDateFilter!.day);
      _filteredTasks = _filteredTasks.where((task) {
        if (task.dueDate == null) return false;
        final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return taskDate.isAtSameMomentAs(filterDate);
      }).toList();
    }

    // Apply assigned to filter
    if (_assignedToFilter != null) {
      _filteredTasks = _filteredTasks.where((task) =>
          task.assignedTo == _assignedToFilter
      ).toList();
    }

    // Apply sorting
    _sortTasks();
    notifyListeners();
  }

  /// Sorts the filtered tasks based on the current sort option
  void _sortTasks() {
    _filteredTasks.sort((a, b) {
      int comparison = 0;
      
      switch (_sortOption) {
        case TaskSortOption.title:
          comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case TaskSortOption.dueDate:
          if (a.dueDate == null && b.dueDate == null) {
            comparison = 0;
          } else if (a.dueDate == null) {
            comparison = 1;
          } else if (b.dueDate == null) {
            comparison = -1;
          } else {
            comparison = a.dueDate!.compareTo(b.dueDate!);
          }
          break;
        case TaskSortOption.priority:
          comparison = _getPriorityValue(a.priority).compareTo(_getPriorityValue(b.priority));
          break;
        case TaskSortOption.status:
          comparison = a.status.index.compareTo(b.status.index);
          break;
        case TaskSortOption.createdAt:
          if (a.createdAt == null && b.createdAt == null) {
            comparison = 0;
          } else if (a.createdAt == null) {
            comparison = 1;
          } else if (b.createdAt == null) {
            comparison = -1;
          } else {
            comparison = a.createdAt!.compareTo(b.createdAt!);
          }
          break;
        case TaskSortOption.updatedAt:
          if (a.updatedAt == null && b.updatedAt == null) {
            comparison = 0;
          } else if (a.updatedAt == null) {
            comparison = 1;
          } else if (b.updatedAt == null) {
            comparison = -1;
          } else {
            comparison = a.updatedAt!.compareTo(b.updatedAt!);
          }
          break;
      }
      
      return _sortAscending ? comparison : -comparison;
    });
  }

  /// Gets numeric value for priority sorting
  int _getPriorityValue(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 0;
      case TaskPriority.medium:
        return 1;
      case TaskPriority.high:
        return 2;
      case TaskPriority.urgent:
        return 3;
    }
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

/// Enum for task sorting options
enum TaskSortOption {
  title,
  dueDate,
  priority,
  status,
  createdAt,
  updatedAt,
}
