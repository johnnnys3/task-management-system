import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';

/// In-memory [TeamStore] implementation. For use in tests only — not
/// registered as the production adapter.
class InMemoryTeamStore implements TeamStore {
  final Map<String, Team> _teams;
  int _nextId = 1;

  InMemoryTeamStore({List<Team> teams = const []})
      : _teams = {for (final team in teams) team.id: team};

  @override
  Future<String> create(Team team) async {
    _checkValid(team);

    final id = 'team-${_nextId++}';
    _teams[id] = team.copyWith(id: id);
    return id;
  }

  @override
  Future<void> update(Team team) async {
    if (!_teams.containsKey(team.id)) {
      throw TeamNotFoundException(team.id);
    }
    _checkValid(team);
    _teams[team.id] = team;
  }

  @override
  Future<List<Team>> fetch() async => _teams.values.toList();

  @override
  Future<void> delete(String teamId) async {
    if (!_teams.containsKey(teamId)) {
      throw TeamNotFoundException(teamId);
    }
    _teams.remove(teamId);
  }

  void _checkValid(Team team) {
    final errors = team.validate();
    if (errors.isNotEmpty) {
      throw TeamValidationException(errors.join('; '));
    }
  }
}
