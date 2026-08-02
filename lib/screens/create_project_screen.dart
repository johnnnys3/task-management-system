import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/models/project.dart';
import 'package:task_management/widgets/entity_form_scaffold.dart';

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
                  'Project Details',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: projectNameController,
                  validator: Project.validateName,
                  decoration: InputDecoration(
                    labelText: 'Project Name *',
                    hintText: 'Enter project name',
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
                  controller: projectDescriptionController,
                  validator: Project.validateDescription,
                  decoration: InputDecoration(
                    labelText: 'Project Description *',
                    hintText: 'Enter project description',
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
                const SizedBox(height: 20),
                InkWell(
                  onTap: () => _selectDateTime(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Due Date & Time',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
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
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).primaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
