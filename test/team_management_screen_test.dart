import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/data/team_store_in_memory.dart';
import 'package:task_management/models/team.dart' show Team, TeamRole;
import 'package:task_management/screens/team_management_screen.dart';

void main() {
  Widget wrap(TeamStore store) {
    return MaterialApp(
      home: Provider<TeamStore>.value(
        value: store,
        child: const Scaffold(body: TeamManagementScreen(userId: 'user-1')),
      ),
    );
  }

  testWidgets('loads and displays teams from TeamStore', (tester) async {
    final store = InMemoryTeamStore(teams: [
      Team(id: 'team-1', name: 'Engineering', description: 'Builds things'),
    ]);

    await tester.pumpWidget(wrap(store));
    await tester.pumpAndSettle();

    expect(find.text('Engineering'), findsOneWidget);
  });

  testWidgets('a full team card (description + 3 members) fits the grid tile without overflowing', (tester) async {
    final store = InMemoryTeamStore(teams: [
      Team(
        id: 'team-1',
        name: 'Engineering',
        description: 'Builds and ships the whole product end to end',
        members: const {
          'alice': TeamRole.owner,
          'bob': TeamRole.admin,
          'carol': TeamRole.member,
        },
        projects: const ['p1', 'p2'],
      ),
    ]);

    await tester.pumpWidget(wrap(store));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Engineering'), findsOneWidget);
  });
}
