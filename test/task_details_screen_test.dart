import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/task_store_in_memory.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/screens/task_details_screen.dart';

void main() {
  Widget wrap(TaskStore store, Task task) {
    return MaterialApp(
      home: Provider<TaskStore>.value(
        value: store,
        child: TaskDetailsScreen(task: task),
      ),
    );
  }

  testWidgets('marking a task complete calls through to TaskStore.update', (tester) async {
    final store = InMemoryTaskStore();
    final id = await store.create(const Task(
      id: '',
      title: 'Existing task',
      description: 'A valid description text',
    ));
    final task = (await store.fetch()).single;

    await tester.pumpWidget(wrap(store, task));
    await tester.ensureVisible(find.text('Mark Complete'));
    await tester.tap(find.text('Mark Complete'));
    await tester.pumpAndSettle();

    final updated = (await store.fetch()).firstWhere((t) => t.id == id);
    expect(updated.isCompleted, isTrue);
  });

  testWidgets('deleting a task calls through to TaskStore.delete', (tester) async {
    final store = InMemoryTaskStore();
    await store.create(const Task(
      id: '',
      title: 'Existing task',
      description: 'A valid description text',
    ));
    final task = (await store.fetch()).single;

    await tester.pumpWidget(wrap(store, task));
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete Task').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();

    expect(await store.fetch(), isEmpty);
  });

  testWidgets('update surfaces TaskNotFoundException when the task is gone', (tester) async {
    final store = InMemoryTaskStore();
    const task = Task(id: 'missing', title: 'Ghost task', description: 'A valid description text');

    await tester.pumpWidget(wrap(store, task));
    await tester.ensureVisible(find.text('Mark Complete'));
    await tester.tap(find.text('Mark Complete'));
    await tester.pumpAndSettle();

    expect(find.textContaining('TaskNotFoundException'), findsOneWidget);
  });

  testWidgets('update surfaces TaskValidationException for an invalid task', (tester) async {
    final store = InMemoryTaskStore();
    final id = await store.create(const Task(
      id: '',
      title: 'Existing task',
      description: 'A valid description text',
    ));
    // The task exists in the store (so it's past the not-found check), but
    // carries an invalid title, so TaskStore.update's own validation fires.
    final task = Task(id: id, title: '', description: 'A valid description text');

    await tester.pumpWidget(wrap(store, task));
    await tester.ensureVisible(find.text('Mark Complete'));
    await tester.tap(find.text('Mark Complete'));
    await tester.pumpAndSettle();

    expect(find.textContaining('TaskValidationException'), findsOneWidget);
  });
}
