import 'package:equatable/equatable.dart';

/// Enum for user roles
enum UserRole {
  admin('admin'),
  manager('manager'),
  regular('regular');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.regular,
    );
  }
}

/// User entity representing a user in the domain layer
/// This is the pure business object without any infrastructure dependencies
class UserEntity extends Equatable {

  const UserEntity({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.assignedProjects,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });
  /// Unique identifier for the user
  final String uid;
  
  /// User's email address
  final String email;
  
  /// User's full name
  final String name;
  
  /// User's role in the system
  final UserRole role;
  
  /// List of project IDs assigned to this user
  final List<String> assignedProjects;
  
  /// Timestamp when the user was created
  final DateTime? createdAt;
  
  /// Timestamp when the user was last updated
  final DateTime? updatedAt;
  
  /// Whether the user account is active
  final bool isActive;

  /// Creates a copy of this user with updated fields
  UserEntity copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    List<String>? assignedProjects,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      assignedProjects: assignedProjects ?? this.assignedProjects,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Checks if the user has admin privileges
  bool get isAdmin => role == UserRole.admin;

  /// Checks if the user has manager privileges
  bool get isManager => role == UserRole.manager;

  /// Checks if the user is a regular user
  bool get isRegular => role == UserRole.regular;

  /// Gets the display name for the user
  String get displayName => name.isEmpty ? email : name;

  /// Returns a user with updated timestamp
  UserEntity withUpdatedTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        name,
        role,
        assignedProjects,
        createdAt,
        updatedAt,
        isActive,
      ];

  @override
  String toString() {
    return 'UserEntity(uid: $uid, email: $email, name: $name, role: $role, '
        'assignedProjects: $assignedProjects, isActive: $isActive)';
  }
}
