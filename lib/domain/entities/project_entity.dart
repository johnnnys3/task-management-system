import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Enum for project status
enum ProjectStatus {
  active('active'),
  completed('completed'),
  archived('archived'),
  cancelled('cancelled');

  const ProjectStatus(this.value);
  final String value;

  static ProjectStatus fromString(String value) {
    return ProjectStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ProjectStatus.active,
    );
  }
}

/// Project entity representing a project in the domain layer
/// This is the pure business object without any infrastructure dependencies
class ProjectEntity extends Equatable {

  const ProjectEntity({
    required this.id,
    required this.name,
    required this.description,
    this.status = ProjectStatus.active,
    this.assignedMembers = const [],
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.startDate,
    this.endDate,
    this.tags = const [],
    this.isActive = true,
  });
  /// Unique identifier for the project
  final String id;
  
  /// Name of the project
  final String name;
  
  /// Detailed description of the project
  final String description;
  
  /// Current status of the project
  final ProjectStatus status;
  
  /// List of user IDs assigned to this project
  final List<String> assignedMembers;
  
  /// User ID who created this project
  final String? createdBy;
  
  /// Timestamp when the project was created
  final DateTime? createdAt;
  
  /// Timestamp when the project was last updated
  final DateTime? updatedAt;
  
  /// Project start date
  final DateTime? startDate;
  
  /// Project end date
  final DateTime? endDate;
  
  /// List of tags for categorization
  final List<String> tags;
  
  /// Whether the project is active
  final bool isActive;

  /// Creates a copy of this project with updated fields
  ProjectEntity copyWith({
    String? id,
    String? name,
    String? description,
    ProjectStatus? status,
    List<String>? assignedMembers,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    bool? isActive,
  }) {
    return ProjectEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedMembers: assignedMembers ?? this.assignedMembers,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Creates a ProjectEntity from a Map
  factory ProjectEntity.fromMap(Map<String, dynamic> data, String id) {
    return ProjectEntity(
      id: id,
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      status: ProjectStatus.values.firstWhere(
        (status) => status.value == data['status'],
        orElse: () => ProjectStatus.active,
      ),
      assignedMembers: List<String>.from(data['assignedMembers'] as List? ?? []),
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      tags: List<String>.from(data['tags'] as List? ?? []),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Converts ProjectEntity to a Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'status': status.value,
      'assignedMembers': assignedMembers,
      'createdBy': createdBy,
      'isActive': isActive,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'tags': tags,
    };
  }

  /// Checks if the project is currently active
  bool get isCurrentlyActive => isActive && status == ProjectStatus.active;

  /// Checks if the project is completed
  bool get isCompleted => status == ProjectStatus.completed;

  /// Checks if the project is archived
  bool get isArchived => status == ProjectStatus.archived;

  /// Checks if the project is cancelled
  bool get isCancelled => status == ProjectStatus.cancelled;

  /// Checks if the project has started
  bool get hasStarted => startDate != null && startDate!.isBefore(DateTime.now());

  /// Checks if the project has ended
  bool get hasEnded => endDate != null && endDate!.isBefore(DateTime.now());

  /// Checks if the project is overdue
  bool get isOverdue => !isCompleted && endDate != null && endDate!.isBefore(DateTime.now());

  /// Gets the remaining days until project end
  int get daysUntilEnd {
    if (endDate == null) return -1;
    final now = DateTime.now();
    final difference = endDate!.difference(now);
    return difference.inDays;
  }

  /// Returns a project with updated timestamp
  ProjectEntity withUpdatedTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }

  /// Returns a project marked as completed
  ProjectEntity markAsCompleted() {
    return copyWith(
      status: ProjectStatus.completed,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a project marked as archived
  ProjectEntity markAsArchived() {
    return copyWith(
      status: ProjectStatus.archived,
      isActive: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a project with updated status
  ProjectEntity withStatus(ProjectStatus newStatus) {
    return copyWith(
      status: newStatus,
      isActive: newStatus != ProjectStatus.archived && newStatus != ProjectStatus.cancelled,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        status,
        assignedMembers,
        createdBy,
        createdAt,
        updatedAt,
        startDate,
        endDate,
        tags,
        isActive,
      ];

  @override
  String toString() {
    return 'ProjectEntity(id: $id, name: $name, status: $status, '
        'assignedMembers: $assignedMembers, isActive: $isActive)';
  }
}
