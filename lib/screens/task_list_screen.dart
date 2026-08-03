/// Tasks screen: List/Board toggle, filter chips, grouped list, kanban board.
/// Body-only -- the shell owns search and the top bar.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/models/task.dart' as TaskModel;
import 'package:task_management/screens/task_details_screen.dart';
import 'package:task_management/screens/task_creation_screen.dart';
import 'package:task_management/screens/today_screen.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/navigation/app_shell.dart';

enum TaskViewMode { list, board }

/// Fixed status order for both the grouped list and the board columns.
const _kStatusOrder = [
  TaskModel.TaskStatus.todo,
  TaskModel.TaskStatus.inProgress,
  TaskModel.TaskStatus.review,
  TaskModel.TaskStatus.completed,
];

const _kStatusLabels = {
  TaskModel.TaskStatus.todo: 'To do',
  TaskModel.TaskStatus.inProgress: 'In progress',
  TaskModel.TaskStatus.review: 'In review',
  TaskModel.TaskStatus.completed: 'Done',
};

class TaskListScreen extends StatefulWidget implements ShellPage {
  /// User ID for filtering tasks
  final String userId;
  /// Current user information
  final CustomUser user;
  /// Admin status for permission-based actions
  final bool isAdmin;
  /// Initial list of tasks
  final List<TaskModel.Task> tasks;

  const TaskListScreen({
    Key? key,
    required this.userId,
    required this.user,
    required this.isAdmin,
    required this.tasks,
  }) : super(key: key);

  @override
  String get title => 'Tasks';

  @override
  String? get subtitle => null;

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with AutomaticKeepAliveClientMixin {
  List<TaskModel.Task> _tasks = [];
  List<TaskModel.Task> _filteredTasks = [];
  late final TaskStore _taskStore;
  bool _isLoading = false;
  String _errorMessage = '';

  TaskViewMode _view = TaskViewMode.list;
  String _selectedFilter = 'All';
  static const _filterOptions = ['All', 'Mine', 'Due soon', 'Overdue'];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _taskStore = context.read<TaskStore>();
    _tasks = widget.tasks;
    _filteredTasks = _tasks;
    _loadTasks();
  }

  /// Loads tasks from database with error handling
  /// Updates both full list and filtered list
  Future<void> _loadTasks() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final loadedTasks = await _taskStore.fetch(userId: widget.userId);

