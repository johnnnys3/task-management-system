import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/data/team_store_in_memory.dart';
import 'package:task_management/models/team.dart';

void main() {
  Team buildTeam({String id = 'team-1', String name = 'Engineering'}) {
    return Team(
      id: id,
      name: name,
      description: 'A valid description text',
      members: const {},
      projects: const [],
    );
  }

  group('fetch', () {
    test('returns the seeded teams', () async {
      final store = InMemoryTeamStore(teams: [buildTeam(id: 'team-1'), buildTeam(id: 'team-2')]);

      final teams = await store.fetch();
      expect(teams.map((t) => t.id), containsAll(['team-1', 'team-2']));
    });

    test('returns an empty list when nothing has been seeded', () async {
      final store = InMemoryTeamStore();
      expect(await store.fetch(), isEmpty);
    });
  });

  group('create', () {
    test('assigns an id and stores the team', () async {
      final store = InMemoryTeamStore();

      final id = await store.create(buildTeam());
      final teams = await store.fetch();

      expect(teams.single.id, id);
      expect(teams.single.name, 'Engineering');
    });

    test('throws TeamValidationException for an invalid team', () {
      final store = InMemoryTeamStore();

      expect(
        () => store.create(buildTeam(name: '')),
        throwsA(isA<TeamValidationException>()),
      );
    });
  });

  group('update', () {
    test('replaces the stored team', () async {
      final store = InMemoryTeamStore(teams: [buildTeam()]);

      await store.update(buildTeam(name: 'Renamed'));
      final teams = await store.fetch();

      expect(teams.single.name, 'Renamed');
    });

    test('throws TeamNotFoundException for an unknown id', () {
      final store = InMemoryTeamStore();

      expect(
        () => store.update(buildTeam()),
        throwsA(isA<TeamNotFoundException>()),
      );
    });

    test('throws TeamValidationException for an invalid team', () {
      final store = InMemoryTeamStore(teams: [buildTeam()]);

      expect(
        () => store.update(buildTeam(name: '')),
        throwsA(isA<TeamValidationException>()),
      );
    });
  });

  group('delete', () {
    test('removes the team', () async {
      final store = InMemoryTeamStore(teams: [buildTeam()]);

      await store.delete('team-1');
      expect(await store.fetch(), isEmpty);
    });

    test('throws TeamNotFoundException for an unknown id', () {
      final store = InMemoryTeamStore();

      expect(
        () => store.delete('missing'),
        throwsA(isA<TeamNotFoundException>()),
      );
    });
  });
}
