// models/project.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/models/task.dart';

/// Enum for project status
enum ProjectStatus {
  planning('planning'),
  inProgress('in_progress'),
  onHold('on_hold'),
  completed('completed'),
  cancelled('cancelled');

  const ProjectStatus(this.value);
  final String value;

  static ProjectStatus fromString(String value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProjectStatus.planning,
    );
  }
}

/// Enum for project priority
enum ProjectPriority {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const ProjectPriority(this.value);
  final String value;

  static ProjectPriority fromString(String value) {
    return ProjectPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => ProjectPriority.medium,
    );
  }
}

/// Represents a project in the task management system
class Project {
  /// Unique identifier for the project
  final String id;
  
  /// Name of the project
  final String name;
  
  /// Detailed description of the project
  final String description;
  
  /// Due date for the project
  final DateTime dueDate;
  
  /// List of tasks associated with this project
  final List<Task> tasks;
  
  /// Whether the project is completed
  final bool isCompleted;
  
  /// Current status of the project
  final ProjectStatus status;
  
  /// Priority level of the project
  final ProjectPriority priority;
  
  /// List of user IDs assigned to this project
  final List<String> assignedUsers;
  
  /// Timestamp when the project was created
  final DateTime? createdAt;
  
  /// Timestamp when the project was last updated
  final DateTime? updatedAt;

  const Project({
    required this.id,
    required this.name,
    required this.description,
    required this.dueDate,
    required this.tasks,
    this.isCompleted = false,
    this.status = ProjectStatus.planning,
    this.priority = ProjectPriority.medium,
    this.assignedUsers = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Creates a Project from a Map with validation
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  factory Project.fromMap(Map<String, dynamic> map, String id) {
    // Validate required fields
    if (map['name'] == null || map['name'].toString().trim().isEmpty) {
      throw ArgumentError('Project name is required');
    }
    if (map['description'] == null || map['description'].toString().trim().isEmpty) {
      throw ArgumentError('Project description is required');
    }
    if (map['dueDate'] == null) {
      throw ArgumentError('Project due date is required');
    }

    // Parse due date
    DateTime dueDate;
    if (map['dueDate'] is Timestamp) {
      dueDate = (map['dueDate'] as Timestamp).toDate();
    } else if (map['dueDate'] is String) {
      try {
        dueDate = DateTime.parse(map['dueDate'] as String);
      } catch (e) {
        throw ArgumentError('Invalid due date format');
      }
    } else {
      throw ArgumentError('Unexpected type for dueDate');
    }

    // Parse tasks
    List<Task> tasks = [];
    if (map['tasks'] != null) {
      try {
        tasks = List<Task>.from(
          (map['tasks'] as List).map((task) => Task.fromMap(task))
        );
      } catch (e) {
        throw ArgumentError('Invalid tasks data: $e');
      }
    }

    return Project(
      id: id,
      name: map['name'].toString().trim(),
      description: map['description'].toString().trim(),
      dueDate: dueDate,
      tasks: tasks,
      isCompleted: map['isCompleted'] ?? false,
      status: map['status'] != null 
          ? ProjectStatus.fromString(map['status'].toString())
          : ProjectStatus.planning,
      priority: map['priority'] != null 
          ? ProjectPriority.fromString(map['priority'].toString())
          : ProjectPriority.medium,
      assignedUsers: map['assignedUsers'] != null 
          ? List<String>.from(map['assignedUsers'])
          : const [],
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] is Timestamp 
              ? (map['createdAt'] as Timestamp).toDate()
              : DateTime.parse(map['createdAt'] as String))
          : null,
      updatedAt: map['updatedAt'] != null 
          ? (map['updatedAt'] is Timestamp 
              ? (map['updatedAt'] as Timestamp).toDate()
              : DateTime.parse(map['updatedAt'] as String))
          : null,
    );
  }

  /// Creates a Project from a Firestore DocumentSnapshot
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  factory Project.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists) {
      throw ArgumentError('Document does not exist');
    }

    final data = snapshot.data()!;
    return Project.fromMap(data, snapshot.id);
  }

  /// Creates a Project from JSON
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project.fromMap(json, json['id'] as String);
  }

  /// Creates a copy of this project with updated fields
  Project copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? dueDate,
    List<Task>? tasks,
    bool? isCompleted,
    ProjectStatus? status,
    ProjectPriority? priority,
    List<String>? assignedUsers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      tasks: tasks ?? this.tasks,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      assignedUsers: assignedUsers ?? this.assignedUsers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Converts the project to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'tasks': tasks.map((task) => task.toMap()).toList(),
      'isCompleted': isCompleted,
      'status': status.value,
      'priority': priority.value,
      'assignedUsers': assignedUsers,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  /// Converts the project to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'isCompleted': isCompleted,
      'status': status.value,
      'priority': priority.value,
      'assignedUsers': assignedUsers,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Project &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.dueDate == dueDate &&
        other.tasks == tasks &&
        other.isCompleted == isCompleted &&
        other.status == status &&
        other.priority == priority &&
        other.assignedUsers == assignedUsers &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        dueDate.hashCode ^
        tasks.hashCode ^
        isCompleted.hashCode ^
        status.hashCode ^
        priority.hashCode ^
        assignedUsers.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }

  @override
  String toString() {
    return 'Project(id: $id, name: $name, description: $description, '
        'dueDate: $dueDate, isCompleted: $isCompleted, status: $status, '
        'priority: $priority, tasks: ${tasks.length}, assignedUsers: ${assignedUsers.length})';
  }

  /// Validates the project data
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Project name is required';
    }
    if (name.trim().length < 3) {
      return 'Project name must be at least 3 characters';
    }
    if (name.trim().length > 100) {
      return 'Project name must be less than 100 characters';
    }
    return null;
  }

  /// Validates the project description
  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Project description is required';
    }
    if (description.trim().length < 10) {
      return 'Project description must be at least 10 characters';
    }
    if (description.trim().length > 500) {
      return 'Project description must be less than 500 characters';
    }
    return null;
  }

  /// Validates the project due date
  static String? validateDueDate(DateTime? dueDate) {
    if (dueDate == null) {
      return 'Due date is required';
    }
    if (dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Due date cannot be in the past';
    }
    return null;
  }

  /// Checks if the project is overdue
  bool get isOverdue => !isCompleted && dueDate.isBefore(DateTime.now());

  /// Gets the number of completed tasks
  int get completedTasksCount => tasks.where((task) => task.isCompleted).length;

  /// Gets the number of pending tasks
  int get pendingTasksCount => tasks.where((task) => !task.isCompleted).length;

  /// Gets the completion percentage
  double get completionPercentage => tasks.isEmpty 
      ? 0.0 
      : (completedTasksCount / tasks.length) * 100;

  /// Returns a project with updated timestamp
  Project withUpdatedTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }

  /// Returns a project marked as completed
  Project markAsCompleted() {
    return copyWith(
      isCompleted: true,
      status: ProjectStatus.completed,
      updatedAt: DateTime.now(),
    );
  }
}
