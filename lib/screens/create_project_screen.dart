import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_management/data/database_helper(project).dart';
import 'package:task_management/models/project.dart';

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
  bool _autoValidate = false;

  @override
  void dispose() {
    projectNameController.dispose();
    projectDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _createProject(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _autoValidate = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final DateTime combinedDueDate = DateTime(
        selectedDueDate.year,
        selectedDueDate.month,
        selectedDueDate.day,
        selectedDueTime.hour,
        selectedDueTime.minute,
      );

      Project newProject = Project(
        name: projectNameController.text.trim(),
        description: projectDescriptionController.text.trim(),
        dueDate: combinedDueDate,
        tasks: [],
        id: '',
        isCompleted: false,
      );

      await ProjectDatabase().addProject(newProject);
      
      if (mounted) {
        Navigator.pop(context, newProject);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(context, 'Failed to create project: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Validates project name input
  /// Ensures project name meets all requirements:
  /// - Not empty
  /// - Between 3-50 characters
  /// - Only contains allowed characters (letters, numbers, spaces, hyphens, underscores)
  String? _validateProjectName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Project name is required';
    }
    if (value.trim().length < 3) {
      return 'Project name must be at least 3 characters';
    }
    if (value.trim().length > 50) {
      return 'Project name must not exceed 50 characters';
    }
    // Regex to allow only letters, numbers, spaces, hyphens, and underscores
    if (!RegExp(r'^[a-zA-Z0-9\s\-_]+$').hasMatch(value.trim())) {
      return 'Project name can only contain letters, numbers, spaces, hyphens, and underscores';
    }
    return null; // Validation passed
  }

  /// Validates project description input
  /// Ensures description does not exceed 500 characters
  /// Description is optional, so null/empty values are allowed
  String? _validateProjectDescription(String? value) {
    if (value != null && value.trim().length > 500) {
      return 'Description must not exceed 500 characters';
    }
    return null; // Validation passed
  }

  /// Displays error message in a snackbar
  /// Features:
  /// - Hides any existing snackbars first
  /// - Shows error icon with message
  /// - Red background for error indication
  /// - Auto-dismisses after 4 seconds
  /// - Provides manual dismiss button
  void _showErrorSnackbar(BuildContext context, String message) {
    // Hide any existing snackbars to prevent overlap
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Show new error snackbar with custom styling
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            // Error icon for visual indication
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            // Error message text
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600], // Red background for errors
        duration: const Duration(seconds: 4), // Auto-dismiss after 4 seconds
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            // Manual dismiss action
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Project'),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: _autoValidate ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                        validator: _validateProjectName,
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
                        validator: _validateProjectDescription,
                        decoration: InputDecoration(
                          labelText: 'Project Description',
                          hintText: 'Enter project description (optional)',
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
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _createProject(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Creating Project...'),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline),
                            SizedBox(width: 8),
                            Text('Create Project'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
