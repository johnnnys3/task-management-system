/// Advanced task update screen for comprehensive task editing
/// Provides rich task editing interface with modern UI and validation
/// Includes form validation, error handling, and user feedback
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/models/task.dart';

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
    return Scaffold(
      // Modern app bar with loading indicator
      appBar: _buildAppBar(),
      // Main content with loading overlay
      body: Stack(
        children: [
          // Form content
          _buildForm(),
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      // Bottom action buttons
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  /// Builds modern app bar
  /// Includes title, actions, and loading indicator
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Update Task',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      actions: [
        // Save action
        if (!_isLoading)
          IconButton(
            onPressed: _updateTask,
            icon: const Icon(Icons.save),
            tooltip: 'Save Task',
          ),
      ],
    );
  }

  /// Builds main form content
  /// Creates scrollable form with validation
  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message display
            if (_errorMessage.isNotEmpty) _buildErrorMessage(),
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
        ),
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
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage,
              style: TextStyle(color: Colors.red.shade700),
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
      color: Colors.black.withValues(alpha: 0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating task...'),
              ],
            ),
          ),
        ),
      ),
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
      decoration: InputDecoration(
        labelText: 'Task Title',
        hintText: 'Enter task title',
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLength: 100,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return Text(
          '$currentLength/$maxLength',
          style: TextStyle(
            color: currentLength > (maxLength ?? 100) * 0.8 ? Colors.red : Colors.grey,
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
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Enter task description',
        prefixIcon: const Icon(Icons.description),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLength: 1000,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return Text(
          '$currentLength/$maxLength',
          style: TextStyle(
            color: currentLength > (maxLength ?? 1000) * 0.8 ? Colors.red : Colors.grey,
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _dueDate != null 
                    ? DateFormat('MMM dd, yyyy').format(_dueDate!)
                    : 'Select due date',
                style: TextStyle(
                  color: _dueDate != null ? Colors.black87 : Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds priority selector
  /// Creates dropdown with priority options
  Widget _buildPriorityField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskPriority>(
          value: _priority,
          isExpanded: true,
          items: _priorityOptions.map((priority) {
            return DropdownMenuItem<TaskPriority>(
              value: priority,
              child: Row(
                children: [
                  Icon(
                    _getPriorityIcon(priority),
                    color: _getPriorityColor(priority),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    priority.name.capitalize(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (TaskPriority? newValue) {
            if (newValue != null) {
              setState(() {
                _priority = newValue;
              });
            }
          },
        ),
      ),
    );
  }

  /// Builds status selector
  /// Creates dropdown with status options
  Widget _buildStatusField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TaskStatus>(
          value: _status,
          isExpanded: true,
          items: _statusOptions.map((status) {
            return DropdownMenuItem<TaskStatus>(
              value: status,
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(status),
                    color: _getStatusColor(status),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    status.name.capitalize(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (TaskStatus? newValue) {
            if (newValue != null) {
              setState(() {
                _status = newValue;
                // Auto-update completion status based on task status
                _isCompleted = (newValue == TaskStatus.completed);
              });
            }
          },
        ),
      ),
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
              color: _isCompleted ? Colors.green : Colors.grey.shade600,
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
              activeThumbColor: Theme.of(context).primaryColor,
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
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
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Save button
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateTask,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Update Task',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
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
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Gets priority icon
  /// Returns icon based on priority level
  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
      case TaskPriority.medium:
        return Icons.remove;
      case TaskPriority.high:
        return Icons.keyboard_arrow_up;
      case TaskPriority.urgent:
        return Icons.priority_high;
    }
  }

  /// Gets priority color
  /// Returns color based on priority level
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

  /// Gets status icon
  /// Returns icon based on task status
  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.pending;
      case TaskStatus.review:
        return Icons.visibility;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Gets status color
  /// Returns color based on task status
  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.todo:
        return Colors.grey;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.review:
        return Colors.orange;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
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
