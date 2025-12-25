// models/team.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for team status
enum TeamStatus {
  active('active'),
  inactive('inactive'),
  archived('archived');

  const TeamStatus(this.value);
  final String value;

  static TeamStatus fromString(String value) {
    return TeamStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TeamStatus.active,
    );
  }
}

/// Enum for team roles
enum TeamRole {
  owner('owner'),
  admin('admin'),
  member('member'),
  viewer('viewer');

  const TeamRole(this.value);
  final String value;

  static TeamRole fromString(String value) {
    return TeamRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => TeamRole.member,
    );
  }
}

/// Represents a team in the task management system
class Team {
  /// Unique identifier for the team
  final String id;
  
  /// Name of the team
  final String name;
  
  /// Detailed description of the team
  final String description;
  
  /// List of user IDs of team members with their roles
  final Map<String, TeamRole> members;
  
  /// List of project IDs associated with the team
  final List<String> projects;
  
  /// Current status of the team
  final TeamStatus status;
  
  /// User ID who created this team
  final String? createdBy;
  
  /// List of user IDs who are team admins
  final List<String> admins;
  
  /// Team avatar or logo URL
  final String? avatarUrl;
  
  /// Team color theme (hex color code)
  final String? color;
  
  /// Maximum number of members allowed (null for unlimited)
  final int? maxMembers;
  
  /// Whether the team is private (invite-only) or public
  final bool isPrivate;
  
  /// Timestamp when the team was created
  final DateTime? createdAt;
  
  /// Timestamp when the team was last updated
  final DateTime? updatedAt;
  
  /// Timestamp when the team was archived
  final DateTime? archivedAt;

  const Team({
    required this.id,
    required this.name,
    this.description = '',
    this.members = const {},
    this.projects = const [],
    this.status = TeamStatus.active,
    this.createdBy,
    this.admins = const [],
    this.avatarUrl,
    this.color,
    this.maxMembers,
    this.isPrivate = false,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  /// Creates a Team from a Map with validation
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  factory Team.fromMap(Map<String, dynamic> map, [String? id]) {
    // Validate required fields
    if (map['name'] == null || map['name'].toString().trim().isEmpty) {
      throw ArgumentError('Team name is required');
    }

    // Parse members with roles
    Map<String, TeamRole> members = {};
    if (map['members'] != null) {
      final membersData = map['members'] as Map<String, dynamic>;
      for (final entry in membersData.entries) {
        members[entry.key] = TeamRole.fromString(entry.value.toString());
      }
    }

    return Team(
      id: id ?? map['id'] ?? '',
      name: map['name'].toString().trim(),
      description: map['description']?.toString().trim() ?? '',
      members: members,
      projects: map['projects'] != null 
          ? List<String>.from(map['projects'])
          : const [],
      status: map['status'] != null 
          ? TeamStatus.fromString(map['status'].toString())
          : TeamStatus.active,
      createdBy: map['createdBy']?.toString(),
      admins: map['admins'] != null 
          ? List<String>.from(map['admins'])
          : const [],
      avatarUrl: map['avatarUrl']?.toString(),
      color: map['color']?.toString(),
      maxMembers: map['maxMembers']?.toInt(),
      isPrivate: map['isPrivate'] ?? false,
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
      archivedAt: map['archivedAt'] != null 
          ? (map['archivedAt'] is Timestamp 
              ? (map['archivedAt'] as Timestamp).toDate()
              : DateTime.parse(map['archivedAt'] as String))
          : null,
    );
  }

  /// Creates a Team from a Firestore DocumentSnapshot
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  factory Team.fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists) {
      throw ArgumentError('Document does not exist');
    }

    final data = snapshot.data()!;
    return Team.fromMap(data, snapshot.id);
  }

  /// Creates a Team from JSON
  /// 
  /// Throws [ArgumentError] if required fields are missing or invalid
  factory Team.fromJson(Map<String, dynamic> json) {
    return Team.fromMap(json, json['id'] as String);
  }

  /// Creates a copy of this team with updated fields
  Team copyWith({
    String? id,
    String? name,
    String? description,
    Map<String, TeamRole>? members,
    List<String>? projects,
    TeamStatus? status,
    String? createdBy,
    List<String>? admins,
    String? avatarUrl,
    String? color,
    int? maxMembers,
    bool? isPrivate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      projects: projects ?? this.projects,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      admins: admins ?? this.admins,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      color: color ?? this.color,
      maxMembers: maxMembers ?? this.maxMembers,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: archivedAt ?? this.archivedAt,
    );
  }

