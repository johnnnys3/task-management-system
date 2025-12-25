import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/models/project.dart';

/// Enum for task status
enum TaskStatus {
  todo('todo'),
  inProgress('in_progress'),
  review('review'),
  completed('completed'),
  cancelled('cancelled');

  const TaskStatus(this.value);
  final String value;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

/// Enum for task priority
enum TaskPriority {
  low('low'),
  medium('medium'),
  high('high'),
  urgent('urgent');

  const TaskPriority(this.value);
  final String value;

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// Represents a task in the task management system
class Task {
  /// Unique identifier for the task
  final String id;
  
  /// Title of the task
  final String title;
  
  /// Detailed description of the task
  final String description;
  
  /// Due date for the task
  final DateTime? dueDate;
  
  /// List of attachment URLs or file paths
  final List<String> attachments;
  
  /// Whether the task is completed
  final bool isCompleted;
  
  /// Current status of the task
  final TaskStatus status;
  
  /// Priority level of the task
  final TaskPriority priority;
  
  /// Associated project (if any)
  final Project? associatedProject;
  
  /// List of user IDs assigned to this task
  final List<String> assignedMembers;
  
  /// User ID who created this task
  final String? createdBy;
  
  /// User ID who is currently responsible for this task
  final String? assignedTo;
  
  /// Estimated hours to complete the task
  final double? estimatedHours;
  
  /// Actual hours spent on the task
  final double? actualHours;
  
  /// List of tags for categorization
  final List<String> tags;
  
  /// Timestamp when the task was created
  final DateTime? createdAt;
  
  /// Timestamp when the task was last updated
  final DateTime? updatedAt;
  
  /// Timestamp when the task was completed
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.attachments = const [],
    this.isCompleted = false,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.associatedProject,
    this.assignedMembers = const [],
    this.createdBy,
    this.assignedTo,
    this.estimatedHours,
    this.actualHours,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  /// Creates a Task from a Firestore DocumentSnapshot with validation
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  factory Task.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists) {
      throw ArgumentError('Document does not exist');
    }

    final data = snapshot.data()!;
    return Task.fromMap(data, snapshot.id);
  }

  /// Creates a Task from a Map with validation
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  factory Task.fromMap(Map<String, dynamic> map, [String? id]) {
    // Validate required fields
    if (map['title'] == null || map['title'].toString().trim().isEmpty) {
      throw ArgumentError('Task title is required');
    }
    if (map['description'] == null || map['description'].toString().trim().isEmpty) {
      throw ArgumentError('Task description is required');
    }

    // Parse due date
    DateTime? dueDate;
    if (map['dueDate'] != null) {
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
    }

    // Parse associated project
    Project? associatedProject;
    if (map['associatedProject'] != null) {
      try {
        associatedProject = Project.fromMap(
          map['associatedProject'], 
          map['associatedProject']['id'] ?? id ?? 'unknown'
        );
      } catch (e) {
        throw ArgumentError('Invalid associated project data: $e');
      }
    }

    return Task(
      id: id ?? map['id'] ?? '',
      title: map['title'].toString().trim(),
      description: map['description'].toString().trim(),
      dueDate: dueDate,
      attachments: map['attachments'] != null 
          ? List<String>.from(map['attachments'])
          : const [],
      isCompleted: map['isCompleted'] == true || map['isCompleted'] == 1,
      status: map['status'] != null 
          ? TaskStatus.fromString(map['status'].toString())
          : TaskStatus.todo,
      priority: map['priority'] != null 
          ? TaskPriority.fromString(map['priority'].toString())
          : TaskPriority.medium,
      associatedProject: associatedProject,
      assignedMembers: map['assignedMembers'] != null 
          ? List<String>.from(map['assignedMembers'])
          : const [],
      createdBy: map['createdBy']?.toString(),
      assignedTo: map['assignedTo']?.toString(),
      estimatedHours: map['estimatedHours']?.toDouble(),
      actualHours: map['actualHours']?.toDouble(),
      tags: map['tags'] != null 
          ? List<String>.from(map['tags'])
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
      completedAt: map['completedAt'] != null 
          ? (map['completedAt'] is Timestamp 
              ? (map['completedAt'] as Timestamp).toDate()
              : DateTime.parse(map['completedAt'] as String))
          : null,
    );
  }

