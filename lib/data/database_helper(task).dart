import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:task_management/domain/entities/task_entity.dart';

/// Custom exceptions for task database operations
class TaskDatabaseException implements Exception {
  TaskDatabaseException(
    this.message, {
    this.code = 'unknown',
    this.originalError,
  });

  final String message;
  final String code;
  final dynamic originalError;

  @override
  String toString() => 'TaskDatabaseException: $message';
}

class TaskNotFoundException extends TaskDatabaseException {
  TaskNotFoundException(String taskId)
      : super(
          'Task not found: $taskId',
          code: 'task-not-found',
        );
}

class TaskValidationException extends TaskDatabaseException {
  TaskValidationException(String message)
      : super(message, code: 'validation-error');
}

/// Handles all database operations for tasks
class TaskDatabase {
  static final Logger _logger = Logger('TaskDatabase');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'tasks';

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  /// Adds a new task to the database
  Future<String> addTask(TaskEntity task) async {
    try {
      _validateTask(task);
      
      final docRef = await _collection.add({
        ...task.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Task added successfully: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      throw TaskDatabaseException(
        'Failed to add task: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw TaskDatabaseException(
        'Unexpected error adding task',
        originalError: e,
      );
    }
  }

  /// Updates an existing task
  Future<void> updateTask(TaskEntity task) async {
    if (task.id.isEmpty) {
      throw TaskValidationException('Task ID is required for update');
    }

    try {
      _validateTask(task);
      
      await _collection.doc(task.id).update({
        ...task.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Task updated successfully: ${task.id}');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw TaskNotFoundException(task.id);
      }
      throw TaskDatabaseException(
        'Failed to update task: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw TaskDatabaseException(
        'Unexpected error updating task',
        originalError: e,
      );
    }
  }

  /// Deletes a task by ID
  Future<void> deleteTask(String taskId) async {
    if (taskId.isEmpty) {
      throw TaskValidationException('Task ID is required');
    }

    try {
      await _collection.doc(taskId).delete();
      _logger.info('Task deleted successfully: $taskId');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw TaskNotFoundException(taskId);
      }
      throw TaskDatabaseException(
        'Failed to delete task: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw TaskDatabaseException(
        'Unexpected error deleting task',
        originalError: e,
      );
    }
  }

  /// Fetches a task by ID
  Future<TaskEntity> getTask(String taskId) async {
    if (taskId.isEmpty) {
      throw TaskValidationException('Task ID is required');
    }

    try {
      final doc = await _collection.doc(taskId).get();
      if (!doc.exists) {
        throw TaskNotFoundException(taskId);
      }

      return TaskEntity.fromMap(doc.data()!, doc.id);
    } on FirebaseException catch (e) {
      throw TaskDatabaseException(
        'Failed to fetch task: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e) {
      throw TaskDatabaseException(
        'Unexpected error fetching task',
        originalError: e,
      );
    }
  }

  /// Fetches all tasks
  Future<List<TaskEntity>> getAllTasks() async {
    try {
      _logger.info('Fetching all tasks from collection: $_collectionName');
      print('TaskDatabase: Fetching all tasks from collection: $_collectionName');
      
      final snapshot = await _collection.get();
      _logger.info('Retrieved ${snapshot.docs.length} documents from Firestore');
      print('TaskDatabase: Retrieved ${snapshot.docs.length} documents from Firestore');
      
      final tasks = snapshot.docs
          .map((doc) {
            _logger.fine('Processing document: ${doc.id}');
            print('TaskDatabase: Processing document: ${doc.id}');
            return TaskEntity.fromMap(doc.data(), doc.id);
          })
          .toList();
      
      _logger.info('Successfully processed ${tasks.length} tasks');
      print('TaskDatabase: Successfully processed ${tasks.length} tasks');
      return tasks;
    } catch (e) {
      _logger.severe('Failed to fetch tasks: $e');
      print('TaskDatabase: Failed to fetch tasks: $e');
      print('TaskDatabase: Error type: ${e.runtimeType}');
      
      // Check if it's a FirebaseException
      if (e is FirebaseException) {
        print('TaskDatabase: FirebaseException details:');
        print('  - Code: ${e.code}');
        print('  - Message: ${e.message}');
        print('  - Plugin: ${e.plugin}');
      }
      
      throw TaskDatabaseException(
        'Failed to fetch tasks',
        originalError: e,
      );
    }
  }

  /// Fetches tasks for a specific user
  Future<List<TaskEntity>> getTasksForUser(String userId) async {
    if (userId.isEmpty) {
      throw TaskValidationException('User ID is required');
    }

    try {
      _logger.info('Fetching tasks for user: $userId');
      final snapshot = await _collection
          .where('assignedTo', isEqualTo: userId)
          .orderBy('dueDate')
          .get();
      
      _logger.info('Retrieved ${snapshot.docs.length} tasks for user $userId');

      final tasks = snapshot.docs
          .map((doc) {
            _logger.fine('Processing user task document: ${doc.id}');
            return TaskEntity.fromMap(doc.data(), doc.id);
          })
          .toList();
      
      _logger.info('Successfully processed ${tasks.length} tasks for user $userId');
      return tasks;
    } catch (e) {
      _logger.severe('Failed to fetch user tasks: $e');
      throw TaskDatabaseException(
        'Failed to fetch user tasks',
        originalError: e,
      );
    }
  }

  /// Fetches tasks for a specific project
  Future<List<TaskEntity>> getTasksForProject(String projectId) async {
    if (projectId.isEmpty) {
      throw TaskValidationException('Project ID is required');
    }

    try {
      final snapshot = await _collection
          .where('projectId', isEqualTo: projectId)
          .orderBy('dueDate')
          .get();

      return snapshot.docs
          .map((doc) => TaskEntity.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw TaskDatabaseException(
        'Failed to fetch project tasks',
        originalError: e,
      );
    }
  }

  /// Searches tasks by title or description
  Future<List<TaskEntity>> searchTasks(String query) async {
    if (query.isEmpty) return getAllTasks();

    try {
      final snapshot = await _collection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('title')
          .get();

      return snapshot.docs
          .map((doc) => TaskEntity.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw TaskDatabaseException(
        'Failed to search tasks',
        originalError: e,
      );
    }
  }

  /// Batch update tasks
  Future<void> batchUpdateTasks(List<TaskEntity> tasks) async {
    if (tasks.isEmpty) return;

    final batch = _firestore.batch();

    try {
      for (final task in tasks) {
        if (task.id.isEmpty) {
          throw TaskValidationException('All tasks must have IDs for batch update');
        }

        _validateTask(task);

        batch.update(
          _collection.doc(task.id),
          {
            ...task.toMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      }

      await batch.commit();
      _logger.info('Batch updated ${tasks.length} tasks');
    } catch (e) {
      throw TaskDatabaseException(
        'Failed to batch update tasks',
        originalError: e,
      );
    }
  }

  /// Real-time stream of all tasks
  Stream<List<TaskEntity>> getTasksStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskEntity.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Real-time stream of tasks for a user
  Stream<List<TaskEntity>> getTasksForUserStream(String userId) {
    if (userId.isEmpty) {
      throw TaskValidationException('User ID is required');
    }

    return _collection
        .where('assignedTo', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskEntity.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Real-time stream of tasks for a project
  Stream<List<TaskEntity>> getTasksForProjectStream(String projectId) {
    if (projectId.isEmpty) {
      throw TaskValidationException('Project ID is required');
    }

    return _collection
        .where('projectId', isEqualTo: projectId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TaskEntity.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Validates task data before database operations
  void _validateTask(TaskEntity task) {
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
}
