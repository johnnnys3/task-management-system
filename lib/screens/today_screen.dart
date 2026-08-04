/// Today -- the new home screen. Merges reporting_screen.dart (counters,
/// activity) and dashboard_screen.dart (task stats, my tasks) into one
/// scroll. Body-only: the shell owns the app bar.
///
/// ponytail: the "Recent activity" feed from the design has no backing data
/// source in this codebase (no audit-log/activity model) -- omitted rather
/// than faked. Add it when an activity log exists.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/screens/task_details_screen.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';

import '../navigation/app_shell.dart';

class TodayScreen extends StatefulWidget implements ShellPage {
  const TodayScreen({
    super.key,
    required this.currentUserId,
    required this.role,
  });

  final String currentUserId;
  final UserRole role;

  @override
  String get title => 'Today';

  @override
  String? get subtitle => DateFormat('EEEE, d MMMM').format(DateTime.now());

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late final TaskStore _taskStore;
  List<Task> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _taskStore = context.read<TaskStore>();
    _load();
  }

  Future<void> _load() async {
    final tasks = await _taskStore.fetch(
      userId: widget.role == UserRole.regular ? widget.currentUserId : null,
    );
    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _toggle(Task task) async {
    await _taskStore.update(task.isCompleted ? task.withStatus(TaskStatus.todo) : task.markAsCompleted());
    _load();
  }

  void _open(Task task) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailsScreen(task: task)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.terra));
    }

    final open = _tasks.where((t) => !t.isCompleted).toList();
    final overdue = open.where((t) => t.isOverdue).toList();
    final dueToday = open.where((t) => t.isDueToday).toList();
    final completed = _tasks.where((t) => t.isCompleted).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 4 : 2,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 1.9,
            children: [
              _StatCard(value: open.length, label: 'Open'),
              _StatCard(value: dueToday.length, label: 'Due today'),
              _StatCard(value: overdue.length, label: 'Overdue', alert: overdue.isNotEmpty),
              _StatCard(value: completed.length, label: 'Completed'),
            ],
          ),
          if (overdue.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(color: AppColors.blush, borderRadius: BorderRadius.circular(26)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error, size: 21, color: AppColors.rust),
                      const SizedBox(width: 8),
                      Text('Needs attention', style: AppTheme.display(size: 18, color: AppColors.rust)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final t in overdue.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TodayTaskRow(
                        task: t,
                        overdue: true,
                        compact: true,
                        onOpen: () => _open(t),
                        onToggle: () => _toggle(t),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text('On your plate', style: AppTheme.display(size: 19)),
          const SizedBox(height: 10),
          if (open.isEmpty)
            Container(
              padding: const EdgeInsets.all(30),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(26)),
              child: const Text('Nothing open. Enjoy it.', style: TextStyle(color: AppColors.ink2)),
            )
          else
            for (final t in open.take(6))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TodayTaskRow(
                  task: t,
                  overdue: t.isOverdue,
                  onOpen: () => _open(t),
                  onToggle: () => _toggle(t),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, this.alert = false});

  final int value;
  final String label;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: alert ? AppColors.blush : AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [BoxShadow(color: Color(0x12282624), blurRadius: 2, offset: Offset(0, 1))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value', style: AppTheme.display(size: 32, color: alert ? AppColors.rust : AppColors.ink)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.ink2)),
        ],
      ),
    );
  }
}

/// Shared task row -- used by Today and (via task_list_screen) Tasks list view.
class TodayTaskRow extends StatelessWidget {
  const TodayTaskRow({
    super.key,
    required this.task,
    required this.onOpen,
    required this.onToggle,
    this.overdue = false,
    this.compact = false,
  });

  final Task task;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final bool overdue;

  /// `compact` = the variant inside the Needs-attention card (radius 16,
  /// no priority pill, meta in rust).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final prio = AppColors.priorityColors(task.priority);
    final assignee = task.assignedTo ?? '?';
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(compact ? 16 : 18),
        onTap: onOpen,
        hoverColor: AppColors.ink.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          child: Row(
            children: [
              GestureDetector(
                onTap: onToggle,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? AppColors.terra : Colors.transparent,
                    shape: BoxShape.circle,
                    border: task.isCompleted ? null : Border.all(color: AppColors.ink.withOpacity(0.25), width: 1.5),
                  ),
                  child: task.isCompleted ? const Icon(Icons.check, size: 15, color: AppColors.shell) : null,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: task.isCompleted ? AppColors.ink3 : AppColors.ink,
                        decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_dueLabel(task.dueDate)} · ${task.associatedProject?.name ?? 'No project'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                        color: overdue ? AppColors.rust : AppColors.ink2,
                      ),
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: prio.bg, borderRadius: BorderRadius.circular(99)),
                  child: Text(task.priority.name,
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: prio.fg)),
                ),
              ],
              const SizedBox(width: 8),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.avatarColor(assignee), shape: BoxShape.circle),
                child: Text(_initials(assignee),
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.shell)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _initials(String name) =>
      name.trim().split(RegExp(r'\s+')).take(2).map((p) => p.isEmpty ? '' : p[0].toUpperCase()).join();

  static String _dueLabel(DateTime? due) {
    if (due == null) return 'No due date';
    final now = DateTime.now();
    final days = DateTime(due.year, due.month, due.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days == -1) return '1 day overdue';
    if (days < 0) return '${-days} days overdue';
    if (days < 7) return 'Due in $days days';
    return 'Due ${due.day}/${due.month}';
  }
}
