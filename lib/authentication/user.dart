import 'package:cloud_firestore/cloud_firestore.dart';


/// Represents a user in the task management system
class CustomUser {
  /// Unique identifier for the user
  final String uid;
  
  /// User's email address
  final String email;
  
  /// User's full name
  final String name;
  
  /// User's role in the system
  final String role;
  
  /// List of project IDs assigned to this user
  final List<String> assignedProjects;
  
  /// Timestamp when the user was created
  final DateTime? createdAt;
  
  /// Timestamp when the user was last updated
  final DateTime? updatedAt;
  
  /// Whether the user account is active
  final bool isActive;

  const CustomUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.assignedProjects,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  /// Creates a copy of this user with updated fields
  CustomUser copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    List<String>? assignedProjects,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return CustomUser(
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

  /// Creates a CustomUser from a Firestore document
  factory CustomUser.fromFirestore(Map<String, dynamic> data, String uid) {
    return CustomUser(
      uid: uid,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'regular',
      assignedProjects: List<String>.from(data['assignedProjects'] ?? []),
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  /// Converts the user to a Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'assignedProjects': assignedProjects,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
    };
  }

  /// Creates a CustomUser from JSON
  factory CustomUser.fromJson(Map<String, dynamic> json) {
    return CustomUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      assignedProjects: List<String>.from(json['assignedProjects'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : null,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Converts the user to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'assignedProjects': assignedProjects,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomUser &&
        other.uid == uid &&
        other.email == email &&
        other.name == name &&
        other.role == role &&
        other.assignedProjects == assignedProjects &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        name.hashCode ^
        role.hashCode ^
        assignedProjects.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        isActive.hashCode;
  }

  @override
  String toString() {
    return 'CustomUser(uid: $uid, email: $email, name: $name, role: $role, '
        'assignedProjects: $assignedProjects, isActive: $isActive)';
  }

  /// Validates the user data
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates the user role
  static String? validateRole(String? role) {
    if (role == null || role.isEmpty) {
      return 'Role is required';
    }
    const validRoles = ['admin', 'manager', 'regular'];
    if (!validRoles.contains(role)) {
      return 'Invalid role';
    }
    return null;
  }

  /// Validates the user name
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Name is required';
    }
    if (name.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  /// Validates the UID
  static String? validateUid(String? uid) {
    if (uid == null || uid.isEmpty) {
      return 'UID is required';
    }
    if (uid.length < 20) {
      return 'Invalid UID';
    }
    return null;
  }

  /// Checks if the user has admin privileges
  bool get isAdmin => role == 'admin';

  /// Checks if the user has manager privileges
  bool get isManager => role == 'manager';

  /// Checks if the user is a regular user
  bool get isRegular => role == 'regular';

  /// Gets the display name for the user
  String get displayName => name.isEmpty ? email : name;

  /// Returns a user with updated timestamp
  CustomUser withUpdatedTimestamp() {
    return copyWith(updatedAt: DateTime.now());
  }
}

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
    );
  }
}
