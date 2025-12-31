import 'package:equatable/equatable.dart';
import 'task_entity.dart';

/// Task filtering options
class TaskFilter extends Equatable {

  const TaskFilter({
    this.searchQuery,
    this.statuses = const [],
    this.priorities = const [],
    this.dueDateFrom,
    this.dueDateTo,
    this.tags = const [],
    this.assignedTo,
    this.projectId,
    this.isCompleted,
    this.sortBy = TaskSortOption.createdAt,
    this.sortOrder = TaskSortOrder.descending,
  });
  final String? searchQuery;
  final List<TaskStatus> statuses;
  final List<TaskPriority> priorities;
  final DateTime? dueDateFrom;
  final DateTime? dueDateTo;
  final List<String> tags;
  final String? assignedTo;
  final String? projectId;
  final bool? isCompleted;
  final TaskSortOption sortBy;
  final TaskSortOrder sortOrder;

  /// Create an empty filter
  static const TaskFilter empty = TaskFilter();

  /// Create a filter with only search query
  static TaskFilter search(String query) => TaskFilter(searchQuery: query);

  /// Create a filter for specific statuses
  static TaskFilter byStatus(List<TaskStatus> statuses) => 
      TaskFilter(statuses: statuses);

  /// Create a filter for specific priorities
  static TaskFilter byPriority(List<TaskPriority> priorities) => 
      TaskFilter(priorities: priorities);

  /// Create a filter for due date range
  static TaskFilter byDueDateRange(DateTime from, DateTime to) => 
      TaskFilter(dueDateFrom: from, dueDateTo: to);

  /// Create a filter for specific tags
  static TaskFilter byTags(List<String> tags) => 
      TaskFilter(tags: tags);

  /// Create a filter for assigned user
  static TaskFilter byAssignee(String assignee) => 
      TaskFilter(assignedTo: assignee);

  /// Create a filter for project
  static TaskFilter byProject(String projectId) => 
      TaskFilter(projectId: projectId);

  /// Create a filter for completed tasks
  static const TaskFilter completed = TaskFilter(isCompleted: true);

  /// Create a filter for incomplete tasks
  static const TaskFilter incomplete = TaskFilter(isCompleted: false);

  /// Create a filter for overdue tasks
  static TaskFilter overdue() {
    final now = DateTime.now();
    return TaskFilter(
      dueDateTo: now,
      isCompleted: false,
    );
  }

