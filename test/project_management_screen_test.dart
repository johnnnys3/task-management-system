import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/data/project_store_in_memory.dart';
import 'package:task_management/models/project.dart';
import 'package:task_management/screens/project_management_screen.dart';

void main() {
  Widget wrap(ProjectStore store, {bool isAdmin = false}) {
    return MaterialApp(
      home: Provider<ProjectStore>.value(
        value: store,
        child: Scaffold(
          body: ProjectManagementScreen(
            userId: 'user-1',
            isAdmin: isAdmin,
            user: const CustomUser(
              uid: 'user-1',
              email: 'user@example.com',
              name: 'Test User',
              role: 'admin',
              assignedProjects: [],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('a full project card (admin actions + due-soon badge) fits the grid tile without overflowing',
      (tester) async {
    final store = InMemoryProjectStore();
    await store.create(Project(
      id: '',
      name: 'Website redesign',
      description: 'Rebuild the marketing site end to end',
      dueDate: DateTime.now().add(const Duration(days: 2)),
      tasks: const [],
    ));

    await tester.pumpWidget(wrap(store, isAdmin: true));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Website redesign'), findsOneWidget);
  });
}
