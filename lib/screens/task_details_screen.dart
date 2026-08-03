/// Advanced task details screen for comprehensive task information display
/// Provides rich task information with modern UI and interactive features
/// Includes status management, attachments, and action buttons
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
import 'package:task_management/widgets/status_chip.dart';

class TaskDetailsScreen extends StatefulWidget {
  /// The task to display details for
  final Task task;

  const TaskDetailsScreen({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  _TaskDetailsScreenState createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  // State variables for dynamic updates
  bool _isLoading = false;
  String _errorMessage = '';

  late final TaskStore _taskStore;

  @override
  void initState() {
    super.initState();
    _taskStore = context.read<TaskStore>();
  }

  /// Builds comprehensive task details interface
  /// Creates modern layout with cards and interactive elements
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Modern app bar with actions
      appBar: _buildAppBar(context),
      // Main content with loading overlay
      body: Stack(
        children: [
          // Scrollable content
          _buildContent(),
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      // Floating action buttons for quick actions
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  /// Builds modern app bar
  /// Includes title, status indicator, and action buttons
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isOverdue = !widget.task.isCompleted && 
                     widget.task.hasDueDate && 
                     widget.task.dueDate != null && widget.task.dueDate!.isBefore(DateTime.now());
    
    return AppBar(
      title: const Text('Task Details'),
      actions: [
        // Status indicator
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.task.isCompleted
                ? AppColors.statusDone
                : isOverdue
                    ? AppColors.rust
                    : AppColors.statusReview,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.task.isCompleted
                ? 'Completed'
                : isOverdue
                    ? 'Overdue'
                    : 'Pending',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit Task'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.rust),
                  const SizedBox(width: 8),
                  Text('Delete Task', style: TextStyle(color: AppColors.rust)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds main content area
  /// Creates scrollable layout with task information cards
  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Error message display
          if (_errorMessage.isNotEmpty) _buildErrorMessage(),
          // Task information card
          _buildTaskInformationCard(),
          const SizedBox(height: 16),
          // Task details card
          _buildTaskDetailsCard(),
          const SizedBox(height: 16),
          // Assignment card
          _buildAssignmentCard(),
          const SizedBox(height: 16),
          // Project card
          if (widget.task.associatedProject != null) _buildProjectCard(),
          const SizedBox(height: 16),
          // Attachments card
          _buildAttachmentsCard(),
          const SizedBox(height: 24),
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// Builds error message widget
  /// Shows error with dismiss option
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.blush,
        border: Border.all(color: AppColors.rust.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.rust),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: AppColors.rust),
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
                Text('Processing...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds task information card
  /// Displays title, status, and basic information
  Widget _buildTaskInformationCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.task.title,
                  style: AppTheme.display(size: 22, weight: FontWeight.w700, color: AppColors.ink),
                ),
              ),
              const SizedBox(width: 8),
              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: widget.task.isCompleted
                      ? AppColors.statusDone
                      : (_isOverdue() ? AppColors.rust : AppColors.statusReview),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  widget.task.isCompleted
                      ? 'Completed'
                      : (_isOverdue() ? 'Overdue' : 'Pending'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Description
          if (widget.task.description.isNotEmpty) ...[
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.ink2),
            ),
            const SizedBox(height: 8),
            Text(
              widget.task.description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.ink2,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 16),
          // Status / priority chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(status: widget.task.status),
              PriorityBadge(priority: widget.task.priority),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds task details card
  /// Shows due date, priority, and other details
  Widget _buildTaskDetailsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: AppTheme.display(size: 16, weight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          // Due date
          _buildDetailRow(
            Icons.calendar_today,
            'Due Date',
            widget.task.dueDate != null ? _formatDate(widget.task.dueDate!) : 'No due date',
            isOverdue: _isOverdue(),
          ),
          const SizedBox(height: 12),
          // Created date
          _buildDetailRow(
            Icons.add_circle,
            'Created',
            widget.task.createdAt != null ? _formatDate(widget.task.createdAt!) : 'Unknown',
          ),
          const SizedBox(height: 12),
          // Priority (if available)
          if (widget.task.priority.name.isNotEmpty)
            _buildDetailRow(
              Icons.flag,
              'Priority',
              widget.task.priority.name,
            ),
        ],
      ),
    );
  }

  /// Builds assignment card
  /// Shows assigned team members
  Widget _buildAssignmentCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigned To',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.task.assignedMembers.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.task.assignedMembers.map((member) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        member.isNotEmpty ? member[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    label: Text(member),
                    backgroundColor: AppColors.sand,
                  );
                }).toList(),
              )
            else
              Text(
                'No members assigned',
                style: TextStyle(
                  color: AppColors.ink2,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds project card
  /// Shows associated project information
  Widget _buildProjectCard() {
    final project = widget.task.associatedProject!;
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Associated Project',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Project name
            Row(
              children: [
                Icon(
                  Icons.folder,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            // Project description
            if (project.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                project.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.ink2,
                ),
              ),
            ],
            // Project due date
            ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: AppColors.ink2,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Project due: ${_formatDate(project.dueDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          ],
          ],
        ),
      ),
    );
  }

  /// Builds attachments card
  /// Shows task attachments if any
  Widget _buildAttachmentsCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attachments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.task.attachments.isNotEmpty)
              Column(
                children: widget.task.attachments.map((attachment) {
                  return ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(attachment),
                    subtitle: const Text('Tap to view'),
                    onTap: () {
                      // TODO: Implement attachment viewing
                      _showSnackBar('Attachment viewing not implemented yet');
                    },
                  );
                }).toList(),
              )
            else
              Text(
                'No attachments',
                style: TextStyle(
                  color: AppColors.ink2,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds action buttons
  /// Shows primary task actions
  Widget _buildActionButtons() {
    return Row(
      children: [
        // Complete/Incomplete button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleTaskCompletion,
            icon: Icon(
              widget.task.isCompleted ? Icons.undo : Icons.check,
            ),
            label: Text(
              widget.task.isCompleted ? 'Mark Incomplete' : 'Mark Complete',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.task.isCompleted
                  ? AppColors.statusReview
                  : AppColors.sage,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Edit button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _editTask,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Task'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds floating action buttons
  /// Shows quick action buttons
  Widget _buildFloatingActionButtons() {
    return FloatingActionButton.extended(
      onPressed: _toggleTaskCompletion,
      icon: Icon(
        widget.task.isCompleted ? Icons.undo : Icons.check,
      ),
      label: Text(
        widget.task.isCompleted ? 'Incomplete' : 'Complete',
      ),
      backgroundColor: widget.task.isCompleted
          ? AppColors.statusReview
          : AppColors.sage,
    );
  }

  /// Builds detail row with icon, label, and value
  /// Creates consistent row layout for task details
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isOverdue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: isOverdue ? AppColors.rust : AppColors.ink2,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.ink2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    color: isOverdue ? AppColors.rust : AppColors.ink,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Checks if task is overdue
  /// Returns true if task is past due date and not completed
  bool _isOverdue() {
    return !widget.task.isCompleted && 
           widget.task.hasDueDate && 
           widget.task.dueDate != null && widget.task.dueDate!.isBefore(DateTime.now());
  }

  /// Formats date for display
  /// Returns formatted date string
  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Handles menu actions from app bar
  /// Processes edit and delete actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editTask();
        break;
      case 'delete':
        _deleteTask();
        break;
    }
  }

  /// Toggles task completion status
  /// Updates task completion via TaskStore
  Future<void> _toggleTaskCompletion() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Update task completion
      final updatedTask = Task(
        id: widget.task.id,
        title: widget.task.title,
        description: widget.task.description,
        dueDate: widget.task.dueDate,
        assignedMembers: widget.task.assignedMembers,
        associatedProject: widget.task.associatedProject,
        attachments: widget.task.attachments,
        isCompleted: !widget.task.isCompleted,
        priority: widget.task.priority,
        createdAt: widget.task.createdAt,
      );

      // Update via TaskStore
      await _taskStore.update(updatedTask);

      setState(() {
        _isLoading = false;
      });

      // Show success message
      _showSnackBar(
        widget.task.isCompleted ? 'Task marked as incomplete' : 'Task completed!',
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to update task: ${e.toString()}';
      });
    }
  }

  /// Edits task
  /// Navigates to task editing screen
  void _editTask() {
    // TODO: Navigate to task editing screen
    _showSnackBar('Task editing not implemented yet');
  }

  /// Deletes task
  /// Removes task via TaskStore with confirmation
  Future<void> _deleteTask() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${widget.task.title}"?'),
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

    if (confirmed == true) {
      try {
        setState(() {
          _isLoading = true;
          _errorMessage = '';
        });

        // Delete via TaskStore
        await _taskStore.delete(widget.task.id);

        setState(() {
          _isLoading = false;
        });

        // Show success message and navigate back
        _showSnackBar('Task deleted successfully');
        Navigator.pop(context);
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to delete task: ${e.toString()}';
        });
      }
    }
  }

  /// Shows snackbar message
  /// Displays temporary message to user
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
