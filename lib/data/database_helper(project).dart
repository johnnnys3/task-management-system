import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/models/project.dart';

/// Firestore-backed [ProjectStore] implementation.
class ProjectDatabase implements ProjectStore {
  static final ProjectDatabase _instance = ProjectDatabase._internal();
  static final Logger _logger = Logger('ProjectDatabase');

  factory ProjectDatabase() => _instance;

  ProjectDatabase._internal();

  final CollectionReference<Map<String, dynamic>> _projectsCollection =
      FirebaseFirestore.instance.collection('projects');

  @override
  Future<String> create(Project project) async {
    _checkValid(project);

    try {
      final docRef = await _projectsCollection.add({
        ...project.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Project created: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error creating project', e);
      rethrow;
    }
  }

  @override
  Future<void> update(Project project) async {
    if (project.id.isEmpty) {
      throw ProjectValidationException('Project ID is required for update');
    }
    _checkValid(project);

    try {
      await _projectsCollection.doc(project.id).update({
        ...project.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _logger.info('Project updated: ${project.id}');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw ProjectNotFoundException(project.id);
      }
      _logger.severe('Firebase error updating project', e);
      rethrow;
    }
  }

  @override
  Future<void> delete(String projectId) async {
    if (projectId.isEmpty) {
      throw ProjectValidationException('Project ID is required');
    }

    try {
      await _projectsCollection.doc(projectId).delete();
      _logger.info('Project deleted: $projectId');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw ProjectNotFoundException(projectId);
      }
      _logger.severe('Firebase error deleting project', e);
      rethrow;
    }
  }

  @override
  Future<List<Project>> fetch() async {
    try {
      final snapshot = await _projectsCollection.get();
      return _mapDocs(snapshot.docs);
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching projects', e);
      rethrow;
    }
  }

  @override
  Stream<List<Project>> stream() {
    return _projectsCollection.snapshots().map((snapshot) => _mapDocs(snapshot.docs));
  }

  void _checkValid(Project project) {
    final errors = project.validate();
    if (errors.isNotEmpty) {
      throw ProjectValidationException(errors.join('; '));
    }
  }

  List<Project> _mapDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Project.fromMap(data, doc.id);
    }).toList();
  }
}
