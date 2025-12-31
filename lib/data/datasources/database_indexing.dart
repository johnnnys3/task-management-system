import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/core/utils/logger.dart';
import 'package:task_management/core/errors/exceptions.dart';

/// Database indexing and query optimization utilities
class DatabaseIndexing {
  DatabaseIndexing._();

  /// Creates indexes for optimal query performance
  static Future<void> createIndexes() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Create indexes for tasks collection
      await _createTaskIndexes(firestore);
      
      // Create indexes for users collection
      await _createUserIndexes(firestore);
      
      // Create indexes for projects collection
      await _createProjectIndexes(firestore);
      
      AppLogger.info('Database indexes created successfully');
    } catch (e) {
      AppLogger.severe('Failed to create database indexes: ${e.toString()}');
      throw CacheException('Failed to create indexes', originalError: e);
    }
  }

  /// Creates indexes for tasks collection
  static Future<void> _createTaskIndexes(FirebaseFirestore firestore) async {
    final tasksCollection = firestore.collection('tasks');
    
    // Index for due date queries
    await tasksCollection.doc('index_config').set({
      'dueDate_index': {
        'collectionId': 'tasks',
        'fields': [
          {'fieldPath': 'dueDate', 'order': 'ASCENDING'},
          {'fieldPath': 'status', 'order': 'ASCENDING'},
        ],
        'queryScope': 'COLLECTION',
      },
    });
    
    // Index for user queries
    await tasksCollection.doc('index_config').set({
      'user_index': {
        'collectionId': 'tasks',
        'fields': [
          {'fieldPath': 'assignedTo', 'order': 'ASCENDING'},
          {'fieldPath': 'status', 'order': 'ASCENDING'},
          {'fieldPath': 'dueDate', 'order': 'ASCENDING'},
        ],
        'queryScope': 'COLLECTION',
      },
    });
    
    // Index for project queries
    await tasksCollection.doc('index_config').set({
      'project_index': {
        'collectionId': 'tasks',
        'fields': [
          {'fieldPath': 'projectId', 'order': 'ASCENDING'},
          {'fieldPath': 'status', 'order': 'ASCENDING'},
          {'fieldPriority': 'priority', 'order': 'DESCENDING'},
        ],
        'queryScope': 'COLLECTION',
      },
    });
    
    // Index for status queries
    await tasksCollection.doc('index_config').set({
      'status_index': {
        'collectionId': 'tasks',
        'fields': [
          {'fieldPath': 'status', 'order': 'ASCENDING'},
          {'fieldPath': 'createdAt', 'order': 'DESCENDING'},
        ],
        'queryScope': 'COLLECTION',
      },
    });
    
    // Composite index for priority and due date
    await tasksCollection.doc('index_config').set({
      'priority_dueDate_index': {
        'collectionId': 'tasks',
        'fields': [
          {'fieldPath': 'priority', 'order': 'DESCENDING'},
          {'fieldPath': 'dueDate', 'order': 'ASCENDING'},
          {'fieldPath': 'status', 'order': 'ASCENDING'},
        ],
        'queryScope': 'collection',
      },
    });
  }

  /// Creates indexes for users collection
  static Future<void> _createUserIndexes(FirebaseFirestore firestore) async {
    final usersCollection = firestore.collection('users');
    
    // Index for user role queries
    await usersCollection.doc('index_config').set({
      'role_index': {
        'collectionId': 'users',
        'fields': [
          {'fieldPath': 'role', 'order': 'ASCENDING'},
          {'fieldPath': 'isActive', 'order': 'ASCENDING'},
        ],
        'queryScope': 'COLLECTION',
      },
    });
    
    // Index for project assignments
    await usersCollection.doc('index_config').set({
      'projects_index': {
        'collectionId': 'users',
        'fields': [
          {'fieldPath': 'assignedProjects', 'order': 'ASCENDING'},
          {'fieldPath': 'isActive', 'order': 'ASCENDING'},
        ],
        'queryScope': 'COLLECTION',
      },
    });
  }

  /// Creates indexes for projects collection
  static Future<void> _createProjectIndexes(FirebaseFirestore firestore) async {
    final projectsCollection = firestore.collection('projects');
    
    // Index for project status queries
    await projectsCollection.doc('index_config').set({
      'status_index': {
        'collectionId': 'projects',
        'fields': [
          {'fieldPath': 'status', 'order': 'ASCENDING'},
          {'fieldPath': 'createdAt', 'order': 'DESCENDING'},
        ],
        'queryScope': 'COLLECTION',
      },
    });
    
    // Index for owner queries
    await projectsCollection.doc('index_config').set({
      'owner_index': {
        'collectionId': 'projects',
        'fields': [
          {'fieldPath': 'createdBy', 'order': 'ASCENDING'},
          {'fieldPath': 'status', 'order': 'ASCENDING'},
        ],
        'queryScope': 'COLLECTION',
      },
    });
  }

  /// Optimizes query with proper ordering and limiting
  static Query optimizeQuery(Query query, {
    int? limit,
    String? orderBy,
    bool descending = false,
    List<String>? whereConditions,
  }) {
    if (whereConditions != null) {
      for (final condition in whereConditions) {
        query = _addWhereCondition(query, condition);
      }
    }
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    if (limit != null) {
      query = query.limit(limit);
    }
    
    return query;
  }

  /// Adds where condition to query
  static Query _addWhereCondition(Query query, String condition) {
    // Parse condition and add appropriate where clause
    if (condition.contains('>=') || condition.contains('<=') || condition.contains('==')) {
      final parts = condition.split(RegExp(r'(>=|<=|==)'));
      if (parts.length == 3) {
        final field = parts[0].trim();
        final operator = parts[1].trim();
        final value = parts[2].trim();
        
        switch (operator) {
          case '>=':
            query = query.where(field, isGreaterThanOrEqualTo: _parseValue(value));
            break;
          case '<=':
            query = query.where(field, isLessThanOrEqualTo: _parseValue(value));
            break;
          case '==':
            query = query.where(field, isEqualTo: _parseValue(value));
            break;
        }
      }
    } else if (condition.contains('&&')) {
      final conditions = condition.split('&&');
      for (final cond in conditions) {
        query = _addWhereCondition(query, cond.trim());
      }
    } else {
      query = query.where(condition, isEqualTo: true);
    }
    
    return query;
  }

  /// Parses value to appropriate type
  static dynamic _parseValue(String value) {
    // Try parsing as number first
    if (double.tryParse(value) != null) {
      return double.tryParse(value);
    }
    
    // Try parsing as boolean
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    
    // Return as string
    return value;
  }

  /// Creates optimized batch queries
  static List<WriteBatch> createBatchOperations(
    List<WriteOperation> operations,
    int batchSize,
  ) {
    final batches = <WriteBatch>[];
    final firestore = FirebaseFirestore.instance;
    
    for (int i = 0; i < operations.length; i += batchSize) {
      final batch = firestore.batch();
      final end = (i + batchSize < operations.length) 
          ? i + batchSize 
          : operations.length;
      
      for (int j = i; j < end; j++) {
        final operation = operations[j];
        switch (operation.type) {
          case WriteOperationType.create:
            batch.set(operation.reference, operation.data);
            break;
          case WriteOperationType.update:
            batch.update(operation.reference, operation.data);
            break;
          case WriteOperationType.delete:
            batch.delete(operation.reference);
            break;
        }
      }
      batches.add(batch);
    }
    
    return batches;
  }

  /// Monitors query performance
  static Future<QueryPerformanceMetrics> monitorQueryPerformance(
    Query query,
    String queryName,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final snapshot = await query.get();
      stopwatch.stop();
      
      return QueryPerformanceMetrics(
        queryName: queryName,
        executionTime: stopwatch.elapsedMilliseconds,
        documentCount: snapshot.docs.length,
        cacheHit: false, // Firestore doesn't expose cache hits
        success: true,
      );
    } catch (e) {
      stopwatch.stop();
      return QueryPerformanceMetrics(
        queryName: queryName,
        executionTime: stopwatch.elapsedMilliseconds,
        documentCount: 0,
        cacheHit: false,
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// Write operation for batch processing
class WriteOperation {

  const WriteOperation({
    required this.type,
    required this.reference,
    required this.data,
  });
  final WriteOperationType type;
  final DocumentReference reference;
  final Map<String, dynamic> data;
}

enum WriteOperationType {
  create,
  update,
  delete,
}

/// Query performance metrics
class QueryPerformanceMetrics {

  const QueryPerformanceMetrics({
    required this.queryName,
    required this.executionTime,
    required this.documentCount,
    required this.cacheHit,
    required this.success,
    this.error,
  });
  final String queryName;
  final int executionTime;
  final int documentCount;
  final bool cacheHit;
  final bool success;
  final String? error;

  @override
  String toString() {
    return 'QueryPerformanceMetrics('
        'queryName: $queryName, '
        'executionTime: ${executionTime}ms, '
        'documentCount: $documentCount, '
        'cacheHit: $cacheHit, '
        'success: $success'
        '${error != null ? ', error: $error' : ''}';
  }
}

/// Query optimization strategies
class QueryOptimizationStrategies {
  QueryOptimizationStrategies._();

  /// Implements pagination for large result sets
  static Future<List<DocumentSnapshot>> paginateQuery(
    Query query,
    int pageSize,
    int pageNumber,
  ) async {
    final offset = pageNumber > 0 
        ? pageSize * pageNumber 
        : 0;
    
    Query limitedQuery = query.limit(pageSize);
    
    if (offset > 0) {
      // For offset-based pagination, we need to use startAfter
      // This is a simplified version - in practice, you'd need to track the last document
      final snapshot = await query.limit(offset).get();
      if (snapshot.docs.isNotEmpty) {
        limitedQuery = query.limit(pageSize).startAfterDocument(snapshot.docs.last);
      }
    }
    
    final resultSnapshot = await limitedQuery.get();
    return resultSnapshot.docs;
  }

  /// Implements cursor-based pagination
  static Future<List<DocumentSnapshot>> cursorPaginateQuery(
    Query query,
    DocumentSnapshot? lastDocument,
    int pageSize,
  ) async {
    Query limitedQuery = query.limit(pageSize);
    
    if (lastDocument != null) {
      limitedQuery = limitedQuery.startAfterDocument(lastDocument);
    }
    
    final snapshot = await limitedQuery.get();
    return snapshot.docs;
  }

  /// Implements query caching strategy
  static Map<String, Map<String, dynamic>> _queryCache = {};

  static Future<List<DocumentSnapshot>> cachedQuery(
    Query query,
    String cacheKey, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final now = DateTime.now();
    
    // Check cache
    if (_queryCache.containsKey(cacheKey)) {
      final cachedData = _queryCache[cacheKey]!;
      final cacheAge = now.difference(cachedData['timestamp'] as DateTime);
      
      if (cacheAge.inMinutes < ttl.inMinutes) {
        return cachedData['docs'] as List<DocumentSnapshot>;
      } else {
        _queryCache.remove(cacheKey);
      }
    }
    
    // Execute query and cache result
    final snapshot = await query.get();
    _queryCache[cacheKey] = {
      'docs': snapshot.docs,
      'timestamp': now,
    };
    
    return snapshot.docs;
  }

  /// Clears query cache
  static void clearCache() {
    _queryCache.clear();
  }

  /// Gets cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cacheSize': _queryCache.length,
      'cachedQueries': _queryCache.keys.toList(),
    };
  }
}