  /// Converts the team to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'members': members.map((key, value) => MapEntry(key, value.value)),
      'projects': projects,
      'status': status.value,
      'createdBy': createdBy,
      'admins': admins,
      'avatarUrl': avatarUrl,
      'color': color,
      'maxMembers': maxMembers,
      'isPrivate': isPrivate,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
    };
  }

  /// Converts the team to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'members': members.map((key, value) => MapEntry(key, value.value)),
      'projects': projects,
      'status': status.value,
      'createdBy': createdBy,
      'admins': admins,
      'avatarUrl': avatarUrl,
      'color': color,
      'maxMembers': maxMembers,
      'isPrivate': isPrivate,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Team &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.members == members &&
        other.projects == projects &&
        other.status == status &&
        other.createdBy == createdBy &&
        other.admins == admins &&
        other.avatarUrl == avatarUrl &&
        other.color == color &&
        other.maxMembers == maxMembers &&
        other.isPrivate == isPrivate &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.archivedAt == archivedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        members.hashCode ^
        projects.hashCode ^
        status.hashCode ^
        createdBy.hashCode ^
        admins.hashCode ^
        avatarUrl.hashCode ^
        color.hashCode ^
        maxMembers.hashCode ^
        isPrivate.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        archivedAt.hashCode;
  }

  @override
  String toString() {
    return 'Team(id: $id, name: $name, status: $status, members: ${members.length}, '
        'projects: ${projects.length}, isPrivate: $isPrivate)';
  }

  /// Validates the team data
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Team name is required';
    }
    if (name.trim().length < 2) {
      return 'Team name must be at least 2 characters';
    }
    if (name.trim().length > 50) {
      return 'Team name must be less than 50 characters';
    }
    return null;
  }

  /// Validates the team description
  static String? validateDescription(String? description) {
    if (description != null && description.trim().length > 500) {
      return 'Team description must be less than 500 characters';
    }
    return null;
  }

  /// Checks if a user is a member of the team
  bool isMember(String userId) {
    return members.containsKey(userId);
  }

  /// Checks if a user is an admin of the team
  bool isAdmin(String userId) {
    return admins.contains(userId) || members[userId] == TeamRole.admin || members[userId] == TeamRole.owner;
  }

  /// Checks if a user is the owner of the team
  bool isOwner(String userId) {
    return members[userId] == TeamRole.owner || createdBy == userId;
  }

  /// Gets the role of a user in the team
  TeamRole? getUserRole(String userId) {
    return members[userId];
  }

  /// Checks if the team is at maximum capacity
  bool get isAtMaxCapacity => maxMembers != null && members.length >= maxMembers!;

  /// Checks if the team can accept new members
  bool get canAcceptMembers => !isAtMaxCapacity && status == TeamStatus.active;

  /// Gets the number of members in each role
  Map<TeamRole, int> get memberCountsByRole {
    final counts = <TeamRole, int>{};
    for (final role in TeamRole.values) {
      counts[role] = 0;
    }
    for (final role in members.values) {
      counts[role] = (counts[role] ?? 0) + 1;
    }
    return counts;
  }

  /// Returns a team with updated timestamp
  Team withUpdatedTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }

  /// Returns a team with a new member added
  Team withMember(String userId, {TeamRole role = TeamRole.member}) {
    final newMembers = Map<String, TeamRole>.from(members);
    newMembers[userId] = role;
    return copyWith(
      members: newMembers,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a team with a member removed
  Team withoutMember(String userId) {
    final newMembers = Map<String, TeamRole>.from(members);
    newMembers.remove(userId);
    final newAdmins = List<String>.from(admins)..remove(userId);
    return copyWith(
      members: newMembers,
      admins: newAdmins,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a team with updated member role
  Team withMemberRole(String userId, TeamRole newRole) {
    final newMembers = Map<String, TeamRole>.from(members);
    newMembers[userId] = newRole;
    return copyWith(
      members: newMembers,
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a team with a project added
  Team withProject(String projectId) {
    if (!projects.contains(projectId)) {
      return copyWith(
        projects: [...projects, projectId],
        updatedAt: DateTime.now(),
      );
    }
    return this;
  }

  /// Returns a team with a project removed
  Team withoutProject(String projectId) {
    return copyWith(
      projects: projects.where((id) => id != projectId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a team marked as archived
  Team markAsArchived() {
    return copyWith(
      status: TeamStatus.archived,
      archivedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Returns a team with updated status
  Team withStatus(TeamStatus newStatus) {
    return copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      archivedAt: newStatus == TeamStatus.archived ? DateTime.now() : archivedAt,
    );
  }
}
