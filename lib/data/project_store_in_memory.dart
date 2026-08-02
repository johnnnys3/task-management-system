import 'dart:async';

import 'package:task_management/data/project_store.dart';
import 'package:task_management/models/project.dart';

/// In-memory [ProjectStore] implementation. For use in tests only — not
/// registered as the production adapter.
class InMemoryProjectStore implements ProjectStore {
  final Map<String, Project> _projects = {};
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  @override
  Future<String> create(Project project) async {
    _checkValid(project);

    final id = project.id.isNotEmpty ? project.id : 'project-${_nextId++}';
    _projects[id] = project.copyWith(id: id);
    _changes.add(null);
    return id;
  }

  @override
  Future<void> update(Project project) async {
    if (!_projects.containsKey(project.id)) {
      throw ProjectNotFoundException(project.id);
    }
    _checkValid(project);

    _projects[project.id] = project;
    _changes.add(null);
  }

  @override
  Future<void> delete(String projectId) async {
    if (!_projects.containsKey(projectId)) {
      throw ProjectNotFoundException(projectId);
    }
    _projects.remove(projectId);
    _changes.add(null);
  }

  @override
  Future<List<Project>> fetch() async => _projects.values.toList();

  @override
  Stream<List<Project>> stream() async* {
    yield _projects.values.toList();
    yield* _changes.stream.map((_) => _projects.values.toList());
  }

  void _checkValid(Project project) {
    final errors = project.validate();
    if (errors.isNotEmpty) {
      throw ProjectValidationException(errors.join('; '));
    }
  }
}
