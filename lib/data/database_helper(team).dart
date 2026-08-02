import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';

/// Firestore-backed [TeamStore] implementation.
class TeamDatabase implements TeamStore {
  static final TeamDatabase _instance = TeamDatabase._internal();
  static final Logger _logger = Logger('TeamDatabase');

  factory TeamDatabase() => _instance;

  TeamDatabase._internal();

  final CollectionReference<Map<String, dynamic>> _teamsCollection =
      FirebaseFirestore.instance.collection('teams');

  @override
  Future<String> create(Team team) async {
    _checkValid(team);

    try {
      final docRef = await _teamsCollection.add({
        ...team.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Team created: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error creating team', e);
      rethrow;
    }
  }

  @override
  Future<void> update(Team team) async {
    if (team.id.isEmpty) {
      throw TeamValidationException('Team ID is required for update');
    }
    _checkValid(team);

    try {
      await _teamsCollection.doc(team.id).update({
        ...team.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Team updated: ${team.id}');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw TeamNotFoundException(team.id);
      }
      _logger.severe('Firebase error updating team', e);
      rethrow;
    }
  }

  void _checkValid(Team team) {
    final errors = team.validate();
    if (errors.isNotEmpty) {
      throw TeamValidationException(errors.join('; '));
    }
  }

  @override
  Future<List<Team>> fetch() async {
    try {
      final snapshot = await _teamsCollection.get();
      return snapshot.docs.map((doc) => Team.fromMap(doc.data(), doc.id)).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching teams', e);
      rethrow;
    }
  }

  @override
  Future<void> delete(String teamId) async {
    try {
      await _teamsCollection.doc(teamId).delete();
      _logger.info('Team deleted: $teamId');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw TeamNotFoundException(teamId);
      }
      _logger.severe('Firebase error deleting team', e);
      rethrow;
    }
  }
}
