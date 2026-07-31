import 'dart:async';

import 'package:task_management/data/task_search.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/models/task.dart';

/// In-memory [TaskStore] implementation. For use in tests only — not
/// registered as the production adapter.
class InMemoryTaskStore implements TaskStore {
  final Map<String, Task> _tasks = {};
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  @override
  Future<String> create(Task task) async {
    _checkValid(task);

    final id = task.id.isNotEmpty ? task.id : 'task-${_nextId++}';
    _tasks[id] = task.copyWith(id: id);
    _changes.add(null);
    return id;
  }

  @override
  Future<void> update(Task task) async {
    if (!_tasks.containsKey(task.id)) {
      throw TaskNotFoundException(task.id);
    }
    _checkValid(task);

    _tasks[task.id] = task;
    _changes.add(null);
  }

  @override
  Future<void> delete(String taskId) async {
    if (!_tasks.containsKey(taskId)) {
      throw TaskNotFoundException(taskId);
    }
    _tasks.remove(taskId);
    _changes.add(null);
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
    return _filtered(
      userId: userId,
      projectId: projectId,
      status: status,
      date: date,
      dueDate: dueDate,
      searchQuery: searchQuery,
    );
  }

  @override
  Stream<List<Task>> stream({
    String? userId,
    String? projectId,
    TaskStatus? status,
    DateTime? date,
    DateTime? dueDate,
    String? searchQuery,
  }) async* {
    List<Task> filtered() => _filtered(
          userId: userId,
          projectId: projectId,
          status: status,
          date: date,
          dueDate: dueDate,
          searchQuery: searchQuery,
        );

    yield filtered();
    yield* _changes.stream.map((_) => filtered());
  }

  void _checkValid(Task task) {
    final errors = task.validate();
    if (errors.isNotEmpty) {
      throw TaskValidationException(errors.join('; '));
    }
  }

  List<Task> _filtered({
    String? userId,
    String? projectId,
    TaskStatus? status,
    DateTime? date,
    DateTime? dueDate,
    String? searchQuery,
  }) {
    var tasks = _tasks.values.toList();

    if (userId != null) {
      tasks = tasks.where((t) => t.assignedTo == userId).toList();
    }
    if (projectId != null) {
      tasks = tasks.where((t) => t.associatedProject?.id == projectId).toList();
    }
    if (status != null) {
      tasks = tasks.where((t) => t.status == status).toList();
    }
    if (dueDate != null) {
      tasks = tasks.where((t) => _isSameDay(t.dueDate, dueDate)).toList();
    } else if (date != null) {
      tasks = tasks.where((t) => _isSameDay(t.dueDate, date)).toList();
    }
    tasks = filterTasksBySearchQuery(tasks, searchQuery);

    return tasks;
  }

  bool _isSameDay(DateTime? a, DateTime b) {
    return a != null && a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
