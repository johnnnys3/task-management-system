import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:task_management/models/project.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/models/task_list_notifier.dart';
import 'dart:async';

import 'package:task_management/data/database_helper(task).dart';
import 'package:task_management/data/task_store.dart';

/// Provider for managing a single task's state
class TaskProvider extends ChangeNotifier {
  static final Logger _logger = Logger('TaskProvider');
  final TaskStore _taskStore;

  TaskProvider({TaskStore? taskStore}) : _taskStore = taskStore ?? TaskDatabase();

  Task? _task;
  bool _isLoading = false;
  String? _error;
  bool _isDirty = false;

  // Getters
  Task? get task => _task;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isDirty => _isDirty;
  bool get hasTask => _task != null;

  /// Loads a specific task by ID
  Future<void> loadTask(String taskId) async {
    if (taskId.isEmpty) {
      _setError('Task ID is required');
      return;
    }

    _setLoading(true);
    try {
      // ponytail: TaskStore has no get-by-id; fetch and find locally. Add a
      // dedicated lookup if this ever needs to scale past a small task list.
      final tasks = await _taskStore.fetch();
      final task = tasks.firstWhere(
        (t) => t.id == taskId,
        orElse: () => throw TaskNotFoundException(taskId),
      );
      _task = task;
      _isDirty = false;
      _clearError();
      _logger.info('Loaded task: $taskId');
    } catch (e, stackTrace) {
      _setError('Failed to load task: $e');
      _logger.severe('Error loading task', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Creates a new task with the provided details
  Future<void> createTask({
    required String title,
    required String description,
    DateTime? dueDate,
    List<String> attachments = const [],
    Project? associatedProject,
    List<String> assignedMembers = const [],
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    String? createdBy,
    String? assignedTo,
    double? estimatedHours,
    List<String> tags = const [],
  }) async {
    _setLoading(true);
    try {
      final newTask = Task(
        id: '', // Will be set by database
        title: title.trim(),
        description: description.trim(),
        dueDate: dueDate,
        attachments: attachments,
        isCompleted: false,
        status: status,
        priority: priority,
        associatedProject: associatedProject,
        assignedMembers: assignedMembers,
        createdBy: createdBy,
        assignedTo: assignedTo,
        estimatedHours: estimatedHours,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final taskId = await _taskStore.create(newTask);
      _task = newTask.copyWith(id: taskId);
      _isDirty = false;
      _clearError();
      _logger.info('Created task: $taskId');
    } catch (e, stackTrace) {
      _setError('Failed to create task: $e');
      _logger.severe('Error creating task', e, stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates the current task with new values
  Future<void> updateTask({
    String? title,
    String? description,
    DateTime? dueDate,
    List<String>? attachments,
    bool? isCompleted,
    TaskStatus? status,
    TaskPriority? priority,
    Project? associatedProject,
    List<String>? assignedMembers,
    String? assignedTo,
    double? estimatedHours,
    double? actualHours,
    List<String>? tags,
    DateTime? completedAt,
  }) async {
    if (_task == null) {
      _setError('No task loaded to update');
      return;
    }

    _setLoading(true);
    try {
      final updatedTask = _task!.copyWith(
        title: title?.trim(),
        description: description?.trim(),
        dueDate: dueDate,
        attachments: attachments,
        isCompleted: isCompleted,
        status: status,
        priority: priority,
        associatedProject: associatedProject,
        assignedMembers: assignedMembers,
        assignedTo: assignedTo,
        estimatedHours: estimatedHours,
        actualHours: actualHours,
        tags: tags,
        completedAt: completedAt,
        updatedAt: DateTime.now(),
      );

      await _taskStore.update(updatedTask);
      _task = updatedTask;
      _isDirty = false;
      _clearError();
      _logger.info('Updated task: ${_task!.id}');
    } catch (e, stackTrace) {
      _setError('Failed to update task: $e');
      _logger.severe('Error updating task', e, stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates task locally without saving to database (for form editing)
  void updateTaskLocally(Task task) {
    _task = task;
    _isDirty = true;
    notifyListeners();
  }

  /// Toggles task completion status
  Future<void> toggleCompletion() async {
    if (_task == null) return;
    
    final newStatus = _task!.isCompleted ? TaskStatus.todo : TaskStatus.completed;
    await updateTask(
      isCompleted: !_task!.isCompleted,
      status: newStatus,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
    );
  }

  /// Updates task status
  Future<void> updateStatus(TaskStatus newStatus) async {
    if (_task == null) return;
    
    await updateTask(
      status: newStatus,
      isCompleted: newStatus == TaskStatus.completed,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
    );
  }

  /// Assigns task to a user
  Future<void> assignToUser(String userId) async {
    if (_task == null) return;
    
    await updateTask(assignedTo: userId);
  }

  /// Deletes the current task
  Future<void> deleteTask() async {
    if (_task == null) {
      _setError('No task loaded to delete');
      return;
    }

    _setLoading(true);
    try {
      final deletedId = _task!.id;
      await _taskStore.delete(deletedId);
      _task = null;
      _isDirty = false;
      _clearError();
      _logger.info('Deleted task: $deletedId');
    } catch (e, stackTrace) {
      _setError('Failed to delete task: $e');
      _logger.severe('Error deleting task', e, stackTrace);
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Saves the current task (creates or updates)
  Future<void> saveTask() async {
    if (_task == null) {
      await createTask(
        title: '',
        description: '',
      );
    } else {
      await updateTask();
    }
  }

  /// Resets the provider state
  void reset() {
    _task = null;
    _isDirty = false;
    _clearError();
    notifyListeners();
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
    _logger.info('TaskProvider disposed');
    super.dispose();
  }
}

/// Enhanced provider for managing a list of tasks
class TaskListProvider extends ChangeNotifier {
  static final Logger _logger = Logger('TaskListProvider');
  final TaskStore _taskStore;

  TaskListProvider({TaskStore? taskStore}) : _taskStore = taskStore ?? TaskDatabase();

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

  /// Fetches all tasks from the database
  Future<void> fetchTasks() async {
    _setLoading(true);
    try {
      _tasks = await _taskStore.fetch();
      _applyFiltersAndSort();
      _clearError();
      _logger.info('Fetched ${_tasks.length} tasks');
    } catch (e, stackTrace) {
      _setError('Failed to fetch tasks: $e');
      _logger.severe('Error fetching tasks', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches tasks for a specific project
  Future<void> fetchTasksForProject(String projectId) async {
    if (projectId.isEmpty) {
      _setError('Project ID is required');
      return;
    }

    _setLoading(true);
    try {
      _tasks = await _taskStore.fetch(projectId: projectId);
      _applyFiltersAndSort();
      _clearError();
      _logger.info('Fetched ${_tasks.length} tasks for project $projectId');
    } catch (e, stackTrace) {
      _setError('Failed to fetch project tasks: $e');
      _logger.severe('Error fetching project tasks', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Fetches tasks for a specific user
  Future<void> fetchTasksForUser(String userId) async {
    if (userId.isEmpty) {
      _setError('User ID is required');
      return;
    }

    _setLoading(true);
    try {
      _tasks = await _taskStore.fetch(userId: userId);
      _applyFiltersAndSort();
      _clearError();
      _logger.info('Fetched ${_tasks.length} tasks for user $userId');
    } catch (e, stackTrace) {
      _setError('Failed to fetch user tasks: $e');
      _logger.severe('Error fetching user tasks', e, stackTrace);
    } finally {
      _setLoading(false);
    }
  }

  /// Adds a new task to the list
  Future<void> addTask(Task task) async {
    try {
      final taskId = await _taskStore.create(task);
      final newTask = task.copyWith(id: taskId);
      _tasks.add(newTask);
      _applyFiltersAndSort();
      _clearError();
      _logger.info('Added task: $taskId');
    } catch (e, stackTrace) {
      _setError('Failed to add task: $e');
      _logger.severe('Error adding task', e, stackTrace);
      rethrow;
    }
  }

  /// Updates an existing task in the list
  Future<void> updateTask(Task task) async {
    try {
      await _taskStore.update(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        _applyFiltersAndSort();
        _clearError();
        _logger.info('Updated task: ${task.id}');
      }
    } catch (e, stackTrace) {
      _setError('Failed to update task: $e');
      _logger.severe('Error updating task', e, stackTrace);
      rethrow;
    }
  }

  /// Deletes a task from the list
  Future<void> deleteTask(String taskId) async {
    if (taskId.isEmpty) {
      _setError('Task ID is required');
      return;
    }

    try {
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
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.isCompleted 
        ? task.copyWith(isCompleted: false, status: TaskStatus.todo)
        : task.markAsCompleted();
    
    await updateTask(updatedTask);
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
    await fetchTasks();
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
    _logger.info('TaskListProvider disposed');
    super.dispose();
  }
}
