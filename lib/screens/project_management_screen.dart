/// Project management screen for comprehensive project oversight
/// Provides CRUD operations, filtering, and project analytics
/// Includes role-based access control and modern UI design
import 'package:flutter/material.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/models/project.dart' as TaskProject;
import 'package:task_management/screens/project_details_screen.dart';
import 'package:task_management/screens/create_project_screen.dart';
import 'package:task_management/screens/update_project_screen.dart';
import 'package:task_management/service/project_service.dart';
import 'package:intl/intl.dart';

class ProjectManagementScreen extends StatefulWidget {
  /// User ID for filtering projects
  final String userId;
  /// Current user object for role-based access
  final CustomUser user;
  /// Admin status for permission control
  final bool isAdmin;

  const ProjectManagementScreen({super.key, 
    required this.userId, 
    required this.user, 
    required this.isAdmin
  });

  @override
  _ProjectManagementScreenState createState() => _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> 
    with AutomaticKeepAliveClientMixin {
  // State variables
  List<TaskProject.Project> projects = []; // All projects
  List<TaskProject.Project> filteredProjects = []; // Filtered projects for display
  bool _isLoading = true; // Loading state
  String _errorMessage = ''; // Error message for user feedback
  String _searchQuery = ''; // Search query for filtering
  String _selectedFilter = 'All'; // Filter status
  
  // Controller for search
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true; // Keep widget alive when switching tabs

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Listen to search controller changes
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Clean up controller to prevent memory leaks
    _searchController.dispose();
    super.dispose();
  }

  /// Initializes data and loads projects
  /// Sets up initial state and fetches projects from service
  Future<void> _initializeData() async {
    await loadProjects();
  }

