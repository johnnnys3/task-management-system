import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/task_store_in_memory.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/provider/task_provider.dart';

void main() {
  group('TaskProvider', () {
    late InMemoryTaskStore store;
    late TaskProvider provider;

    setUp(() {
      store = InMemoryTaskStore();
      provider = TaskProvider(taskStore: store);
    });

    test('createTask calls through to TaskStore.create', () async {
      await provider.createTask(title: 'Valid title', description: 'A valid description text');

      final tasks = await store.fetch();
      expect(tasks.single.title, 'Valid title');
      expect(provider.task?.id, tasks.single.id);
    });

    test('createTask surfaces TaskValidationException for an invalid task', () async {
      expect(
        () => provider.createTask(title: '', description: 'A valid description text'),
        throwsA(isA<TaskValidationException>()),
      );
    });

    test('updateTask calls through to TaskStore.update', () async {
      await provider.createTask(title: 'Original', description: 'A valid description text');

      await provider.updateTask(title: 'Changed');

      final tasks = await store.fetch();
      expect(tasks.single.title, 'Changed');
    });

    test('deleteTask calls through to TaskStore.delete', () async {
      await provider.createTask(title: 'Original', description: 'A valid description text');

      await provider.deleteTask();

      expect(await store.fetch(), isEmpty);
      expect(provider.hasTask, isFalse);
    });

    test('loadTask surfaces TaskNotFoundException for an unknown id', () async {
      await provider.loadTask('missing');
      expect(provider.error, contains('missing'));
    });

    test('loadTask finds an existing task by id', () async {
      final id = await store.create(
        const Task(id: '', title: 'Existing', description: 'A valid description text'),
      );

      await provider.loadTask(id);

      expect(provider.task?.id, id);
    });
  });

  group('TaskListProvider', () {
    late InMemoryTaskStore store;
    late TaskListProvider provider;

    setUp(() {
      store = InMemoryTaskStore();
      provider = TaskListProvider(taskStore: store);
    });

    test('fetchTasks calls through to TaskStore.fetch', () async {
      await store.create(const Task(id: '', title: 'Task 1', description: 'A valid description text'));

      await provider.fetchTasks();

      expect(provider.tasks.map((t) => t.title), ['Task 1']);
    });

    test('fetchTasksForProject filters by projectId via TaskStore', () async {
      await store.create(const Task(id: '', title: 'No project', description: 'A valid description text'));

      await provider.fetchTasksForProject('project-1');

      expect(provider.tasks, isEmpty);
    });

    test('fetchTasksForUser filters by userId via TaskStore', () async {
      await store.create(const Task(
        id: '',
        title: 'Mine',
        description: 'A valid description text',
        assignedTo: 'user-1',
      ));
      await store.create(const Task(
        id: '',
        title: 'Theirs',
        description: 'A valid description text',
        assignedTo: 'user-2',
      ));

      await provider.fetchTasksForUser('user-1');

      expect(provider.tasks.map((t) => t.title), ['Mine']);
    });

    test('addTask calls through to TaskStore.create', () async {
      await provider.addTask(
        const Task(id: '', title: 'Added', description: 'A valid description text'),
      );

      expect(provider.tasks.map((t) => t.title), ['Added']);
      expect((await store.fetch()).map((t) => t.title), ['Added']);
    });

    test('updateTask calls through to TaskStore.update', () async {
      final id = await store.create(
        const Task(id: '', title: 'Original', description: 'A valid description text'),
      );
      await provider.fetchTasks();

      await provider.updateTask((await store.fetch()).single.copyWith(id: id, title: 'Changed'));

      expect((await store.fetch()).single.title, 'Changed');
    });

    test('deleteTask calls through to TaskStore.delete', () async {
      final id = await store.create(
        const Task(id: '', title: 'Original', description: 'A valid description text'),
      );
      await provider.fetchTasks();

      await provider.deleteTask(id);

      expect(await store.fetch(), isEmpty);
      expect(provider.tasks, isEmpty);
    });

    test('deleteTask surfaces TaskNotFoundException for an unknown id', () async {
      expect(
        () => provider.deleteTask('missing'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });
}
