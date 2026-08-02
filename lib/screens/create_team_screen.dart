import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/models/team.dart';
import 'package:task_management/widgets/entity_form_scaffold.dart';

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
  bool _isLoading = false;
  String _errorMessage = '';

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
    super.dispose();
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
        members: {widget.userId: TeamRole.owner},
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
      children: [
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Team Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
