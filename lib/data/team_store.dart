import 'package:task_management/models/team.dart';

/// Base exception for all [TeamStore] operations.
abstract class TeamStoreException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  TeamStoreException(this.message, {this.code = 'unknown', this.originalError});

  @override
  String toString() => '$runtimeType: $message';
}

class TeamNotFoundException extends TeamStoreException {
  TeamNotFoundException(String teamId)
      : super('Team not found: $teamId', code: 'team-not-found');
}

/// Single interface for all team data access, backed by whichever adapter
/// (Firestore, in-memory, ...) is registered at the app root.
///
/// ponytail: scoped to what team_management_screen.dart actually calls today
/// (fetch + delete). Create/update/stream are TODO-stubbed screens with no
/// real caller yet — add them here when one exists to validate the shape.
abstract class TeamStore {
  /// Fetches all teams.
  Future<List<Team>> fetch();

  /// Deletes the team with the given id.
  ///
  /// Throws [TeamNotFoundException] if no such team exists.
  Future<void> delete(String teamId);
}
