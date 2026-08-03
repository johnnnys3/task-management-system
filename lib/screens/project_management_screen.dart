/// Project management screen for comprehensive project oversight
/// Provides CRUD operations, filtering, and project analytics
/// Includes role-based access control and modern UI design
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/models/project.dart' as TaskProject;
import 'package:task_management/screens/project_details_screen.dart';
import 'package:task_management/screens/create_project_screen.dart';
import 'package:task_management/screens/update_project_screen.dart';
import 'package:intl/intl.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/pill_button.dart';
import 'package:task_management/widgets/progress_bar.dart';
import 'package:task_management/navigation/app_shell.dart';

/// Local color mapping for [TaskProject.ProjectStatus], not reused widely
/// enough to warrant a home in AppColors.
Color _projectStatusColor(TaskProject.ProjectStatus status) {
  switch (status) {
    case TaskProject.ProjectStatus.planning:
      return AppColors.ink3;
    case TaskProject.ProjectStatus.inProgress:
      return AppColors.terra;
    case TaskProject.ProjectStatus.onHold:
      return const Color(0xFFC08A3E); // amber
    case TaskProject.ProjectStatus.completed:
      return AppColors.sage;
    case TaskProject.ProjectStatus.cancelled:
      return AppColors.ink3;
  }
}

String _projectStatusLabel(TaskProject.ProjectStatus status) {
  switch (status) {
    case TaskProject.ProjectStatus.planning:
      return 'Planning';
    case TaskProject.ProjectStatus.inProgress:
      return 'Active';
    case TaskProject.ProjectStatus.onHold:
      return 'On Hold';
    case TaskProject.ProjectStatus.completed:
      return 'Completed';
    case TaskProject.ProjectStatus.cancelled:
      return 'Cancelled';
  }
}

class ProjectManagementScreen extends StatefulWidget implements ShellPage {
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
  String get title => 'Projects';

  @override
  String? get subtitle => null;

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

  late final ProjectStore _projectStore;

  @override
  bool get wantKeepAlive => true; // Keep widget alive when switching tabs

  @override
  void initState() {
    super.initState();
    _projectStore = context.read<ProjectStore>();
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
      final loadedProjects = await _projectStore.fetch();

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

    return Stack(
      children: [
        Column(
          children: [
            _buildSearchAndFilterHeader(),
            Expanded(child: _isLoading ? _buildLoadingWidget() : _buildContent()),
          ],
        ),
        if (widget.isAdmin)
          Positioned(right: 16, bottom: 16, child: _buildFloatingActionButton()),
      ],
    );
  }

  /// Search bar + filter/refresh row, previously the app bar's bottom + actions.
  Widget _buildSearchAndFilterHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
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
                fillColor: AppColors.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: AppColors.ink),
            tooltip: 'Filter Projects',
            onSelected: (String filter) {
              setState(() {
                _selectedFilter = filter;
                _applyFilters();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Projects')),
              const PopupMenuItem(value: 'Active', child: Text('Active Projects')),
              const PopupMenuItem(value: 'Completed', child: Text('Completed Projects')),
              const PopupMenuItem(value: 'Overdue', child: Text('Overdue Projects')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.ink),
            tooltip: 'Refresh Projects',
            onPressed: _refreshProjects,
          ),
        ],
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
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.terra),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading projects...',
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
        color: AppColors.terra.withOpacity(0.1),
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
          color: AppColors.terra,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.display(size: 18, color: AppColors.ink),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.ink2,
          ),
        ),
      ],
    );
  }

  /// Builds responsive project grid
  /// Displays filtered projects with enhanced cards and actions
  Widget _buildProjectList() {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisSpacing: 11,
        crossAxisSpacing: 11,
        mainAxisExtent: 268,
      ),
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
    final statusColor = _projectStatusColor(project.status);
    final total = project.tasks.length;
    final done = project.completedTasksCount;
    final progress = total == 0 ? 0.0 : done / total;

    return AppCard(
        onTap: () => _navigateToProjectDetailsScreen(project),
        child: InkWell(
          onLongPress: widget.isAdmin ? () => _showOptionsDialog(project) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project header with color swatch and status
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.avatarColor(project.id),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      project.name,
                      style: AppTheme.display(size: 18, color: AppColors.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 8),
              // Project description (if available)
              if (project.description.isNotEmpty)
                Text(
                  project.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.ink2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              // Completion progress
              Text(
                '$done of $total done',
                style: TextStyle(fontSize: 13, color: AppColors.ink2, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              AppProgressBar(value: progress, color: AppColors.terra),
              const SizedBox(height: 12),
              // Project metadata
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: isOverdue ? AppColors.rust : AppColors.ink2,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Due: ${DateFormat('MMM dd, yyyy').format(project.dueDate)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isOverdue ? AppColors.rust : AppColors.ink2,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (!project.isCompleted && daysUntilDue >= 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: daysUntilDue <= 3 ? AppColors.rust : AppColors.terra,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$daysUntilDue days',
                        style: TextStyle(
                          color: AppColors.shell,
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
                      icon: Icon(Icons.delete, size: 20, color: AppColors.rust),
                      tooltip: 'Delete Project',
                      onPressed: () => _showDeleteConfirmation(project),
                    ),
                  ],
                ),
              ],
            ],
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
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.rust,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.ink,
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
            color: AppColors.ink3,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty
                ? 'No projects found matching "$_searchQuery"'
                : 'No projects available',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 8),
          if (widget.isAdmin && _searchQuery.isEmpty)
            Text(
              'Tap the + button to create your first project',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.ink3,
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
              leading: Icon(Icons.edit, color: AppColors.terra),
              title: const Text('Edit Project'),
              onTap: () {
                Navigator.pop(context);
                _editProject(project);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: AppColors.rust),
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
              backgroundColor: AppColors.rust,
              foregroundColor: AppColors.shell,
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
      await _projectStore.delete(project.id);

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
            Icon(Icons.check_circle, color: AppColors.shell),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppColors.shell),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.sage,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.shell,
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
            Icon(Icons.error, color: AppColors.shell),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppColors.shell),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.rust,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: AppColors.shell,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
