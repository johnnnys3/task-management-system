import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/avatar_badge.dart';
import 'package:task_management/widgets/entity_form_scaffold.dart';
import 'package:task_management/widgets/pill_button.dart';

class CreateTeamScreen extends StatefulWidget {
  /// Current user ID, recorded as the team's creator and owner.
  final String userId;

  const CreateTeamScreen({super.key, required this.userId});

  @override
  _CreateTeamScreenState createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController teamNameController = TextEditingController();
  final TextEditingController teamDescriptionController = TextEditingController();
  final TextEditingController _memberController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  TeamStatus _status = TeamStatus.active;
  // ponytail: no user directory to pick members from, so members are added
  // by typing a user id and are always granted TeamRole.member.
  final List<String> _memberIds = [];

  late final TeamStore _teamStore;

  @override
  void initState() {
    super.initState();
    _teamStore = context.read<TeamStore>();
  }

  @override
  void dispose() {
    teamNameController.dispose();
    teamDescriptionController.dispose();
    _memberController.dispose();
    super.dispose();
  }

  void _addMember() {
    final id = _memberController.text.trim();
    if (id.isEmpty || _memberIds.contains(id) || id == widget.userId) return;
    setState(() {
      _memberIds.add(id);
      _memberController.clear();
    });
  }

  Future<void> _createTeam() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final Team newTeam = Team(
        id: '',
        name: teamNameController.text.trim(),
        description: teamDescriptionController.text.trim(),
        members: {
          widget.userId: TeamRole.owner,
          for (final id in _memberIds) id: TeamRole.member,
        },
        status: _status,
        createdBy: widget.userId,
      );

      final id = await _teamStore.create(newTeam);

      if (mounted) {
        Navigator.pop(context, newTeam.copyWith(id: id));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create team: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: 'Create Team',
      formKey: _formKey,
      isLoading: _isLoading,
      loadingMessage: 'Creating team...',
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = ''),
      onSave: _createTeam,
      saveTooltip: 'Save Team',
      bottomNavigationBar: _buildBottomActions(),
      children: [
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Team Details',
                style: AppTheme.display(size: 20, weight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: teamNameController,
                validator: Team.validateName,
                decoration: InputDecoration(
                  labelText: 'Team Name *',
                  hintText: 'Enter team name',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.terra,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.rust),
                  ),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: teamDescriptionController,
                validator: Team.validateDescription,
                decoration: InputDecoration(
                  labelText: 'Team Description',
                  hintText: 'Enter team description',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.terra,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.rust),
                  ),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<TeamStatus>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  prefixIcon: const Icon(Icons.flag_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
                items: TeamStatus.values
                    .map((status) => DropdownMenuItem(value: status, child: Text(status.value)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Members',
                style: AppTheme.display(size: 20, weight: FontWeight.bold, color: AppColors.ink),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _memberController,
                      decoration: InputDecoration(
                        hintText: 'Enter a member user id',
                        prefixIcon: const Icon(Icons.person_add_alt),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onFieldSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  PillButton(label: 'Add', onPressed: _addMember),
                ],
              ),
              if (_memberIds.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _memberIds
                      .map((id) => Chip(
                            avatar: AvatarBadge(name: id, size: 22),
                            label: Text(id),
                            onDeleted: () => setState(() => _memberIds.remove(id)),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: PillButton(
              label: 'Cancel',
              outlined: true,
              onPressed: _isLoading ? null : () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PillButton(
              label: 'Create Team',
              onPressed: _isLoading ? null : _createTeam,
            ),
          ),
        ],
      ),
    );
  }
}
