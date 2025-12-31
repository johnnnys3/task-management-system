import 'package:task_management/core/utils/either.dart';
import 'package:task_management/domain/entities/project_entity.dart';

/// Repository interface for project operations
/// This defines the contract for project data operations in the domain layer
abstract class ProjectRepository {
  /// Gets all projects
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> getProjects();

  /// Gets a stream of all projects for real-time updates
  /// Returns [Stream<List<ProjectEntity>>] that emits lists of projects
  Stream<List<ProjectEntity>> getProjectsStream();

  /// Gets a project by ID
  /// Returns [Result<ProjectEntity>] with either the project or a failure
  Future<Result<ProjectEntity>> getProjectById(String id);

  /// Creates a new project
  /// Returns [Result<String>] with either the project ID or a failure
  Future<Result<String>> createProject(ProjectEntity project);

  /// Updates an existing project
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> updateProject(ProjectEntity project);

  /// Deletes a project
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> deleteProject(String id);

  /// Gets projects created by a specific user
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> getProjectsByCreator(String userId);

  /// Gets projects assigned to a specific user
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> getProjectsForUser(String userId);

  /// Gets a stream of projects assigned to a specific user
  /// Returns [Stream<List<ProjectEntity>>] that emits lists of projects
  Stream<List<ProjectEntity>> getProjectsForUserStream(String userId);

  /// Searches projects by name or description
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> searchProjects(String query);

  /// Gets projects by status
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> getProjectsByStatus(String status);

  /// Gets active projects
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> getActiveProjects();

  /// Gets completed projects
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> getCompletedProjects();

  /// Gets archived projects
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> getArchivedProjects();

  /// Gets projects due within a specified date range
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> getProjectsDueInRange(DateTime startDate, DateTime endDate);

  /// Gets overdue projects
  /// Returns [Result<List<ProjectEntity>>] with either a list of projects or a failure
  Future<Result<List<ProjectEntity>>> getOverdueProjects();

  /// Updates multiple projects in a batch
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> batchUpdateProjects(List<ProjectEntity> projects);

  /// Deletes multiple projects in a batch
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> batchDeleteProjects(List<String> projectIds);

  /// Assigns users to a project
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> assignUsersToProject(String projectId, List<String> userIds);

  /// Removes users from a project
  /// Returns [Result<void>] with either success or a failure
  Future<Result<void>> removeUsersFromProject(String projectId, List<String> userIds);

  /// Gets project statistics
  /// Returns [Result<Map<String, int>>] with either statistics or a failure
  Future<Result<Map<String, int>>> getProjectStatistics();

  /// Checks if project exists
  /// Returns [Result<bool>] with either true/false or a failure
  Future<Result<bool>> projectExists(String projectId);
}
