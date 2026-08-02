/// Advanced team management screen for comprehensive team operations
/// Provides rich team display with modern UI and interactive features
/// Includes team creation, member management, and role assignments
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';

class TeamManagementScreen extends StatefulWidget {
  /// Current user ID for team operations
  final String userId;
  /// Admin status for permission-based actions
  final bool isAdmin;

  const TeamManagementScreen({
    Key? key,
    required this.userId,
    this.isAdmin = false,
  }) : super(key: key);

  @override
  _TeamManagementScreenState createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  // State variables for team management
  List<Team> _teams = [];
  List<Team> _filteredTeams = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  
  // Filter options
  final List<String> _filterOptions = ['All', 'Active', 'Inactive', 'My Teams'];

  late final TeamStore _teamStore;

  @override
  void initState() {
    super.initState();
    _teamStore = context.read<TeamStore>();
    // Load teams and setup listeners
    _loadTeams();
    _setupSearchListener();
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Modern app bar with search and filters
      appBar: _buildAppBar(),
      // Main content with loading overlay
      body: Stack(
        children: [
          // Content with search, filters, and team list
          _buildContent(),
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
      // Floating action button for team creation
      floatingActionButton: widget.isAdmin
          ? FloatingActionButton.extended(
              onPressed: _navigateToCreateTeam,
              icon: const Icon(Icons.add),
              label: const Text('Create Team'),
              backgroundColor: Theme.of(context).primaryColor,
            )
          : null,
    );
  }

  /// Builds modern app bar
  /// Includes title, search, and filter options
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Teams',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      // Search bar in app bar
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search field
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search teams...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Filter dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedFilter,
                decoration: const InputDecoration(
                  labelText: 'Filter',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: _filterOptions.map((filter) {
                  return DropdownMenuItem(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                  _applyFilters();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds main content area
  /// Creates layout with error display and team list
  Widget _buildContent() {
    return Column(
      children: [
        // Error message display
        if (_errorMessage.isNotEmpty) _buildErrorMessage(),
        // Team statistics
        _buildTeamStatistics(),
        // Team list
        Expanded(
          child: _filteredTeams.isEmpty
              ? _buildEmptyState()
              : _buildTeamList(),
        ),
      ],
    );
  }

  /// Builds error message widget
  /// Shows error with dismiss option
  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(16),
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
                Text('Loading teams...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds team statistics
  /// Shows count of teams by status
  Widget _buildTeamStatistics() {
    final activeCount = _teams.where((team) => team.status == TeamStatus.active).length;
    final inactiveCount = _teams.where((team) => team.status == TeamStatus.inactive).length;
    final myTeamsCount = _teams.where((team) => team.members.containsKey(widget.userId)).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Total teams
          _buildStatCard('Total', _teams.length.toString(), Colors.blue),
          const SizedBox(width: 8),
          // Active teams
          _buildStatCard('Active', activeCount.toString(), Colors.green),
          const SizedBox(width: 8),
          // Inactive teams
          _buildStatCard('Inactive', inactiveCount.toString(), Colors.grey),
          const SizedBox(width: 8),
          // My teams
          _buildStatCard('My Teams', myTeamsCount.toString(), Colors.purple),
        ],
      ),
    );
  }

  /// Builds empty state widget
  /// Shows message when no teams match filters
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty 
                ? 'No teams found matching "${_searchController.text}"'
                : 'No teams found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isAdmin 
                ? 'Create a new team to get started'
                : 'Contact an admin to create teams',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  /// Loads teams from database with error handling
  /// Updates both full list and filtered list
  Future<void> _loadTeams() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final loadedTeams = await _teamStore.fetch();

      setState(() {
        _teams = loadedTeams;
        _filteredTeams = loadedTeams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading teams: $e';
      });
    }
  }

  /// Sets up search listener for real-time filtering
  /// Updates filtered teams as user types
  void _setupSearchListener() {
    _searchController.addListener(() {
      _applyFilters();
    });
  }

  /// Applies current filter to teams
  /// Updates filtered teams based on search and filter
  void _applyFilters() {
    setState(() {
      _filteredTeams = _teams.where((team) {
        // Apply search filter
        final matchesSearch = _searchController.text.isEmpty ||
            team.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            team.description.toLowerCase().contains(_searchController.text.toLowerCase());
        
        // Apply status filter
        final matchesFilter = _matchesFilter(team);
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  /// Checks if team matches current filter
  /// Returns true if team should be displayed
  bool _matchesFilter(Team team) {
    switch (_selectedFilter) {
      case 'Active':
        return team.status == TeamStatus.active;
      case 'Inactive':
        return team.status == TeamStatus.inactive;
      case 'My Teams':
        return team.members.containsKey(widget.userId);
      default:
        return true; // 'All' filter
    }
  }

  /// Navigates to team creation screen
  /// Opens team creation form
  void _navigateToCreateTeam() {
    // TODO: Navigate to team creation screen
    _showSuccessSnackBar('Team creation not implemented yet');
  }

  /// Navigates to team details screen
  /// Opens team details for viewing and editing
  void _navigateToTeamDetails(Team team) {
    // TODO: Navigate to team details screen
    _showSuccessSnackBar('Team details not implemented yet');
  }

  /// Navigates to team update screen
  /// Opens team update for modification
  void _navigateToUpdateTeam(Team team) {
    // TODO: Navigate to team update screen
    _showSuccessSnackBar('Team update not implemented yet');
  }

  /// Deletes team from database
  /// Shows confirmation dialog and updates list
  Future<void> _deleteTeam(Team team) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${team.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
        
        await _teamStore.delete(team.id);
        await _loadTeams();
        _showSuccessSnackBar('Team deleted successfully');
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error deleting team: $e';
        });
      }
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

  /// Builds team list
  /// Displays teams in a scrollable list
  Widget _buildTeamList() {
    return ListView.builder(
      itemCount: _filteredTeams.length,
      itemBuilder: (context, index) {
        final team = _filteredTeams[index];
        return TeamListItem(
          team: team,
          onTap: () => _navigateToTeamDetails(team),
          onUpdateTeam: widget.isAdmin ? () => _navigateToUpdateTeam(team) : null,
          onDeleteTeam: widget.isAdmin ? () => _deleteTeam(team) : null,
        );
      },
    );
  }

  /// Builds individual statistic card
  /// Creates styled card for team count
  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                count,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Modern team list item with rich information display
/// Provides team card with interactive features
/// Includes status indicators, member count, and action buttons
class TeamListItem extends StatelessWidget {
  /// Team to display
  final Team team;
  /// Callback for team tap
  final VoidCallback onTap;
  /// Callback for team update
  final VoidCallback? onUpdateTeam;
  /// Callback for team delete
  final VoidCallback? onDeleteTeam;
  /// Whether current user is team member
  final bool isMember;

  const TeamListItem({
    Key? key,
    required this.team,
    required this.onTap,
    this.onUpdateTeam,
    this.onDeleteTeam,
    this.isMember = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      team.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: team.status == TeamStatus.active ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      team.status == TeamStatus.active ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              if (team.description.isNotEmpty)
                Text(
                  team.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 12),
              // Footer with member count and actions
              Row(
                children: [
                  // Member count
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${team.members.length} member${team.members.length == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Member badge
                  if (isMember)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Member',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // More options button
                  if (onUpdateTeam != null || onDeleteTeam != null)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => _handleMenuAction(value),
                      itemBuilder: (context) => [
                        if (onUpdateTeam != null)
                          const PopupMenuItem(
                            value: 'update',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 18),
                                SizedBox(width: 8),
                                Text('Update'),
                              ],
                            ),
                          ),
                        if (onDeleteTeam != null)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handles menu action selection
  /// Processes update and delete actions
  void _handleMenuAction(String action) {
    switch (action) {
      case 'update':
        if (onUpdateTeam != null) onUpdateTeam!();
        break;
      case 'delete':
        if (onDeleteTeam != null) onDeleteTeam!();
        break;
    }
  }

}
