import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/models/task.dart';

void main() {
  group('Task.validate', () {
    Task buildTask({
      String title = 'Valid title',
      String description = 'A valid description text',
      DateTime? dueDate,
    }) {
      return Task(id: '1', title: title, description: description, dueDate: dueDate);
    }

    test('returns no errors for a valid task', () {
      expect(buildTask().validate(), isEmpty);
    });

    test('flags empty title', () {
      expect(buildTask(title: '').validate(), contains('Task title is required'));
    });

    test('flags short title', () {
      expect(
        buildTask(title: 'ab').validate(),
        contains('Task title must be at least 3 characters'),
      );
    });

    test('flags short description', () {
      expect(
        buildTask(description: 'short').validate(),
        contains('Task description must be at least 10 characters'),
      );
    });

    test('flags due date in the past', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 5));
      expect(
        buildTask(dueDate: pastDate).validate(),
        contains('Due date cannot be in the past'),
      );
    });

    test('collects multiple errors at once', () {
      expect(buildTask(title: '', description: '').validate().length, 2);
    });
  });
}
