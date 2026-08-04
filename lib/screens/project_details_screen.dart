/// Project details screen: header card (swatch, name, status pill, progress,
/// meta), and a Tasks section reusing the shared task row from Today/Tasks.
/// Editing happens on [UpdateProjectScreen]; this screen is read-only + delete.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/models/project.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/screens/task_details_screen.dart';
import 'package:task_management/screens/today_screen.dart' show TodayTaskRow;
import 'package:task_management/screens/update_project_screen.dart';
import 'package:task_management/screens/create_project_screen.dart' show projectStatusLabel;
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/pill_button.dart';
import 'package:task_management/widgets/progress_bar.dart';

/// Header status pill colors for a [ProjectStatus], distinct from the
/// terra/amber/sage tint used on project list cards: active/at-risk/done
/// mapped onto the mint/blush/sand tokens per the details-screen design.
///
/// ponytail: [ProjectStatus] has no "at risk" value -- onHold is treated as
/// at-risk, planning/cancelled fall back to the neutral "done" (sand) look.
({Color bg, Color fg}) _headerStatusColors(ProjectStatus status) {
  switch (status) {
    case ProjectStatus.inProgress:
      return (bg: AppColors.mint, fg: AppColors.terraDark);
    case ProjectStatus.onHold:
      return (bg: AppColors.blush, fg: AppColors.rust);
    case ProjectStatus.completed:
    case ProjectStatus.planning:
    case ProjectStatus.cancelled:
      return (bg: AppColors.sand, fg: AppColors.ink2);
  }
}

class ProjectDetailsScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  late Project _project;
  List<Task> _tasks = [];
  bool _isLoading = true;
  String _errorMessage = '';

  late final ProjectStore _projectStore;
  late final TaskStore _taskStore;

  @override
  void initState() {
    super.initState();
    _projectStore = context.read<ProjectStore>();
    _taskStore = context.read<TaskStore>();
    _project = widget.project;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      // ponytail: ProjectStore has no get-by-id; fetch and find locally. Add
      // a dedicated lookup if this ever needs to scale past a small project list.
      final projects = await _projectStore.fetch();
      final matches = projects.where((p) => p.id == _project.id);
      final fetchedProject = matches.isEmpty ? null : matches.first;

      final fetchedTasks = await _taskStore.fetch();
      final projectTasks =
          fetchedTasks.where((task) => task.associatedProject?.id == _project.id).toList();

      if (!mounted) return;
      setState(() {
        if (fetchedProject != null) _project = fetchedProject;
        _tasks = projectTasks;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load project: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _editProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UpdateProjectScreen(project: _project)),
    );
    if (result != null && result is Project) {
      setState(() => _project = result);
    }
    _load();
  }

  Future<void> _toggleTask(Task task) async {
    await _taskStore.update(task.isCompleted ? task.withStatus(TaskStatus.todo) : task.markAsCompleted());
    _load();
  }

  void _openTask(Task task) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task))).then((_) => _load());
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${_project.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.rust)),
          ),
        ],
      ),
    );
    if (confirmed == true) _deleteProject();
  }

  Future<void> _deleteProject() async {
    try {
      await _projectStore.delete(_project.id);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete project: $error'), backgroundColor: AppColors.rust),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Project Details', style: AppTheme.display(size: 20)),
        actions: [
          IconButton(icon: const Icon(Icons.edit), tooltip: 'Edit Project', onPressed: _editProject),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.terra))
          : _errorMessage.isNotEmpty
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppColors.rust),
          const SizedBox(height: 12),
          Text(_errorMessage, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.ink2)),
          const SizedBox(height: 16),
          PillButton(label: 'Retry', onPressed: _load),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final total = _tasks.length;
    final done = _tasks.where((t) => t.isCompleted).length;
    final progress = total == 0 ? 0.0 : done / total;
    final isOverdue = !_project.isCompleted && _project.dueDate.isBefore(DateTime.now());

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          AppCard(child: _buildHeader(progress, done, total, isOverdue)),
          const SizedBox(height: 16),
          Text('Tasks (${_tasks.length})', style: AppTheme.display(size: 19)),
          const SizedBox(height: 10),
          if (_tasks.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(26)),
              child: const Text('No tasks yet', style: TextStyle(color: AppColors.ink2)),
            )
          else
            for (final t in _tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TodayTaskRow(task: t, overdue: t.isOverdue, onOpen: () => _openTask(t), onToggle: () => _toggleTask(t)),
              ),
          const SizedBox(height: 20),
          PillButton(
            label: 'Delete Project',
            outlined: true,
            danger: true,
            onPressed: _confirmDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double progress, int done, int total, bool isOverdue) {
    final statusColors = _headerStatusColors(_project.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(color: AppColors.avatarColor(_project.id), shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(_project.name, style: AppTheme.display(size: 24, color: AppColors.ink)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColors.bg, borderRadius: BorderRadius.circular(99)),
              child: Text(
                projectStatusLabel(_project.status),
                style: TextStyle(color: statusColors.fg, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        if (_project.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(_project.description, style: const TextStyle(fontSize: 15, color: AppColors.ink2, height: 1.4)),
        ],
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$done of $total done', style: const TextStyle(fontSize: 13, color: AppColors.ink2, fontWeight: FontWeight.w600)),
            Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 13, color: AppColors.ink2, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 6),
        AppProgressBar(value: progress),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _metaItem(Icons.event, 'Due ${DateFormat('MMM d, yyyy').format(_project.dueDate)}', isOverdue),
            // ponytail: Project has no team association -- showing assigned
            // member count in its place rather than a team name.
            _metaItem(Icons.people_outline, '${_project.assignedUsers.length} members', false),
          ],
        ),
      ],
    );
  }

  Widget _metaItem(IconData icon, String label, bool alert) {
    final color = alert ? AppColors.rust : AppColors.ink2;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: alert ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }
}
