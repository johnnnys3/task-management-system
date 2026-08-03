/// Team details screen for viewing and editing a team.
/// Edit and delete actions are only available to admins.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/avatar_badge.dart';

class TeamDetailsScreen extends StatefulWidget {
  /// Team to display details for
  final Team team;

  /// Whether the current user may edit or delete this team
  final bool isAdmin;

  const TeamDetailsScreen({super.key, required this.team, required this.isAdmin});

  @override
  _TeamDetailsScreenState createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> {
  late Team team;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isEditing = false;

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  late final TeamStore _teamStore;

  @override
  void initState() {
    super.initState();
    _teamStore = context.read<TeamStore>();
    team = widget.team;
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: team.name);
    _descriptionController = TextEditingController(text: team.description);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          _buildContent(),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        _isEditing ? 'Edit Team' : 'Team Details',
        style: AppTheme.display(size: 20, weight: FontWeight.bold, color: AppColors.shell),
      ),
      backgroundColor: AppColors.ink,
      elevation: 0,
      actions: [
        if (widget.isAdmin && _isEditing)
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Changes',
            onPressed: _saveTeamChanges,
          )
        else if (widget.isAdmin)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            tooltip: 'Edit Team',
            onPressed: () => setState(() => _isEditing = true),
          ),
        if (widget.isAdmin && !_isEditing)
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            tooltip: 'Delete Team',
            onPressed: _showDeleteConfirmation,
          ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage.isNotEmpty) _buildErrorBanner(),
          _buildInfoCard(),
          if (!_isEditing && team.members.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMembersCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            child: Text(_errorMessage, style: TextStyle(color: AppColors.rust)),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _errorMessage = ''),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              style: const TextStyle(fontSize: 18),
            )
          else
            Row(
              children: [
                AvatarBadge(name: team.name, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: AppTheme.display(size: 22, weight: FontWeight.bold, color: AppColors.ink),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusPill(),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          if (_isEditing)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              maxLines: 4,
            )
          else
            Text(
              team.description.isNotEmpty ? team.description : 'No description available',
              style: TextStyle(
                fontSize: 16,
                color: team.description.isNotEmpty ? AppColors.ink : AppColors.ink3,
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.people, color: AppColors.ink2, size: 20),
              const SizedBox(width: 8),
              Text(
                '${team.members.length} member${team.members.length == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 16, color: AppColors.ink2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final isActive = team.status == TeamStatus.active;
    final color = isActive ? AppColors.terra : AppColors.ink3;
    final label = switch (team.status) {
      TeamStatus.active => 'Active',
      TeamStatus.inactive => 'Inactive',
      TeamStatus.archived => 'Archived',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMembersCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Members',
            style: AppTheme.display(size: 16, weight: FontWeight.bold, color: AppColors.ink),
          ),
          const SizedBox(height: 12),
          ...team.members.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    AvatarBadge(name: entry.key, size: 26),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
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
                        entry.value.value,
                        style: TextStyle(fontSize: 10, color: AppColors.ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _saveTeamChanges() async {
    final updatedTeam = team.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final errors = updatedTeam.validate();
    if (errors.isNotEmpty) {
      setState(() => _errorMessage = errors.first);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _teamStore.update(updatedTeam);

      setState(() {
        team = updatedTeam;
        _isEditing = false;
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to save team: ${error.toString()}';
      });
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${team.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTeam();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.rust, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTeam() async {
    setState(() => _isLoading = true);

    try {
      await _teamStore.delete(team.id);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to delete team: ${error.toString()}';
      });
    }
  }
}
