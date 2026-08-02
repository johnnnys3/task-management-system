/// Project details screen for displaying comprehensive project information
/// Provides project management features including editing, task viewing, and status updates
/// Includes real-time data fetching and error handling
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/models/project.dart';
import 'package:intl/intl.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/screens/task_details_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _projectStore = context.read<ProjectStore>();
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
      final fetchedTasks = await TaskDatabase().fetchTasks();
      
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      // Edit/save actions
      actions: [
        if (_isEditing)
          // Save button in edit mode
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Changes',
            onPressed: _saveProjectChanges,
          )
        else
          // Edit button in view mode
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Project',
            onPressed: _toggleEditMode,
          ),
        // More options menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
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
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete Project', style: TextStyle(color: Colors.red)),
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
          const CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading project details...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
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
            // Project name
            if (_isEditing)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 18),
              )
            else
              Row(
                children: [
                  Icon(
                    Icons.work,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
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
                  border: OutlineInputBorder(),
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
                    color: Colors.grey[600],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Due Date: ${_formatDate(project.dueDate)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
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
                  color: project.isCompleted ? Colors.green : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  project.isCompleted ? 'Completed' : 'In Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: project.isCompleted ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
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
                      ? Colors.black87 
                      : Colors.grey[600],
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
                        backgroundColor: task.isCompleted ? Colors.green : Colors.orange,
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
                                    ? Colors.red 
                                    : Colors.grey.shade600,
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
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No related tasks',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
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
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: progress >= 75 
                            ? Colors.green 
                            : progress >= 50 
                                ? Colors.orange 
                                : Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 75 
                        ? Colors.green 
                        : progress >= 50 
                            ? Colors.orange 
                            : Colors.red,
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
            color: Colors.grey[600],
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
            color: Colors.red,
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
              backgroundColor: Colors.red,
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
        backgroundColor: Colors.red[600],
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
          backgroundColor: Colors.blue,
          child: const Icon(Icons.edit, color: Colors.white),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: "delete",
          onPressed: () => _showDeleteConfirmation(),
          backgroundColor: Colors.red,
          child: const Icon(Icons.delete, color: Colors.white),
        ),
      ],
    );
  }
}
