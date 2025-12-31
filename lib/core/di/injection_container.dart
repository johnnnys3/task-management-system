import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Domain Layer
import 'package:task_management/domain/repositories/task_repository.dart';
import 'package:task_management/domain/usecases/get_tasks.dart';
import 'package:task_management/domain/usecases/create_task.dart';
import 'package:task_management/domain/usecases/get_tasks_for_today.dart';
import 'package:task_management/domain/usecases/get_task_statistics.dart';

// Data Layer
import 'package:task_management/data/repositories/task_repository_impl.dart';
import 'package:task_management/data/datasources/task_remote_datasource.dart';

// Core
import 'package:task_management/core/utils/logger.dart';

/// Global service locator
final GetIt getIt = GetIt.instance;

/// Initializes dependency injection
Future<void> initDependencies() async {
  // Initialize logger
  AppLogger.init();
  
  // External dependencies
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // Data sources
  getIt.registerLazySingleton<TaskRemoteDataSource>(
    () => TaskRemoteDataSourceImpl(getIt<FirebaseFirestore>()),
  );

  // Repositories
  getIt.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(getIt<TaskRemoteDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton<GetTasksUseCase>(
    () => GetTasksUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton<CreateTaskUseCase>(
    () => CreateTaskUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton<GetTasksForTodayUseCase>(
    () => GetTasksForTodayUseCase(getIt<TaskRepository>()),
  );

  getIt.registerLazySingleton<GetTaskStatisticsUseCase>(
    () => GetTaskStatisticsUseCase(getIt<TaskRepository>()),
  );

  AppLogger.info('Dependency injection initialized successfully');
}

/// Resets all registered services (useful for testing)
void resetDependencies() {
  getIt.reset();
  AppLogger.info('Dependency injection reset');
}

/// Clears all registered services
void clearDependencies() {
  getIt.reset(dispose: true);
  AppLogger.info('Dependency injection cleared');
}
