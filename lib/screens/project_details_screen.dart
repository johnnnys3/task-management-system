/// Project details screen for displaying comprehensive project information
/// Provides project management features including editing, task viewing, and status updates
/// Includes real-time data fetching and error handling
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/models/project.dart';
import 'package:intl/intl.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/screens/task_details_screen.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/avatar_badge.dart';
import 'package:task_management/widgets/priority_badge.dart';
import 'package:task_management/widgets/progress_bar.dart';
import 'package:task_management/widgets/status_chip.dart';

/// Local color mapping for [ProjectStatus], not reused widely enough to
/// warrant a home in AppColors.
Color _projectStatusColor(ProjectStatus status) {
  switch (status) {
    case ProjectStatus.planning:
      return AppColors.ink3;
    case ProjectStatus.inProgress:
      return AppColors.terra;
    case ProjectStatus.onHold:
      return const Color(0xFFC08A3E); // amber
    case ProjectStatus.completed:
      return AppColors.sage;
    case ProjectStatus.cancelled:
      return AppColors.ink3;
  }
}

String _projectStatusLabel(ProjectStatus status) {
  switch (status) {
    case ProjectStatus.planning:
      return 'Planning';
    case ProjectStatus.inProgress:
      return 'Active';
    case ProjectStatus.onHold:
      return 'On Hold';
    case ProjectStatus.completed:
      return 'Completed';
    case ProjectStatus.cancelled:
      return 'Cancelled';
  }
}

class ProjectDetailsScreen extends StatefulWidget {
  /// Project to display details for
  final Project project;

  const ProjectDetailsScreen({super.key, required this.project});

  @override
  _ProjectDetailsScreenState createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  // State variables
  late Project project; // Current project data
  String projectDescription = ''; // Fetched project description
  List<Task> relatedTasks = []; // Related tasks for the project
  List<String> relatedTaskTitles = []; // Task titles for display
  bool _isLoading = true; // Loading state for data fetching
  String _errorMessage = ''; // Error message for user feedback
  bool _isEditing = false; // Edit mode state
  
  // Controllers for editing
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _dueDateController;

  late final ProjectStore _projectStore;
  late final TaskStore _taskStore;

  @override
  void initState() {
    super.initState();
    _projectStore = context.read<ProjectStore>();
    _taskStore = context.read<TaskStore>();
    // Initialize project data and controllers
    project = widget.project;
    _initializeControllers();
    // Fetch additional project details and related tasks
    _fetchProjectDetails();
    _fetchRelatedTasks();
  }

