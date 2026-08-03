import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/models/project.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/entity_form_scaffold.dart';
import 'package:task_management/widgets/pill_button.dart';

/// Color for a given [ProjectStatus], matching the TaskHub palette.
Color projectStatusColor(ProjectStatus status) {
  switch (status) {
    case ProjectStatus.planning:
      return AppColors.ink3;
    case ProjectStatus.inProgress:
      return AppColors.terra;
    case ProjectStatus.onHold:
      return const Color(0xFFC08A3E);
    case ProjectStatus.completed:
      return AppColors.sage;
    case ProjectStatus.cancelled:
      return AppColors.ink3;
  }
}

/// Display label for a given [ProjectStatus].
String projectStatusLabel(ProjectStatus status) {
  switch (status) {
    case ProjectStatus.planning:
      return 'Planning';
    case ProjectStatus.inProgress:
      return 'In Progress';
    case ProjectStatus.onHold:
      return 'On Hold';
    case ProjectStatus.completed:
      return 'Completed';
    case ProjectStatus.cancelled:
      return 'Cancelled';
  }
}

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController projectDescriptionController = TextEditingController();
  DateTime selectedDueDate = DateTime.now();
  TimeOfDay selectedDueTime = TimeOfDay.now();
  ProjectStatus _selectedStatus = ProjectStatus.planning;
  bool _isLoading = false;
  String _errorMessage = '';

  late final ProjectStore _projectStore;

  @override
  void initState() {
    super.initState();
    _projectStore = context.read<ProjectStore>();
  }

  @override
  void dispose() {
    projectNameController.dispose();
    projectDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final DateTime combinedDueDate = DateTime(
        selectedDueDate.year,
        selectedDueDate.month,
        selectedDueDate.day,
        selectedDueTime.hour,
        selectedDueTime.minute,
      );

      final Project newProject = Project(
        name: projectNameController.text.trim(),
        description: projectDescriptionController.text.trim(),
        dueDate: combinedDueDate,
        tasks: const [],
        id: '',
        isCompleted: false,
        status: _selectedStatus,
      );

      await _projectStore.create(newProject);

      if (mounted) {
        Navigator.pop(context, newProject);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create project: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Opens date and time picker for project due date
  /// Allows user to select both date and time in a single flow
  /// Uses current date/time as default and validates selection
  Future<void> _selectDateTime(BuildContext context) async {
    // Show date picker first
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDueDate,
      firstDate: DateTime.now(), // Don't allow past dates
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // Max 2 years ahead
      builder: (context, child) {
        // Apply app theme to date picker
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    // Only proceed if user selected a date
    if (pickedDate != null) {
      // Show time picker after date selection
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: selectedDueTime,
        builder: (context, child) {
          // Apply app theme to time picker
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: Theme.of(context).primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      // Only update state if user selected a time
      if (pickedTime != null) {
        setState(() {
          // Combine selected date and time into single DateTime
          selectedDueDate = pickedDate;
          selectedDueTime = pickedTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return EntityFormScaffold(
      title: 'Create Project',
      formKey: _formKey,
      isLoading: _isLoading,
      loadingMessage: 'Creating project...',
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = ''),
      onSave: _createProject,
      saveTooltip: 'Save Project',
      bottomNavigationBar: _buildBottomActions(),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Project Details',
                style: AppTheme.display(size: 20, color: AppColors.ink),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: projectNameController,
                validator: Project.validateName,
                decoration: const InputDecoration(
                  labelText: 'Project Name *',
                  hintText: 'Enter project name',
                  prefixIcon: Icon(Icons.title),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: projectDescriptionController,
                validator: Project.validateDescription,
                decoration: const InputDecoration(
                  labelText: 'Project Description *',
                  hintText: 'Enter project description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 20),
              Text(
                'Status',
                style: AppTheme.display(size: 14, color: AppColors.ink2),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProjectStatus.values.map((status) {
                  final color = projectStatusColor(status);
                  final selected = status == _selectedStatus;
                  final pill = PillButton(
                    label: projectStatusLabel(status),
                    outlined: !selected,
                    onPressed: () => setState(() => _selectedStatus = status),
                  );
                  if (!selected) return pill;
                  return Theme(
                    data: Theme.of(context).copyWith(
                      elevatedButtonTheme: ElevatedButtonThemeData(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: AppColors.shell,
                          textStyle: AppTheme.display(size: 14, color: AppColors.shell),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                      ),
                    ),
                    child: pill,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () => _selectDateTime(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.edge),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.schedule, color: AppColors.terra),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Due Date & Time',
                              style: TextStyle(
                                color: AppColors.terra,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMd().add_jm().format(
                                DateTime(
                                  selectedDueDate.year,
                                  selectedDueDate.month,
                                  selectedDueDate.day,
                                  selectedDueTime.hour,
                                  selectedDueTime.minute,
                                ),
                              ),
                              style: const TextStyle(
                                color: AppColors.ink2,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: AppColors.terra),
                    ],
                  ),
                ),
              ),
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
              label: 'Create Project',
              onPressed: _isLoading ? null : _createProject,
            ),
          ),
        ],
      ),
    );
  }
}
