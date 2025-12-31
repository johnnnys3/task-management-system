import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/core/errors/exceptions.dart';

/// Remote data source for tasks using Firebase Firestore
/// This handles the actual communication with the remote database
abstract class TaskRemoteDataSource {
  /// Gets all tasks from remote database
  Future<List<Map<String, dynamic>>> getTasks();

  /// Gets a task by ID from remote database
  Future<Map<String, dynamic>> getTaskById(String id);

  /// Creates a new task in remote database
  Future<String> createTask(Map<String, dynamic> taskData);

  /// Updates an existing task in remote database
  Future<void> updateTask(String id, Map<String, dynamic> taskData);

  /// Deletes a task from remote database
  Future<void> deleteTask(String id);

  /// Gets tasks for a specific date from remote database
  Future<List<Map<String, dynamic>>> getTasksForDate(DateTime date);

  /// Gets tasks for a specific project from remote database
  Future<List<Map<String, dynamic>>> getTasksForProject(String projectId);

  /// Gets tasks assigned to a specific user from remote database
  Future<List<Map<String, dynamic>>> getTasksForUser(String userId);

  /// Searches tasks in remote database
  Future<List<Map<String, dynamic>>> searchTasks(String query);

  /// Gets tasks by status from remote database
  Future<List<Map<String, dynamic>>> getTasksByStatus(String status);

  /// Gets tasks due today from remote database
  Future<List<Map<String, dynamic>>> getTasksDueToday();

  /// Gets task statistics from remote database
  Future<Map<String, int>> getTaskStatistics();

  /// Gets a stream of all tasks for real-time updates
  Stream<List<Map<String, dynamic>>> getTasksStream();

  /// Gets a stream of tasks for a specific project
  Stream<List<Map<String, dynamic>>> getTasksForProjectStream(String projectId);

  /// Gets a stream of tasks assigned to a specific user
  Stream<List<Map<String, dynamic>>> getTasksForUserStream(String userId);
}

/// Implementation of TaskRemoteDataSource using Firebase Firestore
class TaskRemoteDataSourceImpl implements TaskRemoteDataSource {

  TaskRemoteDataSourceImpl(FirebaseFirestore firestore) 
      : _tasksCollection = firestore.collection('tasks');
  final CollectionReference<Map<String, dynamic>> _tasksCollection;

  @override
  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final querySnapshot = await _tasksCollection
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get tasks: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error getting tasks: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> getTaskById(String id) async {
    try {
      final docSnapshot = await _tasksCollection.doc(id).get();
      if (!docSnapshot.exists) {
        throw const ServerException('Task not found', code: 'not-found');
      }
      
      final data = docSnapshot.data()!;
      data['id'] = docSnapshot.id;
      return data;
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw const ServerException('Task not found', code: 'not-found');
      }
      throw ServerException('Failed to get task: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error getting task: ${e.toString()}');
    }
  }

  @override
  Future<String> createTask(Map<String, dynamic> taskData) async {
    try {
      final docRef = await _tasksCollection.add({
        ...taskData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return docRef.id;
    } on FirebaseException catch (e) {
      throw ServerException('Failed to create task: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error creating task: ${e.toString()}');
    }
  }

  @override
  Future<void> updateTask(String id, Map<String, dynamic> taskData) async {
    try {
      await _tasksCollection.doc(id).update({
        ...taskData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw const ServerException('Task not found', code: 'not-found');
      }
      throw ServerException('Failed to update task: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error updating task: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    try {
      await _tasksCollection.doc(id).delete();
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw const ServerException('Task not found', code: 'not-found');
      }
      throw ServerException('Failed to delete task: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error deleting task: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTasksForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _tasksCollection
          .where('dueDate', isGreaterThanOrEqualTo: startOfDay)
          .where('dueDate', isLessThan: endOfDay)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get tasks for date: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error getting tasks for date: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTasksForProject(String projectId) async {
    try {
      final querySnapshot = await _tasksCollection
          .where('projectId', isEqualTo: projectId)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get tasks for project: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error getting tasks for project: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTasksForUser(String userId) async {
    try {
      final querySnapshot = await _tasksCollection
          .where('assignedTo', isEqualTo: userId)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get user tasks: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error getting user tasks: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> searchTasks(String query) async {
    try {
      if (query.isEmpty) {
        return getTasks();
      }

      final querySnapshot = await _tasksCollection
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThanOrEqualTo: '$query\uf8ff')
          .orderBy('title')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to search tasks: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error searching tasks: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTasksByStatus(String status) async {
    try {
      final querySnapshot = await _tasksCollection
          .where('status', isEqualTo: status)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get tasks by status: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error getting tasks by status: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTasksDueToday() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final querySnapshot = await _tasksCollection
          .where('dueDate', isGreaterThanOrEqualTo: startOfDay)
          .where('dueDate', isLessThan: endOfDay)
          .orderBy('dueDate')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get tasks due today: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error getting tasks due today: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, int>> getTaskStatistics() async {
    try {
      final querySnapshot = await _tasksCollection.get();
      
      int completedCount = 0;
      int inProgressCount = 0;
      int todoCount = 0;
      int cancelledCount = 0;

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String?;
        
        switch (status) {
          case 'completed':
            completedCount++;
            break;
          case 'in_progress':
            inProgressCount++;
            break;
          case 'todo':
            todoCount++;
            break;
          case 'cancelled':
            cancelledCount++;
            break;
        }
      }

      return {
        'completed': completedCount,
        'in_progress': inProgressCount,
        'todo': todoCount,
        'cancelled': cancelledCount,
        'total': querySnapshot.docs.length,
      };
    } on FirebaseException catch (e) {
      throw ServerException('Failed to get task statistics: ${e.message}', code: e.code);
    } catch (e) {
      throw UnknownException('Unexpected error getting task statistics: ${e.toString()}');
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> getTasksStream() {
    return _tasksCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> getTasksForProjectStream(String projectId) {
    return _tasksCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }

  @override
  Stream<List<Map<String, dynamic>>> getTasksForUserStream(String userId) {
    return _tasksCollection
        .where('assignedTo', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList());
  }
}
