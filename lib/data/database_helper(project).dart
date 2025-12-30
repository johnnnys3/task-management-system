import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:task_management/models/project.dart';

/// Custom exceptions for project database operations
class ProjectDatabaseException implements Exception {
  final String message;
  final String code;
  final dynamic originalError;

  ProjectDatabaseException(this.message, {this.code = 'unknown', this.originalError});

  @override
  String toString() => 'ProjectDatabaseException: $message';
}

class ProjectNotFoundException extends ProjectDatabaseException {
  ProjectNotFoundException(String projectId) 
      : super('Project not found: $projectId', code: 'project-not-found');
}

class ProjectValidationException extends ProjectDatabaseException {
  ProjectValidationException(super.message) 
      : super(code: 'validation-error');
}

/// Handles all database operations for projects
class ProjectDatabase {
  static final Logger _logger = Logger('ProjectDatabase');
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'projects';

  /// Collection reference for projects
  CollectionReference<Map<String, dynamic>> get _collection => 
      _firestore.collection(_collectionName);

  /// Adds a new project to the database
  /// 
  /// Throws [ProjectValidationException] if project data is invalid
  /// Throws [ProjectDatabaseException] for database errors
  Future<String> addProject(Project project) async {
    try {
      _validateProject(project);
      
      final docRef = await _collection.add({
        ...project.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Project added successfully: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error adding project', e);
      throw ProjectDatabaseException(
        'Failed to add project: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error adding project', e, stackTrace);
      throw ProjectDatabaseException(
        'Unexpected error adding project',
        originalError: e,
      );
    }
  }

  /// Updates an existing project
  /// 
  /// Throws [ProjectNotFoundException] if project doesn't exist
  /// Throws [ProjectValidationException] if project data is invalid
  Future<void> updateProject(Project project) async {
    if (project.id.isEmpty) {
      throw ProjectValidationException('Project ID is required for update');
    }

    try {
      _validateProject(project);
      
      await _collection.doc(project.id).update({
        ...project.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _logger.info('Project updated successfully: ${project.id}');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        _logger.warning('Project not found for update: ${project.id}');
        throw ProjectNotFoundException(project.id);
      }
      _logger.severe('Firebase error updating project', e);
      throw ProjectDatabaseException(
        'Failed to update project: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error updating project', e, stackTrace);
      throw ProjectDatabaseException(
        'Unexpected error updating project',
        originalError: e,
      );
    }
  }

  /// Deletes a project by ID
  /// 
  /// Throws [ProjectNotFoundException] if project doesn't exist
  Future<void> deleteProject(String projectId) async {
    if (projectId.isEmpty) {
      throw ProjectValidationException('Project ID is required');
    }

    try {
      await _collection.doc(projectId).delete();
      _logger.info('Project deleted successfully: $projectId');
    } on FirebaseException catch (e) {
      if (e.code == 'not-found') {
        _logger.warning('Project not found for deletion: $projectId');
        throw ProjectNotFoundException(projectId);
      }
      _logger.severe('Firebase error deleting project', e);
      throw ProjectDatabaseException(
        'Failed to delete project: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error deleting project', e, stackTrace);
      throw ProjectDatabaseException(
        'Unexpected error deleting project',
        originalError: e,
      );
    }
  }

  /// Fetches a project by ID
  /// 
  /// Throws [ProjectNotFoundException] if project doesn't exist
  Future<Project?> getProject(String projectId) async {
    if (projectId.isEmpty) {
      throw ProjectValidationException('Project ID is required');
    }

    try {
      final docSnapshot = await _collection.doc(projectId).get();
      if (!docSnapshot.exists) {
        throw ProjectNotFoundException(projectId);
      }
      
      final data = docSnapshot.data()!;
      data['id'] = docSnapshot.id;
      
      return Project.fromMap(data, docSnapshot.id);
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching project', e);
      throw ProjectDatabaseException(
        'Failed to fetch project: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching project', e, stackTrace);
      throw ProjectDatabaseException(
        'Unexpected error fetching project',
        originalError: e,
      );
    }
  }

  /// Fetches all projects
  Future<List<Project>> getAllProjects() async {
    try {
      final querySnapshot = await _collection.get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Project.fromMap(data, doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching all projects', e);
      throw ProjectDatabaseException(
        'Failed to fetch projects: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching all projects', e, stackTrace);
      throw ProjectDatabaseException(
        'Unexpected error fetching projects',
        originalError: e,
      );
    }
  }

  /// Fetches projects for a specific user
  Future<List<Project>> getProjectsForUser(String userId) async {
    if (userId.isEmpty) {
      throw ProjectValidationException('User ID is required');
    }

    try {
      final querySnapshot = await _collection
          .where('assignedUsers', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Project.fromMap(data, doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error fetching user projects', e);
      throw ProjectDatabaseException(
        'Failed to fetch user projects: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error fetching user projects', e, stackTrace);
      throw ProjectDatabaseException(
        'Unexpected error fetching user projects',
        originalError: e,
      );
    }
  }

  /// Searches projects by name or description
  Future<List<Project>> searchProjects(String query) async {
    if (query.isEmpty) {
      return getAllProjects();
    }

    try {
      final querySnapshot = await _collection
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Project.fromMap(data, doc.id);
      }).toList();
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error searching projects', e);
      throw ProjectDatabaseException(
        'Failed to search projects: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error searching projects', e, stackTrace);
      throw ProjectDatabaseException(
        'Unexpected error searching projects',
        originalError: e,
      );
    }
  }

  /// Performs a batch update of multiple projects
  Future<void> batchUpdateProjects(List<Project> projects) async {
    if (projects.isEmpty) {
      return;
    }

    final batch = _firestore.batch();
    try {
      for (final project in projects) {
        if (project.id.isEmpty) {
          throw ProjectValidationException('All projects must have IDs for batch update');
        }
        
        _validateProject(project);
        
        final docRef = _collection.doc(project.id);
        batch.update(docRef, {
          ...project.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      _logger.info('Batch update completed for ${projects.length} projects');
    } on FirebaseException catch (e) {
      _logger.severe('Firebase error in batch update', e);
      throw ProjectDatabaseException(
        'Failed to batch update projects: ${e.message}',
        code: e.code,
        originalError: e,
      );
    } catch (e, stackTrace) {
      _logger.severe('Unexpected error in batch update', e, stackTrace);
      throw ProjectDatabaseException(
        'Unexpected error in batch update',
        originalError: e,
      );
    }
  }

  /// Validates project data before database operations
  void _validateProject(Project project) {
    if (project.name.isEmpty) {
      throw ProjectValidationException('Project name is required');
    }
    if (project.name.length > 100) {
      throw ProjectValidationException('Project name must be less than 100 characters');
    }
    if (project.description.length > 500) {
      throw ProjectValidationException('Project description must be less than 500 characters');
    }
  }

  /// Gets a stream of projects for real-time updates
  Stream<List<Project>> getProjectsStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Project.fromMap(data, doc.id);
        }).toList());
  }

  /// Gets a stream of projects for a specific user
  Stream<List<Project>> getProjectsForUserStream(String userId) {
    if (userId.isEmpty) {
      throw ProjectValidationException('User ID is required');
    }

    return _collection
        .where('assignedUsers', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return Project.fromMap(data, doc.id);
        }).toList());
  }
}