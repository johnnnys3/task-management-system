import 'package:task_management/models/task.dart';
import 'package:task_management/data/task_search.dart';

/// Sorting options for a list of tasks
enum TaskSortOption {
  title,
  dueDate,
  priority,
  status,
  createdAt,
  updatedAt,
}

/// Immutable set of filter/sort parameters applied to a task list
class TaskQuery {
  final String searchQuery;
  final TaskStatus? statusFilter;
  final TaskPriority? priorityFilter;
  final DateTime? dueDateFilter;
  final String? assignedToFilter;
  final TaskSortOption sortOption;
  final bool sortAscending;

  const TaskQuery({
    this.searchQuery = '',
    this.statusFilter,
    this.priorityFilter,
    this.dueDateFilter,
    this.assignedToFilter,
    this.sortOption = TaskSortOption.dueDate,
    this.sortAscending = true,
  });

  /// Applies filtering and sorting to [tasks], returning a new list
  List<Task> apply(List<Task> tasks) {
    var result = filterTasksBySearchQuery(tasks, searchQuery);

    if (statusFilter != null) {
      result = result.where((task) => task.status == statusFilter).toList();
    }

    if (priorityFilter != null) {
      result = result.where((task) => task.priority == priorityFilter).toList();
    }

    if (dueDateFilter != null) {
      final filterDate = DateTime(dueDateFilter!.year, dueDateFilter!.month, dueDateFilter!.day);
      result = result.where((task) {
        if (task.dueDate == null) return false;
        final taskDate = DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
        return taskDate.isAtSameMomentAs(filterDate);
      }).toList();
    }

    if (assignedToFilter != null) {
      result = result.where((task) => task.assignedTo == assignedToFilter).toList();
    }

    return _sorted(result);
  }

  List<Task> _sorted(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    sorted.sort((a, b) {
      final comparison = _compare(a, b);
      return sortAscending ? comparison : -comparison;
    });
    return sorted;
  }

  int _compare(Task a, Task b) {
    switch (sortOption) {
      case TaskSortOption.title:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      case TaskSortOption.dueDate:
        return _compareNullable(a.dueDate, b.dueDate);
      case TaskSortOption.priority:
        return _priorityValue(a.priority).compareTo(_priorityValue(b.priority));
      case TaskSortOption.status:
        return a.status.index.compareTo(b.status.index);
      case TaskSortOption.createdAt:
        return _compareNullable(a.createdAt, b.createdAt);
      case TaskSortOption.updatedAt:
        return _compareNullable(a.updatedAt, b.updatedAt);
    }
  }

  int _compareNullable(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  int _priorityValue(TaskPriority priority) {
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

  TaskQuery copyWith({
    String? searchQuery,
    TaskStatus? statusFilter,
    bool clearStatusFilter = false,
    TaskPriority? priorityFilter,
    bool clearPriorityFilter = false,
    DateTime? dueDateFilter,
    bool clearDueDateFilter = false,
    String? assignedToFilter,
    bool clearAssignedToFilter = false,
    TaskSortOption? sortOption,
    bool? sortAscending,
  }) {
    return TaskQuery(
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter ? null : (statusFilter ?? this.statusFilter),
      priorityFilter: clearPriorityFilter ? null : (priorityFilter ?? this.priorityFilter),
      dueDateFilter: clearDueDateFilter ? null : (dueDateFilter ?? this.dueDateFilter),
      assignedToFilter: clearAssignedToFilter ? null : (assignedToFilter ?? this.assignedToFilter),
      sortOption: sortOption ?? this.sortOption,
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }
}
