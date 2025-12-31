import 'package:flutter/material.dart';
import 'package:task_management/domain/entities/task_entity.dart';

/// Lazy loading task list widget with pagination support
class LazyTaskList extends StatefulWidget {

  const LazyTaskList({
    super.key,
    required this.tasks,
    this.onTaskTap,
    this.onTaskLongPress,
    this.scrollController,
    this.isLoading = false,
    this.emptyMessage,
    this.emptyDescription,
  });
  final List<TaskEntity> tasks;
  final Function(TaskEntity)? onTaskTap;
  final Function(TaskEntity)? onTaskLongPress;
  final ScrollController? scrollController;
  final bool isLoading;
  final String? emptyMessage;
  final String? emptyDescription;

  @override
  State<LazyTaskList> createState() => _LazyTaskListState();
}

class _LazyTaskListState extends State<LazyTaskList> {
  static const int _pageSize = 20;
  
  late ScrollController _scrollController;
  int _displayedItemCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _updateDisplayedItemCount();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(LazyTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tasks.length != widget.tasks.length) {
      _updateDisplayedItemCount();
    }
  }

  void _updateDisplayedItemCount() {
    setState(() {
      _displayedItemCount = widget.tasks.length < _pageSize 
          ? widget.tasks.length 
          : _pageSize;
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = maxScroll - currentScroll;

    // Preload more items when we're near the bottom
    if (delta < 200 && _displayedItemCount < widget.tasks.length) {
      _loadMoreItems();
    }
  }

  void _loadMoreItems() {
    if (_displayedItemCount >= widget.tasks.length) return;

    setState(() {
      _displayedItemCount = (_displayedItemCount + _pageSize)
          .clamp(0, widget.tasks.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty && !widget.isLoading) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _displayedItemCount + (widget.isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _displayedItemCount && widget.isLoading) {
                return _buildLoadingIndicator();
              }

              if (index >= _displayedItemCount) {
                return const SizedBox.shrink();
              }

              final task = widget.tasks[index];
              return TaskItemWidget(
                key: ValueKey(task.id),
                task: task,
                onTap: () => widget.onTaskTap?.call(task),
                onLongPress: () => widget.onTaskLongPress?.call(task),
              );
            },
          ),
        ),
        if (_displayedItemCount < widget.tasks.length)
          _buildLoadMoreButton(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage ?? 'No tasks found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (widget.emptyDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.emptyDescription!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: _loadMoreItems,
        child: Text('Load More (${widget.tasks.length - _displayedItemCount} remaining)'),
      ),
    );
  }
}

/// Optimized task item widget with const constructors
class TaskItemWidget extends StatelessWidget {

  const TaskItemWidget({
    super.key,
    required this.task,
    this.onTap,
    this.onLongPress,
  });
  final TaskEntity task;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildCheckbox(),
              const SizedBox(width: 12),
              Expanded(child: _buildTaskInfo()),
              _buildStatusBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: task.isCompleted 
              ? Colors.green 
              : Colors.grey.shade400,
          width: 2,
        ),
        color: task.isCompleted ? Colors.green : Colors.transparent,
      ),
      child: task.isCompleted
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }

  Widget _buildTaskInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          task.title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted 
                ? Colors.grey.shade600 
                : Theme.of(Get.context!).colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (task.description.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            task.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (task.dueDate != null) ...[
          const SizedBox(height: 4),
          Text(
            'Due: ${_formatDate(task.dueDate!)}',
            style: TextStyle(
              fontSize: 12,
              color: _getDueDateColor(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor = Colors.grey;
    String statusText = 'TODO';

    switch (task.status) {
      case TaskStatus.completed:
        badgeColor = Colors.green;
        statusText = 'DONE';
        break;
      case TaskStatus.inProgress:
        badgeColor = Colors.blue;
        statusText = 'IN PROGRESS';
        break;
      case TaskStatus.review:
        badgeColor = Colors.orange;
        statusText = 'REVIEW';
        break;
      case TaskStatus.cancelled:
        badgeColor = Colors.red;
        statusText = 'CANCELLED';
        break;
      case TaskStatus.todo:
        badgeColor = Colors.grey;
        statusText = 'TODO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate.isAtSameMomentAs(today)) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    final tomorrow = today.add(const Duration(days: 1));
    if (taskDate.isAtSameMomentAs(tomorrow)) {
      return 'Tomorrow ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }

    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getDueDateColor() {
    if (task.dueDate == null) return Colors.grey;

    final now = DateTime.now();
    final difference = task.dueDate!.difference(now);

    if (difference.isNegative) {
      return Colors.red; // Overdue
    } else if (difference.inDays == 0) {
      return Colors.orange; // Due today
    } else if (difference.inDays <= 3) {
      return Colors.amber; // Due soon
    }

    return Colors.grey;
  }
}

// Extension to access context in static methods
extension Get on TaskItemWidget {
  static BuildContext? get context {
    return null; // This would need to be passed differently in a real implementation
  }
}
