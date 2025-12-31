import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:task_management/core/errors/exceptions.dart';
import 'package:task_management/core/errors/failures.dart';
import 'package:task_management/core/utils/either.dart';
import 'package:task_management/data/datasources/task_remote_datasource.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import 'package:task_management/domain/repositories/task_repository.dart';

/// Implementation of TaskRepository
/// This bridges the domain layer with the data layer
class TaskRepositoryImpl implements TaskRepository {

  TaskRepositoryImpl(this._remoteDataSource);
  final TaskRemoteDataSource _remoteDataSource;

  @override
  Future<Result<List<TaskEntity>>> getTasks() async {
    try {
      final taskMaps = await _remoteDataSource.getTasks();
      final tasks = taskMaps.map(_mapToTaskEntity).toList();
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting tasks: ${e.toString()}'));
    }
  }

  @override
  Stream<List<TaskEntity>> getTasksStream() {
    return _remoteDataSource.getTasksStream().map((taskMaps) {
      return taskMaps.map(_mapToTaskEntity).toList();
    });
  }

  @override
  Future<Result<TaskEntity>> getTaskById(String id) async {
    try {
      final taskMap = await _remoteDataSource.getTaskById(id);
      final task = _mapToTaskEntity(taskMap);
      return Right(task);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting task: ${e.toString()}'));
    }
  }

