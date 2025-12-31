import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/domain/entities/task_entity.dart';

void main() {
  group('TaskEntity Tests', () {
    // Test creation
    test('should create TaskEntity with required fields', () {
      // Arrange
      const task = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
      );

      // Assert
      expect(task.id, equals('test-1'));
      expect(task.title, equals('Test Task'));
      expect(task.description, equals('Test Description'));
      expect(task.isCompleted, isFalse);
      expect(task.status, equals(TaskStatus.todo));
      expect(task.priority, equals(TaskPriority.medium));
    });

    // Test copyWith
    test('should create copy with updated fields', () {
      // Arrange
      const originalTask = TaskEntity(
        id: 'test-1',
        title: 'Original Task',
        description: 'Original Description',
      );

      // Act
      final updatedTask = originalTask.copyWith(
        title: 'Updated Task',
        isCompleted: true,
        status: TaskStatus.completed,
      );

      // Assert
      expect(updatedTask.id, equals('test-1'));
      expect(updatedTask.title, equals('Updated Task'));
      expect(updatedTask.description, equals('Original Description'));
      expect(updatedTask.isCompleted, isTrue);
      expect(updatedTask.status, equals(TaskStatus.completed));
    });

    // Test status methods
    test('should mark task as completed', () {
      // Arrange
      const task = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
      );

      // Act
      final completedTask = task.markAsCompleted();

      // Assert
      expect(completedTask.isCompleted, isTrue);
      expect(completedTask.status, equals(TaskStatus.completed));
      expect(completedTask.completedAt, isNotNull);
    });

    test('should update task status', () {
      // Arrange
      const task = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
      );

      // Act
      final updatedTask = task.withStatus(TaskStatus.inProgress);

      // Assert
      expect(updatedTask.status, equals(TaskStatus.inProgress));
      expect(updatedTask.isCompleted, isFalse);
    });

    // Test due date methods
    test('should check if task is due today', () {
      // Arrange
      final today = DateTime.now();
      final task = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
        dueDate: DateTime(today.year, today.month, today.day),
      );

      // Act & Assert
      expect(task.isDueToday, isTrue);
    });

    test('should check if task is overdue', () {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final task = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
        dueDate: yesterday,
      );

      // Act & Assert
      expect(task.isOverdue, isTrue);
    });

    test('should check if task is due soon', () {
      // Arrange
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final task = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
        dueDate: tomorrow,
      );

      // Act & Assert
      expect(task.isDueSoon, isTrue);
    });

    test('should calculate days until due', () {
      // Arrange
      final futureDate = DateTime.now().add(const Duration(days: 5));
      final task = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
        dueDate: futureDate,
      );

      // Act & Assert
      expect(task.daysUntilDue, equals(5));
    });

    // Test efficiency calculation
    test('should calculate efficiency correctly', () {
      // Arrange
      final task = const TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
        estimatedHours: 10.0,
        actualHours: 5.0,
      );

      // Act & Assert
      expect(task.efficiency, equals(2.0));
    });

    test('should return null efficiency when data is missing', () {
      // Arrange
      final task1 = const TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
        estimatedHours: null,
        actualHours: 5.0,
      );
      final task2 = const TaskEntity(
        id: 'test-2',
        title: 'Test Task',
        description: 'Test Description',
        estimatedHours: 10.0,
        actualHours: null,
      );
      final task3 = const TaskEntity(
        id: 'test-3',
        title: 'Test Task',
        description: 'Test Description',
        estimatedHours: 0.0,
        actualHours: 5.0,
      );

      // Act & Assert
      expect(task1.efficiency, isNull);
      expect(task2.efficiency, isNull);
      expect(task3.efficiency, isNull);
    });

    // Test equality
    test('should consider tasks equal when all fields match', () {
      // Arrange
      const task1 = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
      );

      const task2 = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
      );

      // Act & Assert
      expect(task1, equals(task2));
    });

    test('should consider tasks different when id differs', () {
      // Arrange
      const task1 = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
      );

      const task2 = TaskEntity(
        id: 'test-2',
        title: 'Test Task',
        description: 'Test Description',
      );

      // Act & Assert
      expect(task1, isNot(equals(task2)));
    });

    // Test toString
    test('should return meaningful string representation', () {
      // Arrange
      const task = TaskEntity(
        id: 'test-1',
        title: 'Test Task',
        description: 'Test Description',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
      );

      // Act
      final result = task.toString();

      // Assert
      expect(result, contains('test-1'));
      expect(result, contains('Test Task'));
      expect(result, contains('TaskStatus.inProgress'));
      expect(result, contains('TaskPriority.high'));
    });
  });

  group('TaskStatus Tests', () {
    test('should convert string to TaskStatus', () {
      expect(TaskStatus.fromString('todo'), equals(TaskStatus.todo));
      expect(TaskStatus.fromString('in_progress'), equals(TaskStatus.inProgress));
      expect(TaskStatus.fromString('completed'), equals(TaskStatus.completed));
      expect(TaskStatus.fromString('invalid'), equals(TaskStatus.todo)); // Default case
    });

    test('should have correct values', () {
      expect(TaskStatus.todo.value, equals('todo'));
      expect(TaskStatus.inProgress.value, equals('in_progress'));
      expect(TaskStatus.review.value, equals('review'));
      expect(TaskStatus.completed.value, equals('completed'));
      expect(TaskStatus.cancelled.value, equals('cancelled'));
    });
  });

  group('TaskPriority Tests', () {
    test('should convert string to TaskPriority', () {
      expect(TaskPriority.fromString('low'), equals(TaskPriority.low));
      expect(TaskPriority.fromString('medium'), equals(TaskPriority.medium));
      expect(TaskPriority.fromString('high'), equals(TaskPriority.high));
      expect(TaskPriority.fromString('urgent'), equals(TaskPriority.urgent));
      expect(TaskPriority.fromString('invalid'), equals(TaskPriority.medium)); // Default case
    });

    test('should have correct values', () {
      expect(TaskPriority.low.value, equals('low'));
      expect(TaskPriority.medium.value, equals('medium'));
      expect(TaskPriority.high.value, equals('high'));
      expect(TaskPriority.urgent.value, equals('urgent'));
    });
  });
}
