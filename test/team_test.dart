import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/models/team.dart';

void main() {
  group('Team.validate', () {
    Team buildTeam({
      String name = 'Engineering',
      String description = 'A valid description text',
    }) {
      return Team(id: '1', name: name, description: description);
    }

    test('returns no errors for a valid team', () {
      expect(buildTeam().validate(), isEmpty);
    });

    test('flags empty name', () {
      expect(buildTeam(name: '').validate(), contains('Team name is required'));
    });

    test('flags short name', () {
      expect(
        buildTeam(name: 'a').validate(),
        contains('Team name must be at least 2 characters'),
      );
    });

    test('flags long description', () {
      expect(
        buildTeam(description: 'a' * 501).validate(),
        contains('Team description must be less than 500 characters'),
      );
    });

    test('collects multiple errors at once', () {
      expect(buildTeam(name: '', description: 'a' * 501).validate().length, 2);
    });
  });
}
