import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:task_management/data/task_search.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/models/task.dart';

/// Firestore-backed [TaskStore] implementation.
class TaskDatabase implements TaskStore {
  static final TaskDatabase _instance = TaskDatabase._internal();
  static final Logger _logger = Logger('TaskDatabase');

  factory TaskDatabase() => _instance;

  TaskDatabase._internal();

  final CollectionReference<Map<String, dynamic>> _tasksCollection =
      FirebaseFirestore.instance.collection('tasks');

  @override
  Future<String> create(Task task) async {
    _checkValid(task);

    try {
      final docRef = await _tasksCollection.add({
        ...task.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Task created: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error creating task', e);
      rethrow;
    }
  }

  @override
  Future<void> update(Task task) async {
    if (task.id.isEmpty) {
      throw TaskValidationException('Task ID is required for update');
    }
    _checkValid(task);

    try {
      await _tasksCollection.doc(task.id).update({
        ...task.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Task updated: ${task.id}');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw TaskNotFoundException(task.id);
      }
      _logger.severe('Firebase error updating task', e);
      rethrow;
    }
  }

  @override
  Future<void> delete(String taskId) async {
    if (taskId.isEmpty) {
      throw TaskValidationException('Task ID is required');
    }

    try {
      await _tasksCollection.doc(taskId).delete();
      _logger.info('Task deleted: $taskId');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw TaskNotFoundException(taskId);
      }
      _logger.severe('Firebase error deleting task', e);
      rethrow;
    }
  }

  @override
  Future<List<Task>> fetch({
    String? userId,
    String? projectId,
    TaskStatus? status,
    DateTime? date,
    DateTime? dueDate,
    String? searchQuery,
  }) async {
    try {
      final snapshot = await _buildQuery(
        userId: userId,
        projectId: projectId,
        status: status,
        date: date,
        dueDate: dueDate,
      ).get();
      return filterTasksBySearchQuery(_mapDocs(snapshot.docs), searchQuery);
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching tasks', e);
      rethrow;
    }
  }

  @override
  Stream<List<Task>> stream({
    String? userId,
    String? projectId,
    TaskStatus? status,
    DateTime? date,
    DateTime? dueDate,
    String? searchQuery,
  }) {
    return _buildQuery(
      userId: userId,
      projectId: projectId,
      status: status,
      date: date,
      dueDate: dueDate,
    ).snapshots().map(
          (snapshot) => filterTasksBySearchQuery(_mapDocs(snapshot.docs), searchQuery),
        );
  }

  void _checkValid(Task task) {
    final errors = task.validate();
    if (errors.isNotEmpty) {
      throw TaskValidationException(errors.join('; '));
    }
  }

  Query<Map<String, dynamic>> _buildQuery({
    String? userId,
    String? projectId,
    TaskStatus? status,
    DateTime? date,
    DateTime? dueDate,
  }) {
    Query<Map<String, dynamic>> query = _tasksCollection;

    if (userId != null) {
      query = query.where('assignedTo', isEqualTo: userId);
    }
    if (projectId != null) {
      query = query.where('associatedProject.id', isEqualTo: projectId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status.value);
    }

    if (dueDate != null) {
      query = query.where('dueDate', isEqualTo: Timestamp.fromDate(dueDate));
    } else if (date != null) {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      query = query
          .where('dueDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('dueDate', isLessThan: Timestamp.fromDate(endOfDay));
    }

    return query;
  }

  List<Task> _mapDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Task.fromMap(data);
    }).toList();
  }
}