  @override
  Future<Result<String>> createTask(TaskEntity task) async {
    try {
      final taskMap = _mapToTaskMap(task);
      final taskId = await _remoteDataSource.createTask(taskMap);
      return Right(taskId);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error creating task: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> updateTask(TaskEntity task) async {
    try {
      final taskMap = _mapToTaskMap(task);
      await _remoteDataSource.updateTask(task.id, taskMap);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error updating task: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> deleteTask(String id) async {
    try {
      await _remoteDataSource.deleteTask(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error deleting task: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksForDate(DateTime date) async {
    try {
      final taskMaps = await _remoteDataSource.getTasksForDate(date);
      final tasks = taskMaps.map(_mapToTaskEntity).toList();
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting tasks for date: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksForDateRange(DateTime startDate, DateTime endDate) async {
    // For now, we'll implement this using multiple calls to getTasksForDate
    // In a real implementation, you might want to add this method to the data source
    try {
      final List<TaskEntity> allTasks = [];
      DateTime currentDate = startDate;
      
      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        final result = await getTasksForDate(currentDate);
        result.fold(
          (failure) => throw failure,
          (tasks) => allTasks.addAll(tasks),
        );
        currentDate = currentDate.add(const Duration(days: 1));
      }
      
      return Right(allTasks);
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting tasks for date range: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksForProject(String projectId) async {
    try {
      final taskMaps = await _remoteDataSource.getTasksForProject(projectId);
      final tasks = taskMaps.map(_mapToTaskEntity).toList();
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting tasks for project: ${e.toString()}'));
    }
  }

  @override
  Stream<List<TaskEntity>> getTasksForProjectStream(String projectId) {
    return _remoteDataSource.getTasksForProjectStream(projectId).map((taskMaps) {
      return taskMaps.map(_mapToTaskEntity).toList();
    });
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksForUser(String userId) async {
    try {
      final taskMaps = await _remoteDataSource.getTasksForUser(userId);
      final tasks = taskMaps.map(_mapToTaskEntity).toList();
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting user tasks: ${e.toString()}'));
    }
  }

  @override
  Stream<List<TaskEntity>> getTasksForUserStream(String userId) {
    return _remoteDataSource.getTasksForUserStream(userId).map((taskMaps) {
      return taskMaps.map(_mapToTaskEntity).toList();
    });
  }

  @override
  Future<Result<List<TaskEntity>>> searchTasks(String query) async {
    try {
      final taskMaps = await _remoteDataSource.searchTasks(query);
      final tasks = taskMaps.map(_mapToTaskEntity).toList();
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error searching tasks: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksByStatus(String status) async {
    try {
      final taskMaps = await _remoteDataSource.getTasksByStatus(status);
      final tasks = taskMaps.map(_mapToTaskEntity).toList();
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting tasks by status: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksByPriority(String priority) async {
    // This would need to be implemented in the data source
    // For now, we'll get all tasks and filter
    try {
      final result = await getTasks();
      return result.fold(
        (failure) => Left(failure),
        (tasks) {
          final filteredTasks = tasks.where((task) => task.priority.value == priority).toList();
          return Right(filteredTasks);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting tasks by priority: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksDueToday() async {
    try {
      final taskMaps = await _remoteDataSource.getTasksDueToday();
      final tasks = taskMaps.map(_mapToTaskEntity).toList();
      return Right(tasks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting tasks due today: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getOverdueTasks() async {
    try {
      final result = await getTasks();
      return result.fold(
        (failure) => Left(failure),
        (tasks) {
          final overdueTasks = tasks.where((task) => task.isOverdue).toList();
          return Right(overdueTasks);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting overdue tasks: ${e.toString()}'));
    }
  }

  @override
  Future<Result<List<TaskEntity>>> getTasksDueSoon({int days = 3}) async {
    try {
      final result = await getTasks();
      return result.fold(
        (failure) => Left(failure),
        (tasks) {
          final dueSoonTasks = tasks.where((task) => task.isDueSoon).toList();
          return Right(dueSoonTasks);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting tasks due soon: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> batchUpdateTasks(List<TaskEntity> tasks) async {
    try {
      for (final task in tasks) {
        final taskMap = _mapToTaskMap(task);
        await _remoteDataSource.updateTask(task.id, taskMap);
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error batch updating tasks: ${e.toString()}'));
    }
  }

  @override
  Future<Result<void>> batchDeleteTasks(List<String> taskIds) async {
    try {
      for (final taskId in taskIds) {
        await _remoteDataSource.deleteTask(taskId);
      }
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error batch deleting tasks: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Map<String, int>>> getTaskStatistics() async {
    try {
      final statistics = await _remoteDataSource.getTaskStatistics();
      return Right(statistics);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, code: e.code));
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting task statistics: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Map<String, int>>> getTaskStatisticsForProject(String projectId) async {
    // This would need to be implemented in the data source
    // For now, we'll get all project tasks and calculate statistics
    try {
      final result = await getTasksForProject(projectId);
      return result.fold(
        (failure) => Left(failure),
        (tasks) {
          final statistics = <String, int>{};
          statistics['completed'] = tasks.where((t) => t.status == TaskStatus.completed).length;
          statistics['in_progress'] = tasks.where((t) => t.status == TaskStatus.inProgress).length;
          statistics['todo'] = tasks.where((t) => t.status == TaskStatus.todo).length;
          statistics['cancelled'] = tasks.where((t) => t.status == TaskStatus.cancelled).length;
          statistics['total'] = tasks.length;
          return Right(statistics);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting project statistics: ${e.toString()}'));
    }
  }

  @override
  Future<Result<Map<String, int>>> getTaskStatisticsForUser(String userId) async {
    // This would need to be implemented in the data source
    // For now, we'll get all user tasks and calculate statistics
    try {
      final result = await getTasksForUser(userId);
      return result.fold(
        (failure) => Left(failure),
        (tasks) {
          final statistics = <String, int>{};
          statistics['completed'] = tasks.where((t) => t.status == TaskStatus.completed).length;
          statistics['in_progress'] = tasks.where((t) => t.status == TaskStatus.inProgress).length;
          statistics['todo'] = tasks.where((t) => t.status == TaskStatus.todo).length;
          statistics['cancelled'] = tasks.where((t) => t.status == TaskStatus.cancelled).length;
          statistics['total'] = tasks.length;
          return Right(statistics);
        },
      );
    } catch (e) {
      return Left(UnknownFailure('Unexpected error getting user statistics: ${e.toString()}'));
    }
  }

  /// Maps a Map from data source to TaskEntity
  TaskEntity _mapToTaskEntity(Map<String, dynamic> map) {
    return TaskEntity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      dueDate: _parseDateTime(map['dueDate']),
      attachments: List<String>.from(map['attachments'] as List? ?? []),
      isCompleted: map['isCompleted'] as bool? ?? false,
      status: TaskStatus.fromString(map['status'] as String? ?? 'todo'),
      priority: TaskPriority.fromString(map['priority'] as String? ?? 'medium'),
      projectId: map['projectId'] as String?,
      assignedMembers: List<String>.from(map['assignedMembers'] as List? ?? []),
      createdBy: map['createdBy'] as String?,
      assignedTo: map['assignedTo'] as String?,
      estimatedHours: (map['estimatedHours'] as num?)?.toDouble(),
      actualHours: (map['actualHours'] as num?)?.toDouble(),
      tags: List<String>.from(map['tags'] as List? ?? []),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      completedAt: _parseDateTime(map['completedAt']),
    );
  }

  /// Maps TaskEntity to Map for data source
  Map<String, dynamic> _mapToTaskMap(TaskEntity task) {
    return {
      'id': task.id,
      'title': task.title,
      'description': task.description,
      'dueDate': task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
      'attachments': task.attachments,
      'isCompleted': task.isCompleted,
      'status': task.status.value,
      'priority': task.priority.value,
      'projectId': task.projectId,
      'assignedMembers': task.assignedMembers,
      'createdBy': task.createdBy,
      'assignedTo': task.assignedTo,
      'estimatedHours': task.estimatedHours,
      'actualHours': task.actualHours,
      'tags': task.tags,
      'createdAt': task.createdAt != null ? Timestamp.fromDate(task.createdAt!) : null,
      'updatedAt': task.updatedAt != null ? Timestamp.fromDate(task.updatedAt!) : null,
      'completedAt': task.completedAt != null ? Timestamp.fromDate(task.completedAt!) : null,
    };
  }

  /// Parses DateTime from various formats
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return null;
  }
}