      setState(() {
        _tasks = loadedTasks;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading tasks: $e';
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredTasks = _tasks.where(_matchesFilter).toList()
        ..sort((a, b) => (a.dueDate ?? DateTime(9999)).compareTo(b.dueDate ?? DateTime(9999)));
    });
  }

  bool _matchesFilter(TaskModel.Task task) {
    switch (_selectedFilter) {
      case 'Mine':
        return task.assignedTo == widget.userId;
      case 'Due soon':
        return task.isDueSoon;
      case 'Overdue':
        return task.isOverdue;
      default:
        return true; // 'All'
    }
  }

  Future<void> _toggleDone(TaskModel.Task task) async {
    await _taskStore.update(
      task.isCompleted ? task.withStatus(TaskModel.TaskStatus.todo) : task.markAsCompleted(),
    );
    _loadTasks();
  }

  Future<void> _moveStatus(TaskModel.Task task, int direction) async {
    final index = _kStatusOrder.indexOf(task.status);
    final newIndex = index + direction;
    if (index < 0 || newIndex < 0 || newIndex >= _kStatusOrder.length) return;
    await _taskStore.update(task.withStatus(_kStatusOrder[newIndex]));
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        _buildContent(),
        if (_isLoading) _buildLoadingOverlay(),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: _navigateToCreateTask,
            icon: const Icon(Icons.add),
            label: const Text('Create Task'),
            backgroundColor: AppColors.terra,
          ),
        ),
      ],
    );
  }

  /// List/Board segmented toggle + live filter chips.
  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          _buildViewToggle(),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in _filterOptions) _buildFilterChip(filter),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(99)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _viewToggleButton(TaskViewMode.list, Icons.view_list_rounded, 'List'),
          _viewToggleButton(TaskViewMode.board, Icons.view_column_rounded, 'Board'),
        ],
      ),
    );
  }

  Widget _viewToggleButton(TaskViewMode mode, IconData icon, String label) {
    final selected = _view == mode;
    return GestureDetector(
      onTap: () => setState(() => _view = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.paper : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          boxShadow: selected
              ? [const BoxShadow(color: Color(0x14282624), blurRadius: 4, offset: Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.ink : AppColors.ink2),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: selected ? AppColors.ink : AppColors.ink2)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final selected = _selectedFilter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedFilter = filter);
          _applyFilter();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? AppColors.terra : AppColors.sand,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(filter,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.shell : AppColors.ink2)),
        ),
      ),
    );
  }

  /// Builds main content area
  /// Creates layout with error display and task list
  Widget _buildContent() {
    return Column(
      children: [
        _buildToolbar(),
        if (_errorMessage.isNotEmpty) _buildErrorMessage(),
        _buildTaskStatistics(),
        Expanded(
          child: _filteredTasks.isEmpty
              ? _buildEmptyState()
              : (_view == TaskViewMode.list ? _buildListView() : _buildBoardView()),
        ),
      ],
    );
  }

  /// Builds error message widget
  /// Shows error with dismiss option
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.rust.withOpacity(0.08),
        border: Border.all(color: AppColors.rust.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.rust),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: const TextStyle(color: AppColors.rust),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _errorMessage = '';
              });
            },
          ),
        ],
      ),
    );
  }

  /// Builds loading overlay
  /// Shows loading indicator during operations
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading tasks...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds task statistics
  /// Shows count of tasks by status
  Widget _buildTaskStatistics() {
    final completedCount = _tasks.where((task) => task.isCompleted).length;
    final pendingCount = _tasks.where((task) => !task.isCompleted).length;
    final overdueCount = _tasks.where((task) => task.isOverdue).length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Total', _tasks.length.toString(), AppColors.terra),
          const SizedBox(width: 8),
          _buildStatCard('Completed', completedCount.toString(), AppColors.sage),
          const SizedBox(width: 8),
          _buildStatCard('Pending', pendingCount.toString(), AppColors.statusReview),
          const SizedBox(width: 8),
          _buildStatCard('Overdue', overdueCount.toString(), AppColors.rust),
        ],
      ),
    );
  }

  /// Builds individual statistic card
  /// Creates styled card for task count
  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds empty state widget
  /// Shows message when no tasks match filters
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.inbox_outlined,
            size: 64,
            color: AppColors.ink3,
          ),
          const SizedBox(height: 16),
          const Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.ink2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try a different filter or create a new task',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }

  /// List view: grouped by status in fixed order, using the shared task row.
  Widget _buildListView() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        for (final status in _kStatusOrder)
          if (_filteredTasks.any((t) => t.status == status)) ...[
            _buildGroupHeader(status),
            const SizedBox(height: 8),
            for (final t in _filteredTasks.where((t) => t.status == status))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TodayTaskRow(
                  task: t,
                  overdue: t.isOverdue,
                  onOpen: () => _navigateToTaskDetailsScreen(t),
                  onToggle: () => _toggleDone(t),
                ),
              ),
            const SizedBox(height: 6),
          ],
      ],
    );
  }

  Widget _buildGroupHeader(TaskModel.TaskStatus status) {
    final count = _filteredTasks.where((t) => t.status == status).length;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: AppColors.statusColor(status), shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          _kStatusLabels[status]!.toUpperCase(),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.08, color: AppColors.ink2),
        ),
        const SizedBox(width: 6),
        Text('$count', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
      ],
    );
  }

  /// Board view: horizontally scrollable columns, one per status.
  Widget _buildBoardView() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < _kStatusOrder.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 11),
              child: _BoardColumn(
                status: _kStatusOrder[i],
                tasks: _filteredTasks.where((t) => t.status == _kStatusOrder[i]).toList(),
                onOpen: _navigateToTaskDetailsScreen,
                onMoveBack: i > 0 ? (t) => _moveStatus(t, -1) : null,
                onMoveForward: i < _kStatusOrder.length - 1 ? (t) => _moveStatus(t, 1) : null,
              ),
            ),
        ],
      ),
    );
  }

  /// Navigates to task creation screen
  /// Handles task creation and result
  Future<void> _navigateToCreateTask() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTask(availableProjects: []),
      ),
    );

    if (result != null && result is TaskModel.Task) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });
        await _taskStore.create(result.copyWith(assignedTo: widget.userId));
        await _loadTasks();
      } catch (e) {
        setState(() {
          _errorMessage = 'Error adding task: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Navigates to task details screen
  /// Opens task details for viewing and editing
  void _navigateToTaskDetailsScreen(TaskModel.Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TaskDetailsScreen(task: task)),
    ).then((_) => _loadTasks());
  }
}

/// One kanban column: status header + up to N cards, foot chevrons to move
/// a card back/forward through [_kStatusOrder].
class _BoardColumn extends StatelessWidget {
  const _BoardColumn({
    required this.status,
    required this.tasks,
    required this.onOpen,
    required this.onMoveBack,
    required this.onMoveForward,
  });

  final TaskModel.TaskStatus status;
  final List<TaskModel.Task> tasks;
  final void Function(TaskModel.Task) onOpen;
  final void Function(TaskModel.Task)? onMoveBack;
  final void Function(TaskModel.Task)? onMoveForward;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: AppColors.statusColor(status), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                _kStatusLabels[status]!.toUpperCase(),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.08, color: AppColors.ink2),
              ),
              const SizedBox(width: 6),
              Text('${tasks.length}', style: const TextStyle(fontSize: 12, color: AppColors.ink3)),
            ],
          ),
          const SizedBox(height: 9),
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _BoardCard(
                task: t,
                onOpen: () => onOpen(t),
                onMoveBack: onMoveBack == null ? null : () => onMoveBack!(t),
                onMoveForward: onMoveForward == null ? null : () => onMoveForward!(t),
              ),
            ),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No tasks', style: TextStyle(fontSize: 12.5, color: AppColors.ink3)),
            ),
        ],
      ),
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.task,
    required this.onOpen,
    required this.onMoveBack,
    required this.onMoveForward,
  });

  final TaskModel.Task task;
  final VoidCallback onOpen;
  final VoidCallback? onMoveBack;
  final VoidCallback? onMoveForward;

  @override
  Widget build(BuildContext context) {
    final prio = AppColors.priorityColors(task.priority);
    return Material(
      color: AppColors.paper,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onOpen,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x14282624), blurRadius: 2, offset: Offset(0, 1))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // maxLines: 3 + softWrap -- do not collapse this to maxLines: 1,
              // that regression is why board cards used to clip titles.
              Text(
                task.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: prio.bg, borderRadius: BorderRadius.circular(99)),
                child: Text(task.priority.name,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: prio.fg)),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ChevronButton(icon: Icons.chevron_left, onTap: onMoveBack),
                  _ChevronButton(icon: Icons.chevron_right, onTap: onMoveForward),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(icon, size: 18, color: AppColors.ink2),
          ),
        ),
      ),
    );
  }
}
