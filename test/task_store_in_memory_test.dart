import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/task_store_in_memory.dart';
import 'package:task_management/models/task.dart';

void main() {
  late InMemoryTaskStore store;

  setUp(() {
    store = InMemoryTaskStore();
  });

  Task buildTask({
    String id = '',
    String title = 'Valid title',
    String description = 'A valid description text',
    TaskStatus status = TaskStatus.todo,
    DateTime? dueDate,
    String? assignedTo,
  }) {
    return Task(
      id: id,
      title: title,
      description: description,
      status: status,
      dueDate: dueDate,
      assignedTo: assignedTo,
    );
  }

  group('create', () {
    test('assigns an id and stores the task', () async {
      final id = await store.create(buildTask());
      final tasks = await store.fetch();
      expect(tasks.single.id, id);
    });

    test('throws TaskValidationException for an invalid task', () {
      expect(
        () => store.create(buildTask(title: '')),
        throwsA(isA<TaskValidationException>()),
      );
    });
  });

  group('update', () {
    test('updates an existing task', () async {
      await store.create(buildTask());
      final existing = (await store.fetch()).single;
      await store.update(existing.copyWith(title: 'Updated title'));

      final tasks = await store.fetch();
      expect(tasks.single.title, 'Updated title');
    });

    test('throws TaskNotFoundException for an unknown id', () {
      expect(
        () => store.update(buildTask(id: 'missing')),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('removes the task', () async {
      final id = await store.create(buildTask());
      await store.delete(id);
      expect(await store.fetch(), isEmpty);
    });

    test('throws TaskNotFoundException for an unknown id', () {
      expect(
        () => store.delete('missing'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });

  group('fetch', () {
    test('filters by status', () async {
      await store.create(buildTask(title: 'Todo task', status: TaskStatus.todo));
      await store.create(buildTask(title: 'Done task', status: TaskStatus.completed));

      final tasks = await store.fetch(status: TaskStatus.completed);
      expect(tasks.map((t) => t.title), ['Done task']);
    });

    test('filters by assigned user', () async {
      await store.create(buildTask(title: 'Mine', assignedTo: 'user-1'));
      await store.create(buildTask(title: 'Theirs', assignedTo: 'user-2'));

      final tasks = await store.fetch(userId: 'user-1');
      expect(tasks.map((t) => t.title), ['Mine']);
    });

    test('filters by search query across title and description', () async {
      await store.create(buildTask(title: 'Buy milk', description: 'Grocery shopping trip'));
      await store.create(buildTask(title: 'Write report', description: 'Quarterly summary'));

      final tasks = await store.fetch(searchQuery: 'milk');
      expect(tasks.map((t) => t.title), ['Buy milk']);
    });

    test('filters by exact due date', () async {
      final target = DateTime.now().add(const Duration(days: 30));
      await store.create(buildTask(title: 'On date', dueDate: target));
      await store.create(buildTask(title: 'Other date', dueDate: target.add(const Duration(days: 1))));

      final tasks = await store.fetch(dueDate: target);
      expect(tasks.map((t) => t.title), ['On date']);
    });

    test('composes multiple filters', () async {
      await store.create(buildTask(
        title: 'Match',
        status: TaskStatus.inProgress,
        assignedTo: 'user-1',
      ));
      await store.create(buildTask(
        title: 'Wrong status',
        status: TaskStatus.todo,
        assignedTo: 'user-1',
      ));

      final tasks = await store.fetch(userId: 'user-1', status: TaskStatus.inProgress);
      expect(tasks.map((t) => t.title), ['Match']);
    });
  });

  group('stream', () {
    test('emits the current list, then again after each change', () async {
      final emissions = <int>[];
      final sub = store.stream().listen((tasks) => emissions.add(tasks.length));

      await Future.delayed(Duration.zero);
      await store.create(buildTask());
      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions, [0, 1]);
    });
  });
}
