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

class TeamValidationException extends TeamStoreException {
  TeamValidationException(String message)
      : super(message, code: 'validation-error');
}

/// Single interface for all team data access, backed by whichever adapter
/// (Firestore, in-memory, ...) is registered at the app root.
abstract class TeamStore {
  /// Creates [team], returning its assigned id.
  ///
  /// Throws [TeamValidationException] if the team fails [Team.validate].
  Future<String> create(Team team);

  /// Updates an existing team.
  ///
  /// Throws [TeamNotFoundException] if no team with [Team.id] exists.
  /// Throws [TeamValidationException] if the team fails [Team.validate].
  Future<void> update(Team team);

  /// Fetches all teams.
  Future<List<Team>> fetch();

  /// Deletes the team with the given id.
  ///
  /// Throws [TeamNotFoundException] if no such team exists.
  Future<void> delete(String teamId);
}
