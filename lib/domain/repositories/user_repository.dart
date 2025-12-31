import 'package:task_management/core/utils/either.dart';
import 'package:task_management/domain/entities/user_entity.dart';

/// Repository interface for user operations
/// This defines the contract for user data operations in the domain layer
abstract class UserRepository {
  /// Gets a user by ID
  /// Returns [Result<UserEntity>] with either the user or a failure
  Future<Result<UserEntity>> getUserById(String id);

  /// Gets the currently authenticated user
  /// Returns [Result<UserEntity>] with either the user or a failure
  Future<Result<UserEntity>> getCurrentUser();

  /// Creates a new user
  /// Returns [Result<String>] with either the user ID or a failure
  Future<Result<String>> createUser(UserEntity user);

  /// Updates an existing user
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> updateUser(UserEntity user);

  /// Deletes a user
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> deleteUser(String id);

  /// Gets all users
  /// Returns [Result<List<UserEntity>>] with either a list of users or a failure
  Future<Result<List<UserEntity>>> getAllUsers();

  /// Searches users by name or email
  /// Returns [Result<List<UserEntity>>] with either a list of users or a failure
  Future<Result<List<UserEntity>>> searchUsers(String query);

  /// Gets users by role
  /// Returns [Result<List<UserEntity>>] with either a list of users or a failure
  Future<Result<List<UserEntity>>> getUsersByRole(String role);

  /// Gets users assigned to a specific project
  /// Returns [Result<List<UserEntity>>] with either a list of users or a failure
  Future<Result<List<UserEntity>>> getUsersForProject(String projectId);

  /// Updates user role
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> updateUserRole(String userId, String newRole);

  /// Activates or deactivates a user
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> updateUserStatus(String userId, bool isActive);

  /// Assigns user to projects
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> assignUserToProjects(String userId, List<String> projectIds);

  /// Removes user from projects
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> removeUserFromProjects(String userId, List<String> projectIds);

  /// Checks if user exists
  /// Returns [Result<bool>] with either true/false or a failure
  Future<Result<bool>> userExists(String userId);

  /// Gets user statistics
  /// Returns [Result<Map<String, int>>] with either statistics or a failure
  Future<Result<Map<String, int>>> getUserStatistics();
}
