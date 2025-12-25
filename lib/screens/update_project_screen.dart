/// Advanced project update screen for comprehensive project editing
/// Provides rich project editing interface with modern UI and validation
/// Includes form validation, error handling, and user feedback
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:task_management/data/database_helper(project).dart';
import 'package:task_management/models/project.dart';

class UpdateProjectScreen extends StatefulWidget {
  /// Project to be updated
  final Project project;
  /// Current user ID for permission checks
  final String? userId;
  /// Admin status for permission-based actions
  final bool isAdmin;

  const UpdateProjectScreen({
    Key? key,
    required this.project,
    this.userId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  _UpdateProjectScreenState createState() => _UpdateProjectScreenState();
}

class _UpdateProjectScreenState extends State<UpdateProjectScreen> {
  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // State variables
  late DateTime _dueDate;
  bool _isCompleted = false;
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Focus nodes for form navigation
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Initialize form with existing project details
    _initializeForm();
  }

  @override
  void dispose() {
    // Clean up controllers and focus nodes
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  /// Initializes form with existing project data
  /// Sets up controllers and state variables
  void _initializeForm() {
    _nameController.text = widget.project.name;
    _descriptionController.text = widget.project.description;
    _dueDate = widget.project.dueDate;
    _isCompleted = widget.project.isCompleted;
  }

  /// Updates project with validation and error handling
  /// Performs comprehensive validation before database update
  Future<void> _updateProject() async {
    // Validate form before proceeding
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Extract updated project details from controllers
      final String updatedName = _nameController.text.trim();
      final String updatedDescription = _descriptionController.text.trim();

      // Create updated project object
      final Project updatedProject = Project(
        name: updatedName,
        description: updatedDescription,
        dueDate: _dueDate,
        tasks: widget.project.tasks,
        id: widget.project.id,
        isCompleted: _isCompleted,
        updatedAt: DateTime.now(),
      );

      // Update project in database
      await ProjectDatabase().updateProject(updatedProject);

      // Show success message and navigate back
      _showSuccessSnackBar('Project updated successfully');
      Navigator.pop(context, updatedProject);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating project: $e';
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to update project. Please try again.');
    }
  }

  /// Validates project name
  /// Ensures name is not empty and meets requirements
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project name is required';
    }
    if (value.trim().length < 3) {
      return 'Project name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Project name cannot exceed 50 characters';
    }
    return null;
  }

  /// Validates project description
  /// Ensures description meets requirements
  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project description is required';
    }
    if (value.trim().length > 500) {
      return 'Description cannot exceed 500 characters';
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
        'Update Project',
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
            onPressed: _updateProject,
            icon: const Icon(Icons.save),
            tooltip: 'Save Project',
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
            // Project name field
            _buildNameField(),
            const SizedBox(height: 24),
            // Project description field
            _buildDescriptionField(),
            const SizedBox(height: 24),
            // Due date picker
            _buildDueDateField(),
            const SizedBox(height: 24),
            // Completion status toggle
            _buildCompletionToggle(),
            const SizedBox(height: 32),
            // Project statistics
            _buildProjectStatistics(),
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
                Text('Updating project...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds project name field
  /// Creates validated text field with modern styling
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      focusNode: _nameFocusNode,
      validator: _validateName,
      decoration: InputDecoration(
        labelText: 'Project Name',
        hintText: 'Enter project name',
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
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) {
        FocusScope.of(context).requestFocus(_descriptionFocusNode);
      },
      maxLength: 50,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return Text(
          '$currentLength/$maxLength',
          style: TextStyle(
            color: currentLength > maxLength * 0.8 ? Colors.red : Colors.grey,
          ),
        );
      },
    );
  }

  /// Builds project description field
  /// Creates validated multiline text field
  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      focusNode: _descriptionFocusNode,
      validator: _validateDescription,
      maxLines: 5,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Enter project description',
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
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      textInputAction: TextInputAction.done,
      maxLength: 500,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
        return Text(
          '$currentLength/$maxLength',
          style: TextStyle(
            color: currentLength > maxLength * 0.8 ? Colors.red : Colors.grey,
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
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(_dueDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds completion toggle
  /// Creates modern switch with label
  Widget _buildCompletionToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Row(
        children: [
          Icon(
            _isCompleted ? Icons.check_circle : Icons.circle_outlined,
            color: _isCompleted ? Colors.green : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isCompleted ? 'Completed' : 'In Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isCompleted ? Colors.green : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isCompleted,
            onChanged: (value) {
              setState(() {
                _isCompleted = value;
              });
            },
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  /// Builds project statistics
  /// Shows project information cards
  Widget _buildProjectStatistics() {
    final taskCount = widget.project.tasks?.length ?? 0;
    final isOverdue = !widget.project.isCompleted && 
                     widget.project.dueDate.isBefore(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Project Information',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Tasks count card
            _buildStatCard(
              'Tasks',
              taskCount.toString(),
              Icons.task,
              Colors.blue,
            ),
            const SizedBox(width: 12),
            // Status card
            _buildStatCard(
              'Status',
              widget.project.isCompleted ? 'Completed' : 'Active',
              widget.project.isCompleted ? Icons.check_circle : Icons.pending,
              widget.project.isCompleted ? Colors.green : Colors.orange,
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Due date status
        if (isOverdue)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This project is overdue!',
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Builds individual statistic card
  /// Creates styled card for project information
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
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

  /// Builds bottom action buttons
  /// Creates save and cancel buttons
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              ),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          // Save button
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateProject,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
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
                  : const Text('Update Project'),
            ),
          ),
        ],
      ),
    );
  }

  /// Selects due date from date picker
  /// Updates due date state when date is selected
  Future<void> _selectDueDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (pickedDate != null && pickedDate != _dueDate) {
      setState(() {
        _dueDate = pickedDate;
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
}
