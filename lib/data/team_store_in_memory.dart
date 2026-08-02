import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';

/// In-memory [TeamStore] implementation. For use in tests only — not
/// registered as the production adapter.
///
/// Seed via the constructor: there's no `create` on [TeamStore] to populate
/// it through (out of scope until a real create screen exists).
class InMemoryTeamStore implements TeamStore {
  final Map<String, Team> _teams;

  InMemoryTeamStore({List<Team> teams = const []})
      : _teams = {for (final team in teams) team.id: team};

  @override
  Future<List<Team>> fetch() async => _teams.values.toList();

  @override
  Future<void> delete(String teamId) async {
    if (!_teams.containsKey(teamId)) {
      throw TeamNotFoundException(teamId);
    }
    _teams.remove(teamId);
  }
}
