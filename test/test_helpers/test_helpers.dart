import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import 'package:task_management/domain/entities/user_entity.dart';
import 'package:task_management/core/utils/either.dart';
import 'package:task_management/core/errors/failures.dart';

/// Test helpers for unit and widget tests
class TestHelpers {
  TestHelpers._();

  /// Creates a mock task entity for testing
  static TaskEntity createMockTask({
    String id = 'test-task-1',
    String title = 'Test Task',
    String description = 'Test task description',
    DateTime? dueDate,
    bool isCompleted = false,
    TaskStatus status = TaskStatus.todo,
    TaskPriority priority = TaskPriority.medium,
    String? projectId,
    List<String> assignedMembers = const [],
    String? createdBy,
    String? assignedTo,
    double? estimatedHours,
    double? actualHours,
    List<String> tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return TaskEntity(
      id: id,
      title: title,
      description: description,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
      isCompleted: isCompleted,
      status: status,
      priority: priority,
      projectId: projectId,
      assignedMembers: assignedMembers,
      createdBy: createdBy,
      assignedTo: assignedTo,
      estimatedHours: estimatedHours,
      actualHours: actualHours,
      tags: tags,
      createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: updatedAt ?? DateTime.now(),
      completedAt: completedAt,
    );
  }

  /// Creates a list of mock tasks for testing
  static List<TaskEntity> createMockTaskList({int count = 5}) {
    return List.generate(count, (index) => createMockTask(
      id: 'test-task-${index + 1}',
      title: 'Test Task ${index + 1}',
      description: 'Description for test task ${index + 1}',
      dueDate: DateTime.now().add(Duration(days: index + 1)),
      status: TaskStatus.values[index % TaskStatus.values.length],
      priority: TaskPriority.values[index % TaskPriority.values.length],
    ));
  }

  /// Creates a mock user entity for testing
  static UserEntity createMockUser({
    String uid = 'test-user-1',
    String email = 'test@example.com',
    String name = 'Test User',
    UserRole role = UserRole.regular,
    List<String> assignedProjects = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    bool isActive = true,
  }) {
    return UserEntity(
      uid: uid,
      email: email,
      name: name,
      role: role,
      assignedProjects: assignedProjects,
      createdAt: createdAt ?? DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: updatedAt ?? DateTime.now(),
      isActive: isActive,
    );
  }

  /// Creates a mock failure for testing error scenarios
  static Failure createMockFailure({
    String message = 'Test failure',
    String code = 'test_error',
  }) {
    return ServerFailure(message, code: code);
  }

  /// Creates a mock Either result for testing
  static Result<T> createMockResult<T>({
    T? data,
    Failure? failure,
  }) {
    if (failure != null) {
      return Left(failure);
    }
    if (data != null) {
      return Right(data);
    }
    return const Left(ServerFailure('No data provided', code: 'no_data'));
  }

  /// Wraps a widget in a MaterialApp for testing
  static Widget wrapInMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Wraps a widget in a ProviderScope for testing
  static Widget wrapInProviderScope(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  /// Creates a testable widget with proper material and provider setup
  static Widget createTestableWidget({
    required Widget child,
    bool useProviderScope = false,
  }) {
    if (useProviderScope) {
      return wrapInProviderScope(child);
    }
    return wrapInMaterialApp(child);
  }

  /// Common test utilities
  static Future<void> pumpAndSettle(WidgetTester tester, {Duration? duration}) async {
    await tester.pumpAndSettle(duration ?? const Duration(milliseconds: 100));
  }

  /// Finds a widget by type and key
  static T findWidgetByKey<T extends Widget>(WidgetTester tester, Key key) {
    return tester.widget<T>(find.byKey(key));
  }

  /// Finds a widget by type
  static T findWidget<T extends Widget>(WidgetTester tester) {
    return tester.widget<T>(find.byType(T));
  }

  /// Verifies that a widget exists
  static void expectWidgetExists<T extends Widget>(WidgetTester tester) {
    expect(find.byType(T), findsOneWidget);
  }

  /// Verifies that a widget with specific text exists
  static void expectTextExists(WidgetTester tester, String text) {
    expect(find.text(text), findsOneWidget);
  }

  /// Verifies that a widget with specific text does not exist
  static void expectTextNotExists(WidgetTester tester, String text) {
    expect(find.text(text), findsNothing);
  }

  /// Taps a widget by type
  static Future<void> tapWidget<T extends Widget>(WidgetTester tester) async {
    await tester.tap(find.byType(T));
    await pumpAndSettle(tester);
  }

  /// Taps a widget by key
  static Future<void> tapWidgetByKey(WidgetTester tester, Key key) async {
    await tester.tap(find.byKey(key));
    await pumpAndSettle(tester);
  }

  /// Enters text in a text field
  static Future<void> enterText(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await pumpAndSettle(tester);
  }

  /// Enters text in a specific text field
  static Future<void> enterTextInField(WidgetTester tester, Finder finder, String text) async {
    await tester.enterText(finder, text);
    await pumpAndSettle(tester);
  }

  /// Scrolls until a widget is found
  static Future<void> scrollUntilVisible(
    WidgetTester tester,
    Finder finder, {
    double delta = 100.0,
  }) async {
    await tester.scrollUntilVisible(
      finder,
      delta,
    );
    await pumpAndSettle(tester);
  }

  /// Creates a mock stream for testing
  static Stream<T> createMockStream<T>(List<T> data) async* {
    for (final item in data) {
      yield item;
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  /// Creates a mock stream that emits an error
  static Stream<T> createMockErrorStream<T>(Object error) async* {
    await Future.delayed(const Duration(milliseconds: 100));
    throw error;
  }

  /// Creates a mock future for testing
  static Future<T> createMockFuture<T>(T data, {Duration? delay}) async {
    await Future.delayed(delay ?? Duration.zero);
    return data;
  }

  /// Creates a mock future that throws an error
  static Future<T> createMockErrorFuture<T>(Object error, {Duration? delay}) async {
    await Future.delayed(delay ?? Duration.zero);
    throw error;
  }
}

/// Custom matchers for testing
class CustomMatchers {
  CustomMatchers._();

  /// Matcher for checking if a widget contains specific text
  static Matcher hasText(String text) {
    return isA<Widget>();
  }

  /// Matcher for checking task properties
  static Matcher matchesTask({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return isA<TaskEntity>();
  }

  /// Matcher for checking if a result is a success
  static Matcher isSuccess<T>() {
    return isA<Result<T>>().having(
      (result) => result.isRight(),
      'isRight',
      true,
    );
  }

  /// Matcher for checking if a result is a failure
  static Matcher isFailure<T>() {
    return isA<Result<T>>().having(
      (result) => result.isLeft(),
      'isLeft',
      true,
    );
  }
}

/// Extension methods for testing
extension TestExtensions on WidgetTester {
  /// Prints a message for debugging
  void debugPrint(String message) {
    print(message);
  }

  /// Waits for a specific condition to be true
  Future<void> waitForCondition(
    bool Function() condition, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (!condition() && stopwatch.elapsed < timeout) {
      await pump(interval);
      await Future.delayed(interval);
    }
    
    if (!condition()) {
      throw Exception('Condition not met within timeout');
    }
  }
}
