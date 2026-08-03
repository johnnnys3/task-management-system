import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/data/project_store_in_memory.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/task_store_in_memory.dart';
import 'package:task_management/models/project.dart';
import 'package:task_management/screens/task_creation_screen.dart';

void main() {
  final testProject = Project(
    id: 'project-1',
    name: 'Test Project',
    description: '',
    dueDate: DateTime(2026, 12, 31),
    tasks: const [],
  );

  Widget wrap(TaskStore store, {ProjectStore? projectStore}) {
    return MaterialApp(
      home: MultiProvider(
        providers: [
          Provider<TaskStore>.value(value: store),
          Provider<ProjectStore>.value(
            value: projectStore ?? InMemoryProjectStore(),
          ),
        ],
        child: CreateTask(
          availableProjects: const [],
          memberFetcher: () async => ['Alex'],
          projectFetcher: () async => [testProject],
        ),
      ),
    );
  }

  Future<void> fillFormAndSelectAssignments(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Task Name'), 'A new task');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Task Description'),
      'A valid description text',
    );

    await tester.ensureVisible(find.text('Choose').first);
    await tester.tap(find.text('Choose').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Choose').last);
    await tester.tap(find.text('Choose').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Project'));
    await tester.pumpAndSettle();
  }

  testWidgets('creating a task calls through to TaskStore.create', (tester) async {
    final store = InMemoryTaskStore();

    await tester.pumpWidget(wrap(store));
    await tester.pumpAndSettle();
    await fillFormAndSelectAssignments(tester);

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Create Task'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Task'));
    await tester.pumpAndSettle();

    final tasks = await store.fetch();
    expect(tasks.map((t) => t.title), contains('A new task'));
  });

  testWidgets('surfaces TaskValidationException when the task is invalid', (tester) async {
    final store = InMemoryTaskStore();

    await tester.pumpWidget(wrap(store));
    await tester.pumpAndSettle();
    // "ab" passes the form's own (looser) validator but fails
    // Task.validate()'s stricter minimum-length check inside TaskStore.
    await tester.enterText(find.widgetWithText(TextFormField, 'Task Name'), 'ab');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Task Description'),
      'A valid description text',
    );
    await tester.ensureVisible(find.text('Choose').first);
    await tester.tap(find.text('Choose').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alex'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose').last);
    await tester.tap(find.text('Choose').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Project'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(ElevatedButton, 'Create Task'));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create Task'));
    await tester.pumpAndSettle();

    expect(find.textContaining('TaskValidationException'), findsOneWidget);
    expect(await store.fetch(), isEmpty);
  });
}
