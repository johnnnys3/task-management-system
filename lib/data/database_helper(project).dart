import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:task_management/domain/entities/project_entity.dart';

/// Custom exceptions for project database operations
class ProjectDatabaseException implements Exception {
  ProjectDatabaseException(
    this.message, {
    this.code = 'unknown',
    this.originalError,
  });

  final String message;
  final String code;
  final dynamic originalError;

  @override
  String toString() => 'ProjectDatabaseException: $message';
}

class ProjectNotFoundException extends ProjectDatabaseException {
  ProjectNotFoundException(String projectId)
      : super('Project not found: $projectId', code: 'project-not-found');
}

class ProjectValidationException extends ProjectDatabaseException {
  ProjectValidationException(String message)
      : super(message, code: 'validation-error');
}

/// Handles all database operations for projects
class ProjectDatabase {
  static final Logger _logger = Logger('ProjectDatabase');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'projects';

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(_collectionName);

  /// Add project
  Future<String> addProject(ProjectEntity project) async {
    try {
      _validateProject(project);

      final docRef = await _collection.add({
        ...project.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.info('Project added: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      throw ProjectDatabaseException(
        'Failed to add project: ${e.message}',
        code: e.code,
        originalError: e,
      );
    }
  }

  /// Update project
  Future<void> updateProject(ProjectEntity project) async {
    if (project.id.isEmpty) {
      throw ProjectValidationException('Project ID is required');
    }

    try {
      _validateProject(project);

      await _collection.doc(project.id).update({
        ...project.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _logger.info('Project updated: ${project.id}');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw ProjectNotFoundException(project.id);
      }
      throw ProjectDatabaseException(
        'Failed to update project: ${e.message}',
        code: e.code,
        originalError: e,
      );
    }
  }

  /// Delete project
  Future<void> deleteProject(String projectId) async {
    if (projectId.isEmpty) {
      throw ProjectValidationException('Project ID is required');
    }

    try {
      await _collection.doc(projectId).delete();
      _logger.info('Project deleted: $projectId');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        throw ProjectNotFoundException(projectId);
      }
      throw ProjectDatabaseException(
        'Failed to delete project: ${e.message}',
        code: e.code,
        originalError: e,
      );
    }
  }

  /// Get project by ID
  Future<ProjectEntity> getProject(String projectId) async {
    if (projectId.isEmpty) {
      throw ProjectValidationException('Project ID is required');
    }

    final doc = await _collection.doc(projectId).get();
    if (!doc.exists) {
      throw ProjectNotFoundException(projectId);
    }

    return ProjectEntity.fromMap(doc.data()!, doc.id);
  }

  /// Get all projects
  Future<List<ProjectEntity>> getAllProjects() async {
    final snapshot = await _collection.get();
    return snapshot.docs
        .map((doc) => ProjectEntity.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Get projects for user
  Future<List<ProjectEntity>> getProjectsForUser(String userId) async {
    if (userId.isEmpty) {
      throw ProjectValidationException('User ID is required');
    }

    final snapshot = await _collection
        .where('assignedUsers', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ProjectEntity.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Search projects
  Future<List<ProjectEntity>> searchProjects(String query) async {
    if (query.isEmpty) return getAllProjects();

    final snapshot = await _collection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) => ProjectEntity.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// ✅ FIXED: batch update projects
  Future<void> batchUpdateProjects(List<ProjectEntity> projects) async {
    if (projects.isEmpty) return;

    final batch = _firestore.batch();

    for (final project in projects) {
      if (project.id.isEmpty) {
        throw ProjectValidationException('All projects must have IDs');
      }

      _validateProject(project);

      batch.update(
        _collection.doc(project.id),
        {
          ...project.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    await batch.commit();
    _logger.info('Batch updated ${projects.length} projects');
  }

  /// Validation
  void _validateProject(ProjectEntity project) {
    if (project.name.isEmpty) {
      throw ProjectValidationException('Project name is required');
    }
    if (project.name.length > 100) {
      throw ProjectValidationException('Project name too long');
    }
    if (project.description.length > 500) {
      throw ProjectValidationException('Project description too long');
    }
  }

  /// Streams
  Stream<List<ProjectEntity>> getProjectsStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ProjectEntity.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<ProjectEntity>> getProjectsForUserStream(String userId) {
    if (userId.isEmpty) {
      throw ProjectValidationException('User ID is required');
    }

    return _collection
        .where('assignedUsers', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ProjectEntity.fromMap(d.data(), d.id)).toList());
  }
}
