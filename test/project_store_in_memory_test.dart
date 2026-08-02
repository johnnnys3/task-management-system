import 'package:flutter_test/flutter_test.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/data/project_store_in_memory.dart';
import 'package:task_management/models/project.dart';

void main() {
  late InMemoryProjectStore store;

  setUp(() {
    store = InMemoryProjectStore();
  });

  Project buildProject({
    String id = '',
    String name = 'Valid project name',
    String description = 'A valid description text',
    DateTime? dueDate,
  }) {
    return Project(
      id: id,
      name: name,
      description: description,
      dueDate: dueDate ?? DateTime.now().add(const Duration(days: 7)),
      tasks: const [],
    );
  }

  group('create', () {
    test('assigns an id and stores the project', () async {
      final id = await store.create(buildProject());
      final projects = await store.fetch();
      expect(projects.single.id, id);
    });

    test('throws ProjectValidationException for an invalid project', () {
      expect(
        () => store.create(buildProject(name: '')),
        throwsA(isA<ProjectValidationException>()),
      );
    });
  });

  group('update', () {
    test('updates an existing project', () async {
      await store.create(buildProject());
      final existing = (await store.fetch()).single;
      await store.update(existing.copyWith(name: 'Updated name'));

      final projects = await store.fetch();
      expect(projects.single.name, 'Updated name');
    });

    test('throws ProjectNotFoundException for an unknown id', () {
      expect(
        () => store.update(buildProject(id: 'missing')),
        throwsA(isA<ProjectNotFoundException>()),
      );
    });
  });

  group('delete', () {
    test('removes the project', () async {
      final id = await store.create(buildProject());
      await store.delete(id);
      expect(await store.fetch(), isEmpty);
    });

    test('throws ProjectNotFoundException for an unknown id', () {
      expect(
        () => store.delete('missing'),
        throwsA(isA<ProjectNotFoundException>()),
      );
    });
  });

  group('fetch', () {
    test('returns all stored projects', () async {
      await store.create(buildProject(name: 'First'));
      await store.create(buildProject(name: 'Second'));

      final projects = await store.fetch();
      expect(projects.map((p) => p.name), containsAll(['First', 'Second']));
    });
  });

  group('stream', () {
    test('emits the current list, then again after each change', () async {
      final emissions = <int>[];
      final sub = store.stream().listen((projects) => emissions.add(projects.length));

      await Future.delayed(Duration.zero);
      await store.create(buildProject());
      await Future.delayed(Duration.zero);
      await sub.cancel();

      expect(emissions, [0, 1]);
    });
  });
}
