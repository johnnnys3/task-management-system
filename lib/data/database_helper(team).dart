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
