/// Advanced task update screen for comprehensive task editing
/// Provides rich task editing interface with modern UI and validation
/// Includes form validation, error handling, and user feedback
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/widgets/entity_form_scaffold.dart';
import 'package:task_management/widgets/pill_button.dart';
import 'package:task_management/widgets/status_chip.dart';

class UpdateTaskScreen extends StatefulWidget {
  /// Task to be updated
  final Task task;
  /// Admin status for permission-based actions
  final bool isAdmin;

  const UpdateTaskScreen({
    Key? key,
    required this.task,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  _UpdateTaskScreenState createState() => _UpdateTaskScreenState();
}

class _UpdateTaskScreenState extends State<UpdateTaskScreen> {
  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // State variables
  DateTime? _dueDate;
  bool _isCompleted = false;
  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.todo;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Focus nodes for form navigation
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  
  // Priority options
  final List<TaskPriority> _priorityOptions = TaskPriority.values;
  final List<TaskStatus> _statusOptions = TaskStatus.values;

  @override
  void initState() {
    super.initState();
    // Initialize form with existing task details
    _initializeForm();
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  /// Initializes form with existing task data
  /// Sets up controllers and state variables
  void _initializeForm() {
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _dueDate = widget.task.dueDate;
    _isCompleted = widget.task.isCompleted;
    _priority = widget.task.priority;
    _status = widget.task.status;
  }

  /// Updates task with validation and error handling
  /// Performs comprehensive validation before database update
  Future<void> _updateTask() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Extract updated task details from controllers
      final String updatedTitle = _titleController.text.trim();
      final String updatedDescription = _descriptionController.text.trim();

      // Create updated task object using copyWith
      final Task updatedTask = widget.task.copyWith(
        title: updatedTitle,
        description: updatedDescription,
        dueDate: _dueDate,
        isCompleted: _isCompleted,
        priority: _priority,
        status: _status,
        updatedAt: DateTime.now(),
      );

      // Update task via TaskStore
      await context.read<TaskStore>().update(updatedTask);

      // Show success message and navigate back
      if (mounted) {
        _showSuccessSnackBar('Task updated successfully');
        Navigator.pop(context, updatedTask);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error updating task: $e';
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to update task. Please try again.');
      }
    }
  }

  /// Validates task title
  /// Ensures title is not empty and meets requirements
  String? _validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Task title is required';
    }
    if (value.trim().length < 3) {
      return 'Task title must be at least 3 characters';
    }
    if (value.trim().length > 100) {
      return 'Task title cannot exceed 100 characters';
    }
    return null;
  }

  /// Validates task description
  /// Ensures description meets requirements
  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Task description is required';
    }
    if (value.trim().length > 1000) {
      return 'Description cannot exceed 1000 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: 'Update Task',
      formKey: _formKey,
      isLoading: _isLoading,
      loadingMessage: 'Updating task...',
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = ''),
      onSave: _updateTask,
      saveTooltip: 'Save Task',
      bottomNavigationBar: _buildBottomActions(),
      children: [
        const SizedBox(height: 16),
        // Task title field
        _buildTitleField(),
        const SizedBox(height: 24),
        // Task description field
        _buildDescriptionField(),
        const SizedBox(height: 24),
        // Due date picker
        _buildDueDateField(),
        const SizedBox(height: 24),
        // Priority selector
        _buildPriorityField(),
        const SizedBox(height: 24),
        // Status selector
        _buildStatusField(),
        const SizedBox(height: 24),
        // Completion status toggle
        _buildCompletionToggle(),
        const SizedBox(height: 32),
        // Task information
        _buildTaskInformation(),
        const SizedBox(height: 100), // Space for bottom navigation
      ],
    );
  }

  /// Builds task title field
  /// Creates validated text field with modern styling
  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      validator: _validateTitle,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) {
        FocusScope.of(context).requestFocus(_descriptionFocusNode);
      },
      decoration: const InputDecoration(
        labelText: 'Task Title',
        hintText: 'Enter task title',
        prefixIcon: Icon(Icons.title),
      ),
      maxLength: 100,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return Text(
          '$currentLength/$maxLength',
          style: TextStyle(
            color: currentLength > (maxLength ?? 100) * 0.8 ? AppColors.rust : AppColors.ink3,
          ),
        );
      },
    );
  }

  /// Builds task description field
  /// Creates validated multiline text field
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      validator: _validateDescription,
      maxLines: 5,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Enter task description',
        prefixIcon: Icon(Icons.description),
      ),
      maxLength: 1000,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return Text(
          '$currentLength/$maxLength',
          style: TextStyle(
            color: currentLength > (maxLength ?? 1000) * 0.8 ? AppColors.rust : AppColors.ink3,
          ),
        );
      },
    );
  }

  /// Builds due date field
  /// Creates date picker with modern styling
  Widget _buildDueDateField() {
    return InkWell(
      onTap: _selectDueDate,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.ink.withOpacity(0.16)),
          borderRadius: BorderRadius.circular(16),
          color: AppColors.paper,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              color: AppColors.terra,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dueDate != null
                    ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                    : 'Select due date',
                style: TextStyle(
                  color: _dueDate != null ? AppColors.ink : AppColors.ink3,
                  fontSize: 16,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.ink3,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds priority selector
  /// Creates dropdown with priority options
  Widget _buildPriorityField() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _priorityOptions.map((priority) {
        final selected = _priority == priority;
        final colors = AppColors.priorityColors(priority);
        return ChoiceChip(
          label: Text(priority.name.capitalize()),
          selected: selected,
          onSelected: (_) => setState(() => _priority = priority),
          backgroundColor: Colors.transparent,
          selectedColor: colors.bg,
          labelStyle: TextStyle(
            color: selected ? colors.fg : AppColors.ink2,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: selected ? colors.bg : AppColors.sand),
          shape: const StadiumBorder(),
        );
      }).toList(),
    );
  }

  /// Builds status selector
  /// Creates dropdown with status options
  Widget _buildStatusField() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _statusOptions.map((status) {
        final selected = _status == status;
        final color = AppColors.statusColor(status);
        return ChoiceChip(
          label: Text(statusLabel(status)),
          selected: selected,
          onSelected: (_) => setState(() {
            _status = status;
            // Auto-update completion status based on task status
            _isCompleted = (status == TaskStatus.completed);
          }),
          backgroundColor: Colors.transparent,
          selectedColor: color,
          labelStyle: TextStyle(
            color: selected ? AppColors.paper : AppColors.ink2,
            fontWeight: FontWeight.w600,
          ),
          side: BorderSide(color: selected ? color : AppColors.sand),
          shape: const StadiumBorder(),
        );
      }).toList(),
    );
  }

  /// Builds completion toggle
  /// Creates switch for task completion
  Widget _buildCompletionToggle() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _isCompleted ? AppColors.sage : AppColors.ink3,
            ),
            const SizedBox(width: 12),
            const Text(
              'Mark as completed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Switch(
              value: _isCompleted,
              onChanged: (bool value) {
                setState(() {
                  _isCompleted = value;
                  // Update status based on completion
                  if (value) {
                    _status = TaskStatus.completed;
                  } else {
                    _status = TaskStatus.todo;
                  }
                });
              },
              activeThumbColor: AppColors.terra,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds task information section
  /// Shows current task details
  Widget _buildTaskInformation() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.terra),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Created', _formatDate(widget.task.createdAt)),
            if (widget.task.updatedAt != null)
              _buildInfoRow('Last Updated', _formatDate(widget.task.updatedAt!)),
            if (widget.task.associatedProject != null)
              _buildInfoRow('Project', widget.task.associatedProject!.name),
            if (widget.task.assignedMembers.isNotEmpty)
              _buildInfoRow('Assigned', '${widget.task.assignedMembers.length} member(s)'),
          ],
        ),
      ),
    );
  }

  /// Builds information row
  /// Creates styled row with label and value
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.ink3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds bottom action buttons
  /// Creates save and cancel buttons
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: PillButton(
              label: 'Cancel',
              outlined: true,
              onPressed: _isLoading ? null : () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          // Save button
          Expanded(
            child: PillButton(
              label: _isLoading ? 'Saving...' : 'Update Task',
              onPressed: _isLoading ? null : _updateTask,
            ),
          ),
        ],
      ),
    );
  }

  /// Shows due date picker
  /// Opens date selection dialog
  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  /// Shows success message
  /// Displays temporary success notification
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.paper),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.paper),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.sage,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.paper,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows error message
  /// Displays temporary error notification
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: AppColors.paper),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: AppColors.paper),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.rust,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.paper,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Formats date for display
  /// Returns formatted date string
  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('MMM dd, yyyy').format(date);
  }
}

/// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