  /// Loads projects from service with error handling
  /// Updates state with fetched projects or error message
  Future<void> loadProjects() async {
    try {
      final projectService = ProjectService();
      final loadedProjects = (await projectService.getProjects(userId: widget.userId))
          .cast<TaskProject.Project>();
      
      if (mounted) {
        setState(() {
          projects = loadedProjects;
          filteredProjects = loadedProjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load projects: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Builds the main project management interface
  /// Creates responsive layout with search, filtering, and project list
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      // Modern app bar with search and actions
      appBar: _buildAppBar(context),
      // Main content with loading/error states
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
      // Floating action button for creating projects
      floatingActionButton: widget.isAdmin ? _buildFloatingActionButton() : null,
    );
  }

  /// Builds modern app bar with search and filtering
  /// Includes title, search bar, and filter options
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Projects',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      // Search and filter actions
      actions: [
        // Filter dropdown
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          tooltip: 'Filter Projects',
          onSelected: (String filter) {
            setState(() {
              _selectedFilter = filter;
              _applyFilters();
            });
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'All',
              child: Text('All Projects'),
            ),
            const PopupMenuItem(
              value: 'Active',
              child: Text('Active Projects'),
            ),
            const PopupMenuItem(
              value: 'Completed',
              child: Text('Completed Projects'),
            ),
            const PopupMenuItem(
              value: 'Overdue',
              child: Text('Overdue Projects'),
            ),
          ],
        ),
        // Refresh button
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh Projects',
          onPressed: _refreshProjects,
        ),
      ],
      // Search bar in app bar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search projects...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
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
            'Loading projects...',
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
  /// Shows project list or error state
  Widget _buildContent() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }
    
    if (filteredProjects.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _refreshProjects,
      child: Column(
        children: [
          // Statistics header
          _buildStatisticsHeader(),
          // Project list
          Expanded(
            child: _buildProjectList(),
          ),
        ],
      ),
    );
  }

  /// Builds statistics header
  /// Shows project count and completion metrics
  Widget _buildStatisticsHeader() {
    final totalProjects = projects.length;
    final completedProjects = projects.where((p) => p.isCompleted).length;
    final activeProjects = totalProjects - completedProjects;
    final overdueProjects = projects.where((p) => 
      !p.isCompleted && p.dueDate.isBefore(DateTime.now())
    ).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', totalProjects.toString(), Icons.folder),
          _buildStatItem('Active', activeProjects.toString(), Icons.pending),
          _buildStatItem('Completed', completedProjects.toString(), Icons.check_circle),
          _buildStatItem('Overdue', overdueProjects.toString(), Icons.warning),
        ],
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
            fontSize: 18,
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

  /// Builds modern project list
  /// Displays filtered projects with enhanced cards and actions
  Widget _buildProjectList() {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredProjects.length,
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        return _buildProjectCard(project);
      },
    );
  }

  /// Builds individual project card
  /// Creates rich card with project info and actions
  Widget _buildProjectCard(TaskProject.Project project) {
    final isOverdue = !project.isCompleted && project.dueDate.isBefore(DateTime.now());
    final daysUntilDue = project.dueDate.difference(DateTime.now()).inDays;
    
    return Card(
      elevation: project.isCompleted ? 1 : 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToProjectDetailsScreen(project),
        onLongPress: widget.isAdmin ? () => _showOptionsDialog(project) : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project header with status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: project.isCompleted ? Colors.grey[600] : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: project.isCompleted 
                          ? Colors.green 
                          : isOverdue 
                              ? Colors.red 
                              : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      project.isCompleted 
                          ? 'Completed' 
                          : isOverdue 
                              ? 'Overdue' 
                              : 'Active',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Project description (if available)
              if (project.description.isNotEmpty)
                Text(
                  project.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              // Project metadata
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(project.dueDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  if (!project.isCompleted && daysUntilDue >= 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: daysUntilDue <= 3 ? Colors.red : Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$daysUntilDue days',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              // Action buttons for admin
              if (widget.isAdmin) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Edit Project',
                      onPressed: () => _editProject(project),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      tooltip: 'Delete Project',
                      onPressed: () => _showDeleteConfirmation(project),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
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
            onPressed: _refreshProjects,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds empty state widget
  /// Shows message when no projects are available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty 
                ? 'No projects found matching "$_searchQuery"'
                : 'No projects available',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          if (widget.isAdmin && _searchQuery.isEmpty)
            Text(
              'Tap the + button to create your first project',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }

  /// Builds floating action button
  /// Creates modern FAB for creating projects
  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _navigateToCreateProjectScreen,
      icon: const Icon(Icons.add),
      label: const Text('New Project'),
      backgroundColor: Theme.of(context).primaryColor,
      tooltip: 'Create Project',
    );
  }

  /// Navigates to create project screen
  /// Handles result and updates project list
  Future<void> _navigateToCreateProjectScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateProjectScreen(),
      ),
    );

    if (result != null && result is TaskProject.Project) {
      setState(() {
        projects.add(result);
        _applyFilters();
      });
      _showSuccessSnackBar('Project created successfully');
    }
  }

  /// Navigates to project details screen
  /// Opens detailed view for selected project
  void _navigateToProjectDetailsScreen(TaskProject.Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(project: project),
      ),
    );
  }

  /// Shows options dialog for project management
  /// Provides edit and delete options for admin users
  void _showOptionsDialog(TaskProject.Project project) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Edit Project'),
              onTap: () {
                Navigator.pop(context);
                _editProject(project);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Project'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(project);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Navigates to edit project screen
  /// Opens update screen for selected project
  Future<void> _editProject(TaskProject.Project project) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateProjectScreen(project: project),
      ),
    );

    if (result != null && result is TaskProject.Project) {
      setState(() {
        final index = projects.indexWhere((p) => p.id == result.id);
        if (index != -1) {
          projects[index] = result;
          _applyFilters();
        }
      });
      _showSuccessSnackBar('Project updated successfully');
    }
  }

  /// Shows delete confirmation dialog
  /// Asks user to confirm project deletion
  void _showDeleteConfirmation(TaskProject.Project project) {
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
              _deleteProject(project);
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
  /// Removes project and updates UI
  Future<void> _deleteProject(TaskProject.Project project) async {
    try {
      final projectService = ProjectService();
      await projectService.deleteProject(
        projectId: project.id, 
        userId: widget.userId
      );

      setState(() {
        projects.remove(project);
        _applyFilters();
      });
      
      _showSuccessSnackBar('Project deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete project: ${e.toString()}');
    }
  }

  /// Refreshes projects from database
  /// Reloads project list with loading state
  Future<void> _refreshProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await loadProjects();
  }

  /// Handles search query changes
  /// Filters projects based on search input
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  /// Clears search query
  /// Resets search and applies filters
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _applyFilters();
    });
  }

  /// Applies search and status filters
  /// Updates filtered projects list
  void _applyFilters() {
    setState(() {
      filteredProjects = projects.where((project) {
        // Apply search filter
        final matchesSearch = _searchQuery.isEmpty ||
            project.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            project.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        // Apply status filter
        final matchesFilter = _selectedFilter == 'All' ||
            (_selectedFilter == 'Active' && !project.isCompleted) ||
            (_selectedFilter == 'Completed' && project.isCompleted) ||
            (_selectedFilter == 'Overdue' && !project.isCompleted && project.dueDate.isBefore(DateTime.now()));
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
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
}
