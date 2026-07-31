import 'package:task_management/models/task.dart';

// ponytail: search is filtered client-side by both TaskStore adapters —
// Firestore can't combine a prefix search on title/description with the
// other equality/range filters. Move server-side if result sets get large.
List<Task> filterTasksBySearchQuery(List<Task> tasks, String? searchQuery) {
  if (searchQuery == null || searchQuery.isEmpty) return tasks;
  final query = searchQuery.toLowerCase();
  return tasks
      .where((task) =>
          task.title.toLowerCase().contains(query) ||
          task.description.toLowerCase().contains(query))
      .toList();
}
