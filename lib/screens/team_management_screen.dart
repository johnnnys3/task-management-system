/// Advanced team management screen for comprehensive team operations
/// Provides rich team display with modern UI and interactive features
/// Includes team creation, member management, and role assignments
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';
import 'package:task_management/screens/create_team_screen.dart';
import 'package:task_management/screens/team_details_screen.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/avatar_badge.dart';
import 'package:task_management/widgets/pill_button.dart';
import 'package:task_management/navigation/app_shell.dart';

class TeamManagementScreen extends StatefulWidget implements ShellPage {
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
  String get title => 'Teams';

  @override
  String? get subtitle => null;

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
    return Container(
      color: AppColors.pageBg,
      child: Stack(
        children: [
          Column(
            children: [
              _buildSearchAndFilterHeader(),
              Expanded(
                child: Stack(
                  children: [
                    _buildContent(),
                    if (_isLoading) _buildLoadingOverlay(),
                  ],
                ),
              ),
            ],
          ),
          if (widget.isAdmin)
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: _navigateToCreateTeam,
                icon: const Icon(Icons.add),
                label: const Text('Create Team'),
                backgroundColor: AppColors.terra,
                foregroundColor: AppColors.shell,
              ),
            ),
        ],
      ),
    );
  }

  /// Search bar + filter dropdown, previously the app bar's bottom.
  Widget _buildSearchAndFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search teams...',
              prefixIcon: const Icon(Icons.search),
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
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedFilter,
            decoration: InputDecoration(
              labelText: 'Filter',
              filled: true,
              fillColor: AppColors.paper,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
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
        color: AppColors.blush,
        border: Border.all(color: AppColors.rust.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
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
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Loading teams...'),
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
          _buildStatCard('Total', _teams.length.toString(), AppColors.ink),
          const SizedBox(width: 8),
          // Active teams
          _buildStatCard('Active', activeCount.toString(), AppColors.terra),
          const SizedBox(width: 8),
          // Inactive teams
          _buildStatCard('Inactive', inactiveCount.toString(), AppColors.ink3),
          const SizedBox(width: 8),
          // My teams
          _buildStatCard('My Teams', myTeamsCount.toString(), AppColors.rust),
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
            color: AppColors.ink3,
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isNotEmpty
                ? 'No teams found matching "${_searchController.text}"'
                : 'No teams found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.ink2,
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
              color: AppColors.ink3,
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
  Future<void> _navigateToCreateTeam() async {
    final created = await Navigator.push<Team>(
      context,
      MaterialPageRoute(builder: (context) => CreateTeamScreen(userId: widget.userId)),
    );
    if (created != null) {
      await _loadTeams();
    }
  }

  /// Navigates to team details screen
  /// Opens team details for viewing, editing, and deleting
  Future<void> _navigateToTeamDetails(Team team) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamDetailsScreen(team: team, isAdmin: widget.isAdmin),
      ),
    );
    await _loadTeams();
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
            child: Text('Delete', style: TextStyle(color: AppColors.rust)),
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
        backgroundColor: AppColors.terra,
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

  /// Builds responsive team grid
  /// Displays teams in a responsive card grid
  Widget _buildTeamList() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 340,
        mainAxisSpacing: 11,
        crossAxisSpacing: 11,
        mainAxisExtent: 360,
      ),
      itemCount: _filteredTeams.length,
      itemBuilder: (context, index) {
        final team = _filteredTeams[index];
        return TeamListItem(
          team: team,
          onTap: () => _navigateToTeamDetails(team),
          onDeleteTeam: widget.isAdmin ? () => _deleteTeam(team) : null,
          isMember: team.members.containsKey(widget.userId),
        );
      },
    );
  }

  /// Builds individual statistic card
  /// Creates styled card for team count
  Widget _buildStatCard(String label, String count, Color color) {
    return Expanded(
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              count,
              style: AppTheme.display(size: 20, weight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.ink2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
  /// Callback for team delete
  final VoidCallback? onDeleteTeam;
  /// Whether current user is team member
  final bool isMember;

  const TeamListItem({
    Key? key,
    required this.team,
    required this.onTap,
    this.onDeleteTeam,
    this.isMember = false,
  }) : super(key: key);

  Color get _statusColor => team.status == TeamStatus.active ? AppColors.terra : AppColors.ink3;

  String get _statusLabel {
    switch (team.status) {
      case TeamStatus.active:
        return 'Active';
      case TeamStatus.inactive:
        return 'Inactive';
      case TeamStatus.archived:
        return 'Archived';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar, name and status
            Row(
              children: [
                AvatarBadge(name: team.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: AppTheme.display(size: 18, weight: FontWeight.bold, color: AppColors.ink),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${team.members.length} member${team.members.length == 1 ? '' : 's'} · ${team.projects.length} project${team.projects.length == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 12, color: AppColors.ink2),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel,
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
                  color: AppColors.ink2,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (team.description.isNotEmpty) const SizedBox(height: 12),
            // Member list
            if (team.members.isNotEmpty) ...[
              ...team.members.entries.take(3).map((entry) => _MemberRow(userId: entry.key, role: entry.value)),
              const SizedBox(height: 4),
            ],
            // Footer with member badge and actions
            Row(
              children: [
                const Spacer(),
                // Member badge
                if (isMember)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.rust,
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
                if (onDeleteTeam != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) => _handleMenuAction(value),
                    itemBuilder: (context) => [
                      if (onDeleteTeam != null)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: AppColors.rust),
                              const SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: AppColors.rust)),
                            ],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
    );
  }

  /// Handles menu action selection
  /// Processes delete action
  void _handleMenuAction(String action) {
    switch (action) {
      case 'delete':
        if (onDeleteTeam != null) onDeleteTeam!();
        break;
    }
  }
}

/// Single member row: avatar, name, role pill.
class _MemberRow extends StatelessWidget {
  final String userId;
  final TeamRole role;

  const _MemberRow({required this.userId, required this.role});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AvatarBadge(name: userId, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              userId,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.sand,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              role.value,
              style: TextStyle(fontSize: 10, color: AppColors.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