  /// Create a filter for due today tasks
  static TaskFilter dueToday() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return TaskFilter(
      dueDateFrom: today,
      dueDateTo: tomorrow,
    );
  }

  /// Create a filter for due this week tasks
  static TaskFilter dueThisWeek() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    return TaskFilter(
      dueDateFrom: weekStart,
      dueDateTo: weekEnd,
    );
  }

  /// Copy with updated values
  TaskFilter copyWith({
    String? searchQuery,
    List<TaskStatus>? statuses,
    List<TaskPriority>? priorities,
    DateTime? dueDateFrom,
    DateTime? dueDateTo,
    List<String>? tags,
    String? assignedTo,
    String? projectId,
    bool? isCompleted,
    TaskSortOption? sortBy,
    TaskSortOrder? sortOrder,
  }) {
    return TaskFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      statuses: statuses ?? this.statuses,
      priorities: priorities ?? this.priorities,
      dueDateFrom: dueDateFrom ?? this.dueDateFrom,
      dueDateTo: dueDateTo ?? this.dueDateTo,
      tags: tags ?? this.tags,
      assignedTo: assignedTo ?? this.assignedTo,
      projectId: projectId ?? this.projectId,
      isCompleted: isCompleted ?? this.isCompleted,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Check if filter is empty
  bool get isEmpty {
    return searchQuery == null &&
        statuses.isEmpty &&
        priorities.isEmpty &&
        dueDateFrom == null &&
        dueDateTo == null &&
        tags.isEmpty &&
        assignedTo == null &&
        projectId == null &&
        isCompleted == null;
  }

  /// Check if filter has any active filters
  bool get isNotEmpty => !isEmpty;

  /// Get filter description
  String get description {
    final parts = <String>[];
    
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      parts.add('Search: "$searchQuery"');
    }
    
    if (statuses.isNotEmpty) {
      parts.add('Status: ${statuses.map((s) => s.name).join(', ')}');
    }
    
    if (priorities.isNotEmpty) {
      parts.add('Priority: ${priorities.map((p) => p.name).join(', ')}');
    }
    
    if (dueDateFrom != null || dueDateTo != null) {
      if (dueDateFrom != null && dueDateTo != null) {
        parts.add('Due: ${_formatDate(dueDateFrom!)} - ${_formatDate(dueDateTo!)}');
      } else if (dueDateFrom != null) {
        parts.add('Due after: ${_formatDate(dueDateFrom!)}');
      } else {
        parts.add('Due before: ${_formatDate(dueDateTo!)}');
      }
    }
    
    if (tags.isNotEmpty) {
      parts.add('Tags: ${tags.join(', ')}');
    }
    
    if (assignedTo != null) {
      parts.add('Assigned to: $assignedTo');
    }
    
    if (projectId != null) {
      parts.add('Project: $projectId');
    }
    
    if (isCompleted != null) {
      parts.add(isCompleted! ? 'Completed' : 'Incomplete');
    }
    
    if (sortBy != TaskSortOption.createdAt || sortOrder != TaskSortOrder.descending) {
      parts.add('Sort: ${sortBy.name} ${sortOrder.name}');
    }
    
    return parts.isEmpty ? 'All tasks' : parts.join(' • ');
  }

  /// Apply filter to a list of tasks
  List<TaskEntity> apply(List<TaskEntity> tasks) {
    var filteredTasks = tasks.where(_matchesFilter).toList();
    
    // Apply sorting
    filteredTasks.sort(_getComparator());
    
    return filteredTasks;
  }

  /// Check if a task matches the filter
  bool _matchesFilter(TaskEntity task) {
    // Search query filter
    if (searchQuery != null && searchQuery!.isNotEmpty) {
      final query = searchQuery!.toLowerCase();
      if (!task.title.toLowerCase().contains(query) &&
          !task.description.toLowerCase().contains(query)) {
        return false;
      }
    }
    
    // Status filter
    if (statuses.isNotEmpty && !statuses.contains(task.status)) {
      return false;
    }
    
    // Priority filter
    if (priorities.isNotEmpty && !priorities.contains(task.priority)) {
      return false;
    }
    
    // Due date filter
    if (dueDateFrom != null || dueDateTo != null) {
      if (task.dueDate == null) return false;
      
      if (dueDateFrom != null && task.dueDate!.isBefore(dueDateFrom!)) {
        return false;
      }
      
      if (dueDateTo != null && task.dueDate!.isAfter(dueDateTo!)) {
        return false;
      }
    }
    
    // Tags filter
    if (tags.isNotEmpty) {
      final hasMatchingTag = tags.any((tag) => task.tags.contains(tag));
      if (!hasMatchingTag) return false;
    }
    
    // Assigned to filter
    if (assignedTo != null && task.assignedTo != assignedTo) {
      return false;
    }
    
    // Project filter
    if (projectId != null && task.projectId != projectId) {
      return false;
    }
    
    // Completion filter
    if (isCompleted != null && task.isCompleted != isCompleted) {
      return false;
    }
    
    return true;
  }

  /// Get comparator for sorting
  int Function(TaskEntity, TaskEntity) _getComparator() {
    final ascending = sortOrder == TaskSortOrder.ascending;
    
    switch (sortBy) {
      case TaskSortOption.title:
        return (a, b) => ascending
            ? a.title.compareTo(b.title)
            : b.title.compareTo(a.title);
            
      case TaskSortOption.status:
        return (a, b) => ascending
            ? a.status.index.compareTo(b.status.index)
            : b.status.index.compareTo(a.status.index);
            
      case TaskSortOption.priority:
        return (a, b) => ascending
            ? a.priority.index.compareTo(b.priority.index)
            : b.priority.index.compareTo(a.priority.index);
            
      case TaskSortOption.dueDate:
        return (a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return ascending ? 1 : -1;
          if (b.dueDate == null) return ascending ? -1 : 1;
          return ascending
              ? a.dueDate!.compareTo(b.dueDate!)
              : b.dueDate!.compareTo(a.dueDate!);
        };
        
      case TaskSortOption.createdAt:
        return (a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return ascending ? 1 : -1;
          if (b.createdAt == null) return ascending ? -1 : 1;
          return ascending
              ? a.createdAt!.compareTo(b.createdAt!)
              : b.createdAt!.compareTo(a.createdAt!);
        };
            
      case TaskSortOption.updatedAt:
        return (a, b) {
          if (a.updatedAt == null && b.updatedAt == null) return 0;
          if (a.updatedAt == null) return ascending ? 1 : -1;
          if (b.updatedAt == null) return ascending ? -1 : 1;
          return ascending
              ? a.updatedAt!.compareTo(b.updatedAt!)
              : b.updatedAt!.compareTo(a.updatedAt!);
        };
            
      case TaskSortOption.completedAt:
        return (a, b) {
          if (a.completedAt == null && b.completedAt == null) return 0;
          if (a.completedAt == null) return ascending ? 1 : -1;
          if (b.completedAt == null) return ascending ? -1 : 1;
          return ascending
              ? a.completedAt!.compareTo(b.completedAt!)
              : b.completedAt!.compareTo(a.completedAt!);
        };
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  List<Object?> get props => [
        searchQuery,
        statuses,
        priorities,
        dueDateFrom,
        dueDateTo,
        tags,
        assignedTo,
        projectId,
        isCompleted,
        sortBy,
        sortOrder,
      ];

  @override
  String toString() => description;
}

/// Task sort options
enum TaskSortOption {
  createdAt,
  updatedAt,
  title,
  status,
  priority,
  dueDate,
  completedAt;

  String get name {
    switch (this) {
      case TaskSortOption.createdAt:
        return 'Created';
      case TaskSortOption.updatedAt:
        return 'Updated';
      case TaskSortOption.title:
        return 'Title';
      case TaskSortOption.status:
        return 'Status';
      case TaskSortOption.priority:
        return 'Priority';
      case TaskSortOption.dueDate:
        return 'Due Date';
      case TaskSortOption.completedAt:
        return 'Completed';
    }
  }
}

/// Task sort order
enum TaskSortOrder {
  ascending,
  descending;

  String get name {
    switch (this) {
      case TaskSortOrder.ascending:
        return 'A-Z';
      case TaskSortOrder.descending:
        return 'Z-A';
    }
  }
}

/// Task filter presets
class TaskFilterPresets {
  TaskFilterPresets._();

  static List<TaskFilter> get commonFilters => [
    TaskFilter.empty,
    TaskFilter.completed,
    TaskFilter.incomplete,
    TaskFilter.overdue(),
    TaskFilter.dueToday(),
    TaskFilter.dueThisWeek(),
  ];

  static List<TaskFilter> getStatusFilters() {
    return TaskStatus.values.map((status) => TaskFilter.byStatus([status])).toList();
  }

  static List<TaskFilter> getPriorityFilters() {
    return TaskPriority.values.map((priority) => TaskFilter.byPriority([priority])).toList();
  }

  static TaskFilter getMyTasks(String userId) {
    return TaskFilter.byAssignee(userId);
  }

  static TaskFilter getHighPriorityIncomplete() {
    return const TaskFilter(
      priorities: [TaskPriority.high],
      isCompleted: false,
    );
  }

  static TaskFilter getRecentIncomplete() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return TaskFilter(
      dueDateFrom: weekAgo,
      isCompleted: false,
      sortBy: TaskSortOption.createdAt,
      sortOrder: TaskSortOrder.descending,
    );
  }
}

