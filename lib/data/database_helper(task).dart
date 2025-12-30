import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:task_management/models/task.dart';

/// Custom exceptions for task database operations
class TaskDatabaseException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  TaskDatabaseException(this.message, {this.code = 'unknown', this.originalError});

  @override
  String toString() => 'TaskDatabaseException: $message';
}

class TaskNotFoundException extends TaskDatabaseException {
  TaskNotFoundException(String taskId) 
      : super('Task not found: $taskId', code: 'task-not-found');
}

class TaskValidationException extends TaskDatabaseException {
  TaskValidationException(super.message) 
      : super(code: 'validation-error');
}

/// Handles all database operations for tasks
class TaskDatabase {
  static final TaskDatabase _instance = TaskDatabase._internal();
  static final Logger _logger = Logger('TaskDatabase');

  factory TaskDatabase() => _instance;

  TaskDatabase._internal();

  final CollectionReference<Map<String, dynamic>> _tasksCollection = 
      FirebaseFirestore.instance.collection('tasks');

  /// Adds a new task to the database
  /// 
  /// Throws [TaskValidationException] if task data is invalid
  /// Throws [TaskDatabaseException] for database errors
  Future<String> addTask(Task task) async {
    try {
      _validateTask(task);
      
      final docRef = await _tasksCollection.add({
        ...task.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Task added successfully: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error adding task', e);
      throw TaskDatabaseException(
        'Failed to add task: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error adding task', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error adding task',
        originalError: e,
      );
    }
  }

  /// Updates an existing task
  /// 
  /// Throws [TaskNotFoundException] if task doesn't exist
  /// Throws [TaskValidationException] if task data is invalid
  Future<void> updateTask(String taskId, Map<String, dynamic> taskData) async {
    if (taskId.isEmpty) {
      throw TaskValidationException('Task ID is required for update');
    }

    try {
      await _tasksCollection.doc(taskId).update({
        ...taskData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Task updated successfully: $taskId');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        _logger.warning('Task not found for update: $taskId');
        throw TaskNotFoundException(taskId);
      }
      _logger.severe('Firebase error updating task', e);
      throw TaskDatabaseException(
        'Failed to update task: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error updating task', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error updating task',
        originalError: e,
      );
    }
  }

  /// Updates an existing task using Task object
  Future<void> updateTaskWithObject(Task task) async {
    if (task.id.isEmpty) {
      throw TaskValidationException('Task ID is required for update');
    }

    try {
      _validateTask(task);
      
      await _tasksCollection.doc(task.id).update({
        ...task.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Task updated successfully: ${task.id}');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        _logger.warning('Task not found for update: ${task.id}');
        throw TaskNotFoundException(task.id);
      }
      _logger.severe('Firebase error updating task', e);
      throw TaskDatabaseException(
        'Failed to update task: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error updating task', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error updating task',
        originalError: e,
      );
    }
  }

  /// Deletes a task by ID
  /// 
  /// Throws [TaskNotFoundException] if task doesn't exist
  Future<void> deleteTask(String taskId) async {
    if (taskId.isEmpty) {
      throw TaskValidationException('Task ID is required');
    }

    try {
      await _tasksCollection.doc(taskId).delete();
      _logger.info('Task deleted successfully: $taskId');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        _logger.warning('Task not found for deletion: $taskId');
        throw TaskNotFoundException(taskId);
      }
      _logger.severe('Firebase error deleting task', e);
      throw TaskDatabaseException(
        'Failed to delete task: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error deleting task', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error deleting task',
        originalError: e,
      );
    }
  }

  /// Fetches all tasks
  Future<List<Task>> fetchTasks() async {
    try {
      final querySnapshot = await _tasksCollection
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromMap(data);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching all tasks', e);
      throw TaskDatabaseException(
        'Failed to fetch tasks: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching all tasks', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error fetching tasks',
        originalError: e,
      );
    }
  }

  /// Fetches a single task by ID
  /// 
  /// Throws [TaskNotFoundException] if task doesn't exist
  Future<Task?> getTask(String taskId) async {
    if (taskId.isEmpty) {
      throw TaskValidationException('Task ID is required');
    }

    try {
      final docSnapshot = await _tasksCollection.doc(taskId).get();
      if (!docSnapshot.exists) {
        throw TaskNotFoundException(taskId);
      }
      
      final data = docSnapshot.data()!;
      data['id'] = docSnapshot.id;
      
      return Task.fromMap(data);
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching task', e);
      throw TaskDatabaseException(
        'Failed to fetch task: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching task', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error fetching task',
        originalError: e,
      );
    }
  }

  /// Fetches tasks for a specific date range
  Future<List<Task>> fetchTasksForDate(DateTime selectedDate) async {
    try {
      final startOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _tasksCollection
          .where('dueDate', isGreaterThanOrEqualTo: startOfDay)
          .where('dueDate', isLessThan: endOfDay)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromMap(data);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching tasks for date', e);
      throw TaskDatabaseException(
        'Failed to fetch tasks for date: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching tasks for date', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error fetching tasks for date',
        originalError: e,
      );
    }
  }

  /// Fetches tasks for a specific due date (exact match)
  Future<List<Task>> fetchTasksForDueDate(DateTime dueDate) async {
    try {
      final dueDateStr = dueDate.toIso8601String();
      final querySnapshot = await _tasksCollection
          .where('dueDate', isEqualTo: dueDateStr)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromMap(data);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching tasks for due date', e);
      throw TaskDatabaseException(
        'Failed to fetch tasks for due date: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching tasks for due date', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error fetching tasks for due date',
        originalError: e,
      );
    }
  }

  /// Fetches tasks for a specific project
  Future<List<Task>> fetchTasksForProject(String projectId) async {
    if (projectId.isEmpty) {
      throw TaskValidationException('Project ID is required');
    }

    try {
      final querySnapshot = await _tasksCollection
          .where('projectId', isEqualTo: projectId)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromMap(data);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching tasks for project', e);
      throw TaskDatabaseException(
        'Failed to fetch tasks for project: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching tasks for project', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error fetching tasks for project',
        originalError: e,
      );
    }
  }

  /// Fetches tasks for a specific user
  Future<List<Task>> fetchTasksForUser(String userId) async {
    if (userId.isEmpty) {
      throw TaskValidationException('User ID is required');
    }

    try {
      final querySnapshot = await _tasksCollection
          .where('assignedTo', isEqualTo: userId)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromMap(data);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching user tasks', e);
      throw TaskDatabaseException(
        'Failed to fetch user tasks: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching user tasks', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error fetching user tasks',
        originalError: e,
      );
    }
  }

  /// Searches tasks by title or description
  Future<List<Task>> searchTasks(String query) async {
    if (query.isEmpty) {
      return fetchTasks();
    }

    try {
      final querySnapshot = await _tasksCollection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('title')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromMap(data);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error searching tasks', e);
      throw TaskDatabaseException(
        'Failed to search tasks: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error searching tasks', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error searching tasks',
        originalError: e,
      );
    }
  }

  /// Fetches tasks by status
  Future<List<Task>> fetchTasksByStatus(String status) async {
    if (status.isEmpty) {
      throw TaskValidationException('Status is required');
    }

    try {
      final querySnapshot = await _tasksCollection
          .where('status', isEqualTo: status)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Task.fromMap(data);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching tasks by status', e);
      throw TaskDatabaseException(
        'Failed to fetch tasks by status: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching tasks by status', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error fetching tasks by status',
        originalError: e,
      );
    }
  }

  /// Performs a batch update of multiple tasks
  Future<void> batchUpdateTasks(List<Task> tasks) async {
    if (tasks.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();
    try {
      for (final task in tasks) {
        if (task.id.isEmpty) {
          throw TaskValidationException('All tasks must have IDs for batch update');
        }
        
        _validateTask(task);
        
        final docRef = _tasksCollection.doc(task.id);
        batch.update(docRef, {
          ...task.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      _logger.info('Batch update completed for ${tasks.length} tasks');
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error in batch update', e);
      throw TaskDatabaseException(
        'Failed to batch update tasks: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error in batch update', e, stackTrace);
      throw TaskDatabaseException(
        'Unexpected error in batch update',
        originalError: e,
      );
    }
  }

  /// Validates task data before database operations
  void _validateTask(Task task) {
    if (task.title.isEmpty) {
      throw TaskValidationException('Task title is required');
    }
    if (task.title.length > 200) {
      throw TaskValidationException('Task title must be less than 200 characters');
    }
    if (task.description.length > 1000) {
      throw TaskValidationException('Task description must be less than 1000 characters');
    }
  }

  /// Gets a stream of all tasks for real-time updates
  Stream<List<Task>> getTasksStream() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Task.fromMap(data);
        }).toList());
  }

  /// Gets a stream of tasks for a specific project
  Stream<List<Task>> getTasksForProjectStream(String projectId) {
    if (projectId.isEmpty) {
      throw TaskValidationException('Project ID is required');
    }

    return _tasksCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Task.fromMap(data);
        }).toList());
  }

  /// Gets a stream of tasks for a specific user
  Stream<List<Task>> getTasksForUserStream(String userId) {
    if (userId.isEmpty) {
      throw TaskValidationException('User ID is required');
    }

    return _tasksCollection
        .where('assignedTo', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Task.fromMap(data);
        }).toList());
  }
}