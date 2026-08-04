/// Task details screen matching the TaskHub redesign: big header card with a
/// circular completion toggle, status/priority/due pills, a two-column
/// "Details" + "Move to status" / actions layout (single column under 900px).
///
/// ponytail: the Task model has no subtasks field (see lib/models/task.dart)
/// so the mockup's subtask checklist is omitted rather than faked with
/// local-only state that wouldn't persist.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/avatar_badge.dart';
import 'package:task_management/widgets/pill_button.dart';
import 'package:task_management/widgets/priority_badge.dart';
import 'package:task_management/widgets/progress_bar.dart';
import 'package:task_management/widgets/status_chip.dart';
import 'package:task_management/screens/update_task_screen.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late final TaskStore _taskStore;
  late Task _task;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _taskStore = context.read<TaskStore>();
    _task = widget.task;
  }

  bool get _isOverdue =>
      !_task.isCompleted && _task.hasDueDate && _task.dueDate != null && _task.dueDate!.isBefore(DateTime.now());

  String _formatDate(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  void _showError(Object error) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString()), backgroundColor: AppColors.rust),
    );
  }

  Future<void> _toggleCompletion() async {
    setState(() => _isLoading = true);
    final updated = _task.isCompleted ? _task.withStatus(TaskStatus.todo) : _task.markAsCompleted();
    try {
      await _taskStore.update(updated);
      if (!mounted) return;
      setState(() {
        _task = updated;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e);
    }
  }

  Future<void> _setStatus(TaskStatus status) async {
    if (status == _task.status) return;
    setState(() => _isLoading = true);
    final updated = _task.withStatus(status);
    try {
      await _taskStore.update(updated);
      if (!mounted) return;
      setState(() {
        _task = updated;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e);
    }
  }

  Future<void> _editTask() async {
    final result = await Navigator.push<Task>(
      context,
      MaterialPageRoute(builder: (_) => UpdateTaskScreen(task: _task)),
    );
    if (result != null && mounted) {
      setState(() => _task = result);
    }
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task'),
        content: Text('Are you sure you want to delete "${_task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.rust)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _taskStore.delete(_task.id);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(title: const Text('Task details')),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 900;
                      final left = _buildDetailsCard();
                      final right = _buildSidePanel();
                      if (!wide) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [left, const SizedBox(height: 14), right],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: left),
                          const SizedBox(width: 14),
                          Expanded(child: right),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(child: CircularProgressIndicator(color: AppColors.terra)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _toggleCompletion,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 34,
                  height: 34,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: _task.isCompleted ? AppColors.sage : Colors.transparent,
                    shape: BoxShape.circle,
                    border: _task.isCompleted ? null : Border.all(color: AppColors.ink.withOpacity(0.28), width: 2),
                  ),
                  child: _task.isCompleted ? const Icon(Icons.check, size: 20, color: AppColors.shell) : null,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _task.title,
                      style: AppTheme.display(size: 24, color: AppColors.ink).copyWith(
                        decoration: _task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (_task.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _task.description,
                        style: const TextStyle(fontSize: 14.5, color: AppColors.ink2, height: 1.45),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(status: _task.status),
              PriorityBadge(priority: _task.priority),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _isOverdue ? AppColors.blush : AppColors.sand,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today, size: 12, color: _isOverdue ? AppColors.rust : AppColors.ink2),
                    const SizedBox(width: 5),
                    Text(
                      _task.dueDate != null ? _formatDate(_task.dueDate!) : 'No due date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isOverdue ? AppColors.rust : AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final assignee = _task.assignedTo;
    final hours = _task.estimatedHours;
    final actual = _task.actualHours;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details', style: AppTheme.display(size: 16)),
          const SizedBox(height: 14),
          _detailRow(Icons.person_outline, 'Assignee', assignee != null && assignee.isNotEmpty ? assignee : 'Unassigned'),
          const SizedBox(height: 12),
          _detailRow(Icons.folder_outlined, 'Project', _task.associatedProject?.name ?? 'No project'),
          const SizedBox(height: 12),
          _detailRow(
            Icons.calendar_today_outlined,
            'Due date',
            _task.dueDate != null ? _formatDate(_task.dueDate!) : 'No due date',
            isOverdue: _isOverdue,
          ),
          const SizedBox(height: 12),
          _detailRow(Icons.flag_outlined, 'Priority', PriorityBadge.labelOf(_task.priority)),
          const SizedBox(height: 12),
          _detailRow(
            Icons.groups_outlined,
            'Team',
            _task.assignedMembers.isNotEmpty ? '${_task.assignedMembers.length} member(s)' : 'No team',
          ),
          if (hours != null && hours > 0) ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Time logged', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink2)),
                Text(
                  '${(actual ?? 0).toStringAsFixed(1)} / ${hours.toStringAsFixed(1)}h',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AppProgressBar(value: hours == 0 ? 0 : (actual ?? 0) / hours),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, {bool isOverdue = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: isOverdue ? AppColors.rust : AppColors.ink3),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.ink3)),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: isOverdue ? AppColors.rust : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSidePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Move to', style: AppTheme.display(size: 16)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskStatus.values.map((status) {
                  final selected = status == _task.status;
                  final color = AppColors.statusColor(status);
                  return GestureDetector(
                    onTap: () => _setStatus(status),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color : AppColors.sand,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        statusLabel(status),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppColors.shell : AppColors.ink2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_task.assignedMembers.isNotEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Assigned to', style: AppTheme.display(size: 16)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _task.assignedMembers.map((member) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AvatarBadge(name: member, size: 26),
                        const SizedBox(width: 8),
                        Text(member, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        if (_task.assignedMembers.isNotEmpty) const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: PillButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                onPressed: _isLoading ? null : _editTask,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PillButton(
                label: 'Delete',
                icon: Icons.delete_outline,
                outlined: true,
                danger: true,
                onPressed: _isLoading ? null : _deleteTask,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