/// Task filter utilities
class TaskFilterUtils {
  TaskFilterUtils._();

  /// Get active filter count
  static int getActiveFilterCount(TaskFilter filter) {
    int count = 0;
    
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) count++;
    if (filter.statuses.isNotEmpty) count++;
    if (filter.priorities.isNotEmpty) count++;
    if (filter.dueDateFrom != null || filter.dueDateTo != null) count++;
    if (filter.tags.isNotEmpty) count++;
    if (filter.assignedTo != null) count++;
    if (filter.projectId != null) count++;
    if (filter.isCompleted != null) count++;
    
    return count;
  }

  /// Check if filter has date range
  static bool hasDateRange(TaskFilter filter) {
    return filter.dueDateFrom != null || filter.dueDateTo != null;
  }

  /// Get date range description
  static String getDateRangeDescription(TaskFilter filter) {
    if (filter.dueDateFrom != null && filter.dueDateTo != null) {
      return '${_formatDate(filter.dueDateFrom!)} - ${_formatDate(filter.dueDateTo!)}';
    } else if (filter.dueDateFrom != null) {
      return 'After ${_formatDate(filter.dueDateFrom!)}';
    } else if (filter.dueDateTo != null) {
      return 'Before ${_formatDate(filter.dueDateTo!)}';
    }
    return '';
  }

  /// Format date for display
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Create filter from search parameters
  static TaskFilter fromSearchParams(Map<String, dynamic> params) {
    return TaskFilter(
      searchQuery: params['search'] as String?,
      statuses: (params['statuses'] as List<dynamic>?)?.cast<TaskStatus>() ?? [],
      priorities: (params['priorities'] as List<dynamic>?)?.cast<TaskPriority>() ?? [],
      dueDateFrom: params['dueDateFrom'] as DateTime?,
      dueDateTo: params['dueDateTo'] as DateTime?,
      tags: (params['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      assignedTo: params['assignedTo'] as String?,
      projectId: params['projectId'] as String?,
      isCompleted: params['isCompleted'] as bool?,
      sortBy: params['sortBy'] as TaskSortOption? ?? TaskSortOption.createdAt,
      sortOrder: params['sortOrder'] as TaskSortOrder? ?? TaskSortOrder.descending,
    );
  }

  /// Convert filter to search parameters
  static Map<String, dynamic> toSearchParams(TaskFilter filter) {
    return {
      'search': filter.searchQuery,
      'statuses': filter.statuses,
      'priorities': filter.priorities,
      'dueDateFrom': filter.dueDateFrom?.toIso8601String(),
      'dueDateTo': filter.dueDateTo?.toIso8601String(),
      'tags': filter.tags,
      'assignedTo': filter.assignedTo,
      'projectId': filter.projectId,
      'isCompleted': filter.isCompleted,
      'sortBy': filter.sortBy.name,
      'sortOrder': filter.sortOrder.name,
    };
  }
}
