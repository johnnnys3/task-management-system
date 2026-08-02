/// Team details screen for viewing and editing a team.
/// Edit and delete actions are only available to admins.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';

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
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Theme.of(context).primaryColor,
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
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
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
            child: Text(_errorMessage, style: TextStyle(color: Colors.red.shade700)),
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
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Team Name',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 18),
              )
            else
              Row(
                children: [
                  Icon(Icons.group, color: Theme.of(context).primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      team.name,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (_isEditing)
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              )
            else
              Text(
                team.description.isNotEmpty ? team.description : 'No description available',
                style: TextStyle(
                  fontSize: 16,
                  color: team.description.isNotEmpty ? Colors.black87 : Colors.grey[600],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.people, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  '${team.members.length} member${team.members.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveTeamChanges() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Team name is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final updatedTeam = team.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        updatedAt: DateTime.now(),
      );
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
