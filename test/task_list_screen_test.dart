import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/task_store_in_memory.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/screens/task_list_screen.dart';

void main() {
  testWidgets('TaskListScreen loads its task list via TaskStore', (tester) async {
    final store = InMemoryTaskStore();
    await store.create(const Task(
      id: '',
      title: 'Task from store',
      description: 'A valid description text',
      assignedTo: 'user-1',
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: Provider<TaskStore>.value(
          value: store,
          child: const Scaffold(
            body: TaskListScreen(
              userId: 'user-1',
              user: CustomUser(
                uid: 'user-1',
                email: 'user@example.com',
                name: 'Test User',
                role: 'regular',
                assignedProjects: [],
              ),
              isAdmin: false,
              tasks: [],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Task from store'), findsOneWidget);
  });
}
