import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/task_store_in_memory.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/screens/calendar_integration_screen.dart';

void main() {
  testWidgets('renders the month grid and today\'s tasks below it without overflowing', (tester) async {
    final store = InMemoryTaskStore();
    await store.create(Task(
      id: '',
      title: 'Due today task',
      description: 'A valid description text',
      dueDate: DateTime.now(),
    ));
    await store.create(Task(
      id: '',
      title: 'Due next week task',
      description: 'A valid description text',
      dueDate: DateTime.now().add(const Duration(days: 7)),
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: Provider<TaskStore>.value(
          value: store,
          child: const Scaffold(body: TaskCalendar()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Due today task'), findsOneWidget);
    expect(find.text('Due next week task'), findsNothing);
  });
}
