import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

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

/// Task entity (domain layer – no serialization logic here)
class TaskEntity extends Equatable {
  const TaskEntity({
    required this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.attachments = const [],
    this.isCompleted = false,
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.projectId,
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

  final String id;
  final String title;
  final String description;
  final DateTime? dueDate;
  final List<String> attachments;
  final bool isCompleted;
  final TaskStatus status;
  final TaskPriority priority;
  final String? projectId;
  final List<String> assignedMembers;
  final String? createdBy;
  final String? assignedTo;
  final double? estimatedHours;
  final double? actualHours;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  /// Copy with updates
  TaskEntity copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    List<String>? attachments,
    bool? isCompleted,
    TaskStatus? status,
    TaskPriority? priority,
    String? projectId,
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
    return TaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      attachments: attachments ?? this.attachments,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      projectId: projectId ?? this.projectId,
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

  /// Firestore serialization
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'attachments': attachments,
      'isCompleted': isCompleted,
      'status': status.value,
      'priority': priority.value,
      'projectId': projectId,
      'assignedMembers': assignedMembers,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'estimatedHours': estimatedHours,
      'actualHours': actualHours,
      'tags': tags,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'completedAt': completedAt,
    };
  }

  /// Firestore deserialization
  factory TaskEntity.fromMap(Map<String, dynamic> data, String id) {
    // Helper function to parse date from string or Timestamp
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      
      if (value is Timestamp) {
        return value.toDate();
      }
      
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('TaskEntity.fromMap: Failed to parse date string: $value');
          return null;
        }
      }
      
      return null;
    }

    return TaskEntity(
      id: id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      dueDate: parseDate(data['dueDate']),
      attachments: List<String>.from(data['attachments'] as List? ?? []),
      isCompleted: data['isCompleted'] as bool? ?? false,
      status: TaskStatus.fromString(data['status']?.toString() ?? 'todo'),
      priority: TaskPriority.fromString(data['priority']?.toString() ?? 'medium'),
      projectId: data['projectId']?.toString() ?? '',
      assignedMembers: List<String>.from(data['assignedMembers'] as List? ?? []),
      createdBy: data['createdBy']?.toString() ?? '',
      assignedTo: data['assignedTo']?.toString() ?? '',
      estimatedHours: (data['estimatedHours'] as num?)?.toDouble(),
      actualHours: (data['actualHours'] as num?)?.toDouble(),
      tags: List<String>.from(data['tags'] as List? ?? []),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
      completedAt: parseDate(data['completedAt']),
    );
  }

  /// Domain helpers
  bool get hasDueDate => dueDate != null;

  bool get isOverdue =>
      !isCompleted && dueDate != null && dueDate!.isBefore(DateTime.now());

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDay = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    return today == taskDay;
  }

  bool get isDueSoon {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    return dueDate!.isAfter(now) &&
        dueDate!.isBefore(now.add(const Duration(days: 3)));
  }

  int get daysUntilDue =>
      dueDate == null ? -1 : dueDate!.difference(DateTime.now()).inDays;

  double? get efficiency {
    if (estimatedHours == null ||
        actualHours == null ||
        actualHours == 0) {
      return null;
    }
    return estimatedHours! / actualHours!;
  }

  TaskEntity markAsCompleted() {
    final now = DateTime.now();
    return copyWith(
      isCompleted: true,
      status: TaskStatus.completed,
      completedAt: now,
      updatedAt: now,
    );
  }

  TaskEntity withStatus(TaskStatus newStatus) {
    final now = DateTime.now();
    return copyWith(
      status: newStatus,
      isCompleted: newStatus == TaskStatus.completed,
      completedAt:
          newStatus == TaskStatus.completed ? now : completedAt,
      updatedAt: now,
    );
  }

  TaskEntity withAssignedUser(String userId) {
    return copyWith(
      assignedTo: userId,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        dueDate,
        attachments,
        isCompleted,
        status,
        priority,
        projectId,
        assignedMembers,
        createdBy,
        assignedTo,
        estimatedHours,
        actualHours,
        tags,
        createdAt,
        updatedAt,
        completedAt,
      ];
}
