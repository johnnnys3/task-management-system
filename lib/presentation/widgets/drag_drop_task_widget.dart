import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import '../../core/animations/app_animations.dart';

// ReorderCallback type alias for compatibility
typedef ReorderCallback = void Function(int oldIndex, int newIndex);

/// Draggable task widget
class DraggableTaskWidget extends ConsumerWidget {

  const DraggableTaskWidget({
    super.key,
    required this.task,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.isDraggable = true,
    this.showDragHandle = false,
    this.dragHandleColor,
  });
  final TaskEntity task;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isDraggable;
  final bool showDragHandle;
  final Color? dragHandleColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDraggable) {
      return child;
    }

    return LongPressDraggable<TaskEntity>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Opacity(
            opacity: 0.8,
            child: child,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: child,
      ),
      onDragStarted: () {
        HapticFeedback.lightImpact();
      },
      onDragCompleted: () {
        HapticFeedback.mediumImpact();
      },
      child: Stack(
        children: [
          child,
          if (showDragHandle)
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.drag_handle,
                  color: dragHandleColor ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Drop target for tasks
class TaskDropTarget extends ConsumerWidget {

  const TaskDropTarget({
    super.key,
    required this.child,
    this.acceptedStatuses = const [],
    this.onTaskDropped,
    this.showDropIndicator = true,
    this.dropIndicatorColor,
  });
  final Widget child;
  final List<TaskStatus> acceptedStatuses;
  final Function(TaskEntity task)? onTaskDropped;
  final bool showDropIndicator;
  final Color? dropIndicatorColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DragTarget<TaskEntity>(
      onWillAcceptWithDetails: (details) {
        // Access the task data from details
        return acceptedStatuses.isEmpty || acceptedStatuses.contains(details.data.status);
      },
      onAcceptWithDetails: (details) {
        HapticFeedback.selectionClick();
        // Access the task data from details
        onTaskDropped?.call(details.data);
      },
      onLeave: (_) {
        // Handle drag leave if needed
      },
      builder: (context, candidateData, rejectedData) {
        bool isHovering = candidateData.isNotEmpty;
        
        return Stack(
          children: [
            child,
            if (showDropIndicator && isHovering)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dropIndicatorColor ?? Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Drag and drop task list widget
class DragDropTaskList extends ConsumerStatefulWidget {

  const DragDropTaskList({
    super.key,
    required this.tasks,
    this.onTaskReordered,
    this.onTaskStatusChanged,
    this.itemBuilder,
    this.enableReordering = true,
    this.enableStatusDrop = true,
    this.padding,
  });
  final List<TaskEntity> tasks;
  final Function(TaskEntity task, int oldIndex, int newIndex)? onTaskReordered;
  final Function(TaskEntity task, TaskStatus newStatus)? onTaskStatusChanged;
  final Widget Function(BuildContext context, TaskEntity task, int index)? itemBuilder;
  final bool enableReordering;
  final bool enableStatusDrop;
  final EdgeInsets? padding;

  @override
  ConsumerState<DragDropTaskList> createState() => _DragDropTaskListState();
}

class _DragDropTaskListState extends ConsumerState<DragDropTaskList>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppAnimations.medium,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? const EdgeInsets.all(16),
      child: Column(
        children: [
          // Status drop targets
          if (widget.enableStatusDrop) ..._buildStatusDropTargets(),
          
          // Task list
          Expanded(
            child: ReorderableListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.tasks.length,
              onReorder: widget.enableReordering ? _handleReorder : (oldIndex, newIndex) {},
              itemBuilder: (context, index) {
                final task = widget.tasks[index];
                
                return Container(
                  key: ValueKey(task.id),
                  child: AppAnimations.slideAndFade(
                    begin: const Offset(0, 0.1),
                    duration: AppAnimations.medium,
                    curve: AppAnimations.defaultCurve,
                    child: widget.itemBuilder?.call(context, task, index) ?? 
                        _buildDefaultTaskItem(task, index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStatusDropTargets() {
    final statuses = TaskStatus.values;
    
    return [
      const SizedBox(height: 16),
      Row(
        children: statuses.map((status) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TaskDropTarget(
                acceptedStatuses: [status],
                onTaskDropped: (task) {
                  if (widget.onTaskStatusChanged != null) {
                    widget.onTaskStatusChanged!(task, status);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status.name,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),
    ];
  }

  Widget _buildDefaultTaskItem(TaskEntity task, int index) {
    return DraggableTaskWidget(
      key: ValueKey(task.id),
      task: task,
      showDragHandle: widget.enableReordering,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: _getPriorityColor(task.priority),
            child: Text(
              task.title.isNotEmpty ? task.title[0].toUpperCase() : 'T',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(task.title),
          subtitle: task.description.isNotEmpty 
              ? Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (task.dueDate != null)
                _buildDueDateChip(context, task.dueDate!),
              const SizedBox(width: 8),
              _buildStatusChip(task.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(TaskStatus status) {
    return Chip(
      label: Text(status.name),
      backgroundColor: _getStatusColor(status).withOpacity(0.1),
      labelStyle: TextStyle(
        color: _getStatusColor(status),
        fontSize: 12,
      ),
    );
  }

  Widget _buildDueDateChip(BuildContext context, DateTime dueDate) {
    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now);
    final isToday = _isSameDay(dueDate, now);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOverdue 
            ? Theme.of(context).colorScheme.error
            : isToday
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isToday ? 'Today' : _formatDate(dueDate),
        style: TextStyle(
          color: isOverdue || isToday ? Colors.white : null,
          fontSize: 10,
        ),
      ),
    );
  }

  void _handleReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final task = widget.tasks.removeAt(oldIndex);
    widget.tasks.insert(newIndex, task);
    
    if (widget.onTaskReordered != null) {
      widget.onTaskReordered!(task, oldIndex, newIndex);
    }
    
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.review:
        return Colors.purple;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.check_circle_outline;
      case TaskStatus.inProgress:
        return Icons.pending;
      case TaskStatus.review:
        return Icons.rate_review;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

/// Kanban board widget with drag and drop
class KanbanBoard extends ConsumerWidget {

  const KanbanBoard({
    super.key,
    required this.tasksByStatus,
    this.onTaskStatusChanged,
    this.onTaskReordered,
    this.itemBuilder,
  });
  final Map<TaskStatus, List<TaskEntity>> tasksByStatus;
  final Function(TaskEntity task, TaskStatus newStatus)? onTaskStatusChanged;
  final Function(TaskEntity task, int oldIndex, int newIndex, TaskStatus oldStatus)? onTaskReordered;
  final Widget Function(BuildContext context, TaskEntity task, TaskStatus status)? itemBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statuses = TaskStatus.values;
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: statuses.map((status) {
          final tasks = tasksByStatus[status] ?? [];
          
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Column header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        status.name,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Task list
                Expanded(
                  child: TaskDropTarget(
                    acceptedStatuses: [status],
                    onTaskDropped: (task) {
                      if (onTaskStatusChanged != null) {
                        onTaskStatusChanged!(task, status);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: tasks.isEmpty
                          ? Center(
                              child: Text(
                                'No tasks in ${status.name}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) {
                                final task = tasks[index];
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: DraggableTaskWidget(
                                    task: task,
                                    child: itemBuilder?.call(context, task, status) ?? 
                                        _buildKanbanTaskItem(context, task),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKanbanTaskItem(BuildContext context, TaskEntity task) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (task.dueDate != null)
                  Expanded(
                    child: _buildDueDateChip(task.dueDate!),
                  ),
                if (task.tags.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  _buildPriorityChip(task.priority),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateChip(DateTime dueDate) {
    final now = DateTime.now();
    final isOverdue = dueDate.isBefore(now);
    final isToday = _isSameDay(dueDate, now);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOverdue 
            ? Colors.red
            : isToday
                ? Colors.blue
                : Colors.grey,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isToday ? 'Today' : _formatDate(dueDate),
        style: TextStyle(
          color: isOverdue || isToday ? Colors.white : null,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(TaskPriority priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        priority.name,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.blue;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.review:
        return Colors.purple;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.check_circle_outline;
      case TaskStatus.inProgress:
        return Icons.pending;
      case TaskStatus.review:
        return Icons.rate_review;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Colors.green;
      case TaskPriority.medium:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}';
  }
}

/// Drag and drop utilities
class DragDropUtils {
  DragDropUtils._();

  /// Check if drag and drop is supported on this platform
  static bool get isSupported {
    return true; // Flutter supports drag and drop on all platforms
  }

  /// Provide haptic feedback for drag operations
  static void provideDragFeedback(DragFeedbackType type) {
    switch (type) {
      case DragFeedbackType.start:
        HapticFeedback.lightImpact();
        break;
      case DragFeedbackType.move:
        HapticFeedback.selectionClick();
        break;
      case DragFeedbackType.drop:
        HapticFeedback.mediumImpact();
        break;
      case DragFeedbackType.cancel:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// Get drag feedback animation duration
  static Duration getFeedbackDuration(DragFeedbackType type) {
    switch (type) {
      case DragFeedbackType.start:
        return AppAnimations.fast;
      case DragFeedbackType.move:
        return AppAnimations.fast;
      case DragFeedbackType.drop:
        return AppAnimations.medium;
      case DragFeedbackType.cancel:
        return AppAnimations.slow;
    }
  }
}

/// Drag feedback types
enum DragFeedbackType {
  start,
  move,
  drop,
  cancel,
}