  /// Creates a Task from JSON
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task.fromMap(json, json['id'] as String);
  }

  /// Creates a copy of this task with updated fields
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    List<String>? attachments,
    bool? isCompleted,
    TaskStatus? status,
    TaskPriority? priority,
    Project? associatedProject,
    List<String>? assignedMembers,
    String? createdBy,
    String? assignedTo,
    double? estimatedHours,
    double? actualHours,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      associatedProject: associatedProject ?? this.associatedProject,
      assignedMembers: assignedMembers ?? this.assignedMembers,
      createdBy: createdBy ?? this.createdBy,
      assignedTo: assignedTo ?? this.assignedTo,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Converts the task to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'attachments': attachments,
      'isCompleted': isCompleted,
      'status': status.value,
      'priority': priority.value,
      'associatedProject': associatedProject?.toMap(),
      'assignedMembers': assignedMembers,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
      'tags': tags,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  /// Converts the task to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate?.toIso8601String(),
      'attachments': attachments,
      'isCompleted': isCompleted,
      'status': status.value,
      'priority': priority.value,
      'associatedProject': associatedProject?.toJson(),
      'assignedMembers': assignedMembers,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
      'tags': tags,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.dueDate == dueDate &&
        other.attachments == attachments &&
        other.isCompleted == isCompleted &&
        other.status == status &&
        other.priority == priority &&
        other.associatedProject == associatedProject &&
        other.assignedMembers == assignedMembers &&
        other.createdBy == createdBy &&
        other.assignedTo == assignedTo &&
        other.estimatedHours == estimatedHours &&
        other.actualHours == actualHours &&
        other.tags == tags &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        dueDate.hashCode ^
        attachments.hashCode ^
        isCompleted.hashCode ^
        status.hashCode ^
        priority.hashCode ^
        associatedProject.hashCode ^
        assignedMembers.hashCode ^
        createdBy.hashCode ^
        assignedTo.hashCode ^
        estimatedHours.hashCode ^
        actualHours.hashCode ^
        tags.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        completedAt.hashCode;
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, status: $status, priority: $priority, '
        'isCompleted: $isCompleted, dueDate: $dueDate, assignedTo: $assignedTo)';
  }

  /// Validates the task data
  static String? validateTitle(String? title) {
    if (title == null || title.trim().isEmpty) {
      return 'Task title is required';
    }
    if (title.trim().length < 3) {
      return 'Task title must be at least 3 characters';
    }
    if (title.trim().length > 200) {
      return 'Task title must be less than 200 characters';
    }
    return null;
  }

  /// Validates the task description
  static String? validateDescription(String? description) {
    if (description == null || description.trim().isEmpty) {
      return 'Task description is required';
    }
    if (description.trim().length < 10) {
      return 'Task description must be at least 10 characters';
    }
    if (description.trim().length > 1000) {
      return 'Task description must be less than 1000 characters';
    }
    return null;
  }

  /// Validates the task due date
  static String? validateDueDate(DateTime? dueDate) {
    if (dueDate != null && dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return 'Due date cannot be in the past';
    }
    return null;
  }

  /// Checks if the task has a due date
  bool get hasDueDate => dueDate != null;

  /// Checks if the task is overdue
  bool get isOverdue => !isCompleted && dueDate != null && dueDate!.isBefore(DateTime.now());

  /// Checks if the task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return taskDate.isAtSameMomentAs(today);
  }

  /// Checks if the task is due soon (within 3 days)
  bool get isDueSoon {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final threeDaysFromNow = now.add(const Duration(days: 3));
    return dueDate!.isBefore(threeDaysFromNow) && dueDate!.isAfter(now);
  }

  /// Gets the remaining days until due date
  int get daysUntilDue {
    if (dueDate == null) return -1;
    final now = DateTime.now();
    final difference = dueDate!.difference(now);
    return difference.inDays;
  }

  /// Gets the time tracking efficiency
  double? get efficiency {
    if (estimatedHours == null || actualHours == null || estimatedHours == 0) {
      return null;
    }
    return estimatedHours! / actualHours!;
  }

  /// Returns a task with updated timestamp
  Task withUpdatedTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }

  /// Returns a task marked as completed
  Task markAsCompleted() {
    return copyWith(
      isCompleted: true,
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a task with updated status
  Task withStatus(TaskStatus newStatus) {
    return copyWith(
      status: newStatus,
      isCompleted: newStatus == TaskStatus.completed,
      completedAt: newStatus == TaskStatus.completed ? DateTime.now() : completedAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a task with assigned user
  Task withAssignedUser(String userId) {
    return copyWith(
      assignedTo: userId,
      updatedAt: DateTime.now(),
    );
  }
}
