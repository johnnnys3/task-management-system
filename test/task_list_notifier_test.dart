import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/task_store_in_memory.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/provider/task_list_notifier.dart';

void main() {
  group('TaskListNotifier', () {
    late InMemoryTaskStore store;
    late TaskListNotifier notifier;

    setUp(() {
      store = InMemoryTaskStore();
      notifier = TaskListNotifier(taskStore: store);
    });

    test('loadTasks calls through to TaskStore.fetch', () async {
      await store.create(const Task(id: '', title: 'Task 1', description: 'A valid description text'));

      await notifier.loadTasks();

      expect(notifier.tasks.map((t) => t.title), ['Task 1']);
    });

    test('addTask calls through to TaskStore.create', () async {
      await notifier.addTask(
        const Task(id: '', title: 'Added', description: 'A valid description text'),
      );

      expect(notifier.tasks.map((t) => t.title), ['Added']);
      expect((await store.fetch()).map((t) => t.title), ['Added']);
    });

    test('updateTask calls through to TaskStore.update', () async {
      final id = await store.create(
        const Task(id: '', title: 'Original', description: 'A valid description text'),
      );
      await notifier.loadTasks();

      await notifier.updateTask((await store.fetch()).single.copyWith(id: id, title: 'Changed'));

      expect((await store.fetch()).single.title, 'Changed');
    });

    test('deleteTask calls through to TaskStore.delete', () async {
      final id = await store.create(
        const Task(id: '', title: 'Original', description: 'A valid description text'),
      );
      await notifier.loadTasks();

      await notifier.deleteTask(id);

      expect(await store.fetch(), isEmpty);
      expect(notifier.tasks, isEmpty);
    });

    test('deleteTask surfaces TaskNotFoundException for an unknown id', () async {
      expect(
        () => notifier.deleteTask('missing'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });
}