  /// Initialize text controllers with current project data
  /// Sets up controllers for editing functionality
  void _initializeControllers() {
    _nameController = TextEditingController(text: project.name);
    _descriptionController = TextEditingController(text: projectDescription);
    _dueDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(project.dueDate)
    );
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _nameController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  /// Fetches detailed project information via ProjectStore
  /// Updates project description and handles errors gracefully
  Future<void> _fetchProjectDetails() async {
    try {
      // ponytail: ProjectStore has no get-by-id; fetch and find locally. Add
      // a dedicated lookup if this ever needs to scale past a small project list.
      final projects = await _projectStore.fetch();
      final matches = projects.where((p) => p.id == project.id);
      final fetched = matches.isEmpty ? null : matches.first;

      if (fetched != null && mounted) {
        setState(() {
          projectDescription = fetched.description;
          project = fetched;
          // Update controllers with fresh data
          _descriptionController.text = projectDescription;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch project details: ${error.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Fetches related tasks for the project
  /// Updates task list and handles errors gracefully
  Future<void> _fetchRelatedTasks() async {
    try {
      // Fetch tasks from local database
      final fetchedTasks = await _taskStore.fetch();
      
      // Filter tasks related to this project
      final projectTasks = fetchedTasks.where((task) => 
        task.associatedProject?.id == project.id
      ).toList();
      
      if (mounted) {
        setState(() {
          relatedTasks = projectTasks;
          relatedTaskTitles = projectTasks.map((task) => task.title).toList();
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch related tasks: ${error.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Builds the main project details interface
  /// Creates responsive layout with editing capabilities
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Modern app bar with editing controls
      appBar: _buildAppBar(context),
      // Main content with loading/error states
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
      // Floating action button for quick actions
      floatingActionButton: _isEditing ? null : _buildFloatingActions(),
    );
  }

  /// Builds app bar with edit/save functionality
  /// Includes title, actions, and edit mode controls
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        _isEditing ? 'Edit Project' : 'Project Details',
        style: AppTheme.display(size: 20, color: AppColors.shell),
      ),
      backgroundColor: AppColors.terra,
      elevation: 0,
      // Edit/save actions
      actions: [
        if (_isEditing)
          // Save button in edit mode
          IconButton(
            icon: Icon(Icons.save, color: AppColors.shell),
            tooltip: 'Save Changes',
            onPressed: _saveProjectChanges,
          )
        else
          // Edit button in view mode
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.shell),
            tooltip: 'Edit Project',
            onPressed: _toggleEditMode,
          ),
        // More options menu
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: AppColors.shell),
          tooltip: 'More Options',
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Refresh'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: AppColors.rust),
                  const SizedBox(width: 8),
                  Text('Delete Project', style: TextStyle(color: AppColors.rust)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds loading widget with modern styling
  /// Shows centered loading indicator with message
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.terra),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading project details...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds main content area
  /// Shows project details or error state
  Widget _buildContent() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }
    
    return RefreshIndicator(
      onRefresh: _refreshProjectData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Project information section
            _buildProjectInfoCard(),
            const SizedBox(height: 16),
            // Description section
            _buildDescriptionCard(),
            const SizedBox(height: 16),
            // Related tasks section
            _buildRelatedTasksCard(),
            const SizedBox(height: 16),
            // Project statistics
            _buildStatisticsCard(context),
          ],
        ),
      ),
    );
  }

  /// Builds project information card
  /// Displays project name, due date, and status
  Widget _buildProjectInfoCard() {
    final statusColor = _projectStatusColor(project.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project name
          if (_isEditing)
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Project Name',
              ),
              style: const TextStyle(fontSize: 18),
            )
          else
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.avatarColor(project.id),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    project.name,
                    style: AppTheme.display(size: 24, color: AppColors.ink),
                  ),
                ),
                // Status pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    _projectStatusLabel(project.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Due date
          if (_isEditing)
            TextFormField(
              controller: _dueDateController,
              decoration: const InputDecoration(
                labelText: 'Due Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: _selectDueDate,
              readOnly: true,
            )
          else
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: AppColors.ink2,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Due Date: ${_formatDate(project.dueDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.ink2,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Status
          Row(
            children: [
              Icon(
                project.isCompleted ? Icons.check_circle : Icons.pending,
                color: project.isCompleted ? AppColors.sage : const Color(0xFFC08A3E),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                project.isCompleted ? 'Completed' : 'In Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: project.isCompleted ? AppColors.sage : const Color(0xFFC08A3E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds description card with editing support
  /// Shows project description with edit capability
  Widget _buildDescriptionCard() {
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
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isEditing)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter project description',
                ),
                maxLines: 4,
                style: const TextStyle(fontSize: 16),
              )
            else
              Text(
                projectDescription.isNotEmpty 
                    ? projectDescription 
                    : 'No description available',
                style: TextStyle(
                  fontSize: 16,
                  color: projectDescription.isNotEmpty
                      ? AppColors.ink
                      : AppColors.ink3,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds related tasks card
  /// Displays list of tasks related to the project
  Widget _buildRelatedTasksCard() {
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
            Row(
              children: [
                Icon(
                  Icons.task,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Related Tasks (${relatedTasks.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (relatedTasks.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: relatedTasks.length,
                  itemBuilder: (context, index) {
                    final task = relatedTasks[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: task.isCompleted ? AppColors.sage : AppColors.statusReview,
                        child: Icon(
                          task.isCompleted ? Icons.check : Icons.pending,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      title: Text(
                        task.title,
                        style: const TextStyle(fontSize: 16),
                      ),
                      subtitle: task.dueDate != null
                          ? Text(
                              'Due: ${_formatDate(task.dueDate!)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: task.dueDate!.isBefore(DateTime.now())
                                    ? AppColors.rust
                                    : AppColors.ink3,
                              ),
                            )
                          : null,
                      onTap: () => _navigateToTask(task),
                    );
                  },
                ),
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt,
                      size: 48,
                      color: AppColors.ink3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No related tasks',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds project statistics card
  /// Shows project metrics and progress
  Widget _buildStatisticsCard(BuildContext context) {
    final completedTasks = relatedTasks.where((task) => task.isCompleted).length;
    final totalTasks = relatedTasks.length;
    final progress = totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0;
    
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
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Project Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.ink3,
                      ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: progress >= 75
                            ? AppColors.sage
                            : progress >= 50
                                ? AppColors.statusReview
                                : AppColors.rust,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: AppColors.sand,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 75
                        ? AppColors.sage
                        : progress >= 50
                            ? AppColors.statusReview
                            : AppColors.rust,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Task statistics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Total Tasks', totalTasks.toString(), Icons.task),
                _buildStatItem('Completed', completedTasks.toString(), Icons.check_circle),
                _buildStatItem('Remaining', (totalTasks - completedTasks).toString(), Icons.pending),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds individual statistic item
  /// Creates styled stat display with icon and value
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.ink3,
          ),
        ),
      ],
    );
  }

  /// Builds error state widget
  /// Shows error message with retry option
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.rust,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshProjectData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Handles menu actions from app bar
  /// Processes refresh and delete operations
  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _refreshProjectData();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
    }
  }

  /// Refreshes project data from database
  /// Reloads project details and related tasks
  Future<void> _refreshProjectData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    await _fetchProjectDetails();
    await _fetchRelatedTasks();
  }

  /// Toggles between view and edit modes
  /// Switches UI state and updates controllers
  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (_isEditing) {
        _initializeControllers();
      }
    });
  }

  /// Shows date picker for due date selection
  /// Allows user to select project due date
  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: project.dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        _dueDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  /// Saves project changes to database
  /// Updates project with new values and handles errors
  Future<void> _saveProjectChanges() async {
    try {
      // Validate input
      if (_nameController.text.trim().isEmpty) {
        _showErrorSnackBar('Project name is required');
        return;
      }
      
      setState(() {
        _isLoading = true;
      });

      // Update project via ProjectStore
      final updatedProject = project.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: DateFormat('yyyy-MM-dd').parse(_dueDateController.text),
        updatedAt: DateTime.now(),
      );
      await _projectStore.update(updatedProject);

      // Update local project object
      setState(() {
        project = updatedProject;
        projectDescription = updatedProject.description;
        _isEditing = false;
        _isLoading = false;
      });
      
      _showSuccessSnackBar('Project updated successfully');
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to save project: ${error.toString()}');
    }
  }

  /// Shows delete confirmation dialog
  /// Asks user to confirm project deletion
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteProject();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rust,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Deletes project from database
  /// Removes project and navigates back
  Future<void> _deleteProject() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Delete project via ProjectStore
      await _projectStore.delete(project.id);

      _showSuccessSnackBar('Project deleted successfully');
      
      // Navigate back to project list
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to delete project: ${error.toString()}');
    }
  }

  /// Navigates to task details screen
  /// Opens task details for selected task
  void _navigateToTask(Task task) {
    // Import and navigate to task details screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(task: task),
      ),
    );
  }

  /// Shows success message in snackbar
  /// Provides positive feedback for successful operations
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
        backgroundColor: AppColors.sage,
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

  /// Shows error message in snackbar
  /// Provides error feedback for failed operations
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
        backgroundColor: AppColors.rust,
        duration: const Duration(seconds: 4),
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

  /// Formats date for display
  /// Returns formatted date string
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Builds floating action buttons
  /// Provides edit and delete functionality
  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: "edit",
          onPressed: () {
            setState(() {
              _isEditing = true;
            });
          },
          backgroundColor: AppColors.terra,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "delete",
          onPressed: () => _showDeleteConfirmation(),
          backgroundColor: AppColors.rust,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
      ],
    );
  }
}
