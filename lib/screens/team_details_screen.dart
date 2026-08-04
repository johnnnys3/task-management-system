/// Team details screen for viewing and editing a team.
/// Edit and delete actions are only available to admins.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/avatar_badge.dart';
import 'package:task_management/widgets/pill_button.dart';

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
  late final TaskStore _taskStore;

  // ponytail: no separate "edit team" screen exists yet, so Edit toggles an
  // inline form on this screen (matching the pre-existing behavior) rather
  // than pushing a new route.
  Map<String, int>? _openTaskCounts;

  @override
  void initState() {
    super.initState();
    _teamStore = context.read<TeamStore>();
    _taskStore = context.read<TaskStore>();
    team = widget.team;
    _initializeControllers();
    _loadOpenTaskCounts();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: team.name);
    _descriptionController = TextEditingController(text: team.description);
  }

  Future<void> _loadOpenTaskCounts() async {
    final counts = <String, int>{};
    for (final userId in team.members.keys) {
      try {
        final tasks = await _taskStore.fetch(userId: userId);
        counts[userId] = tasks.where((t) => !t.isCompleted).length;
      } catch (_) {
        counts[userId] = 0;
      }
    }
    if (mounted) setState(() => _openTaskCounts = counts);
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
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Team' : 'Team Details'),
      ),
      body: Stack(
        children: [
          _buildContent(),
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
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
          if (widget.isAdmin) ...[
            const SizedBox(height: 16),
            _buildActions(),
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
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.rust),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_errorMessage, style: const TextStyle(color: AppColors.rust)),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AvatarBadge(name: team.name, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name, style: AppTheme.display(size: 22)),
                      const SizedBox(height: 4),
                      Text(
                        '${team.members.length} member${team.members.length == 1 ? '' : 's'}'
                        ' · ${team.projects.length} project${team.projects.length == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 13, color: AppColors.ink2),
                      ),
                      const SizedBox(height: 8),
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
                fontSize: 14.5,
                color: team.description.isNotEmpty ? AppColors.ink2 : AppColors.ink3,
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final isActive = team.status == TeamStatus.active;
    final bg = isActive ? AppColors.mint : AppColors.sand;
    final fg = isActive ? AppColors.terraDark : AppColors.ink3;
    final label = switch (team.status) {
      TeamStatus.active => 'Active',
      TeamStatus.inactive => 'Inactive',
      TeamStatus.archived => 'Archived',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildMembersCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Members', style: AppTheme.display(size: 16)),
          const SizedBox(height: 12),
          ...team.members.entries.map((entry) => _MemberRow(
                userId: entry.key,
                role: entry.value,
                openTaskCount: _openTaskCounts?[entry.key],
              )),
        ],
      ),
    );
  }

  Widget _buildActions() {
    if (_isEditing) {
      return Row(
        children: [
          Expanded(
            child: PillButton(
              label: 'Cancel',
              outlined: true,
              onPressed: () => setState(() {
                _isEditing = false;
                _initializeControllers();
              }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PillButton(label: 'Save', onPressed: _saveTeamChanges),
          ),
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: PillButton(
            label: 'Edit',
            icon: Icons.edit,
            onPressed: () => setState(() => _isEditing = true),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: PillButton(
            label: 'Delete',
            icon: Icons.delete,
            outlined: true,
            danger: true,
            onPressed: _showDeleteConfirmation,
          ),
        ),
      ],
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

/// Single member row: avatar, name, role pill, open-task count.
class _MemberRow extends StatelessWidget {
  final String userId;
  final TeamRole role;
  final int? openTaskCount;

  const _MemberRow({required this.userId, required this.role, this.openTaskCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          AvatarBadge(name: userId, size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              userId,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.sand, borderRadius: BorderRadius.circular(99)),
            child: Text(
              role.value,
              style: const TextStyle(fontSize: 11, color: AppColors.ink, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 62,
            child: Text(
              openTaskCount == null ? '…' : '$openTaskCount open',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11.5, color: AppColors.ink3, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
