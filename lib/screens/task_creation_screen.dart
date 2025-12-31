/// Advanced task creation screen for comprehensive task management
/// Provides form validation, member assignment, and project integration
/// Includes modern UI with proper error handling and loading states
library;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/domain/entities/task_entity.dart';
import 'package:task_management/data/database_helper(task).dart';

class CreateTask extends StatefulWidget {
  const CreateTask({
    super.key,
    this.availableProjects = const [],
  });
  
  /// List of available projects for task assignment
  final List<String> availableProjects;

  @override
  _CreateTaskState createState() => _CreateTaskState();
}

class _CreateTaskState extends State<CreateTask> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for form fields
  final _taskNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // State variables
  DateTime _selectedDueDate = DateTime.now();
  String? _selectedMember;
  String? _selectedProjectId;
  List<String> _memberList = []; // Available team members
  bool _isLoading = false; // Loading state for operations
  String _errorMessage = ''; // Error message for user feedback
  
  // Priority levels for tasks
  final List<String> _priorityLevels = ['Low', 'Medium', 'High', 'Urgent'];
  String _selectedPriority = 'Medium';
  
  // Task categories
  final List<String> _categories = ['Work', 'Personal', 'Shopping', 'Health', 'Other'];
  String _selectedCategory = 'Work';
  
  // Database helper
  final TaskDatabase _taskDatabase = TaskDatabase();
  
  // Firestore references for fetching data
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference _projectsCollection = FirebaseFirestore.instance.collection('projects');

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    _initializeDefaultValues();
  }

  @override
  void dispose() {
    // Clean up controllers to prevent memory leaks
    _taskNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Initializes default values for form fields
  /// Sets up initial state for better UX
  void _initializeDefaultValues() {
    // Set default due date to tomorrow
    setState(() {
      _selectedDueDate = DateTime.now().add(const Duration(days: 1));
    });
  }

  /// Fetches available team members from Firestore
  /// Updates member list for assignment options
  Future<void> _fetchMembers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final QuerySnapshot usersSnapshot = await _usersCollection.limit(50).get();
      
      if (usersSnapshot.docs.isNotEmpty) {
        final List<String> users = usersSnapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return data?['name']?.toString() ?? data?['email']?.toString() ?? 'Unknown User';
            })
            .where((name) => name.isNotEmpty && name != 'Unknown User')
            .toList();
        
        if (mounted) {
          setState(() {
            _memberList = users.isNotEmpty ? users : ['No members available'];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _memberList = ['No members available'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to fetch members: ${e.toString()}';
          _memberList = ['Default User'];
          _isLoading = false;
        });
      }
    }
  }

  /// Builds comprehensive task creation interface
  /// Creates modern form with validation and error handling
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Modern app bar with save action
      appBar: _buildAppBar(context),
      // Main content with loading overlay
      body: Stack(
        children: [
          // Form content
          _buildFormContent(),
          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  /// Builds modern app bar
  /// Includes title, save action, and validation feedback
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Create Task',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      actions: [
        // Save button
        TextButton(
          onPressed: _canCreateTask() ? _createTask : null,
          child: const Text(
            'Save',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Builds main form content
  /// Creates scrollable form with all task fields
  Widget _buildFormContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message display
            if (_errorMessage.isNotEmpty) _buildErrorMessage(),
            // Task information card
            _buildTaskInformationCard(),
            const SizedBox(height: 16),
            // Task details card
            _buildTaskDetailsCard(),
            const SizedBox(height: 16),
            // Assignment card
            _buildAssignmentCard(),
            const SizedBox(height: 16),
            // Project card
            _buildProjectCard(),
            const SizedBox(height: 24),
            // Create button
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  /// Builds error message widget
  /// Shows error with dismiss option
  Widget _buildErrorMessage() {
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

  /// Builds task information card
  /// Contains title and description fields
  Widget _buildTaskInformationCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            // Task name field
            TextFormField(
              controller: _taskNameController,
              decoration: const InputDecoration(
                labelText: 'Task Name *',
                hintText: 'Enter task name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.task),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Task name is required';
                }
                if (value.trim().length < 3) {
                  return 'Task name must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Description field
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter task description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              validator: (value) {
                if (value != null && value.trim().length > 500) {
                  return 'Description must be less than 500 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds task details card
  /// Contains due date, priority, and category
  Widget _buildTaskDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            // Due date picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Due Date'),
              subtitle: Text(
                '${_selectedDueDate.day}/${_selectedDueDate.month}/${_selectedDueDate.year}',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: _selectDueDate,
            ),
            const Divider(),
            // Priority dropdown
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Priority'),
              subtitle: Text(_selectedPriority),
              trailing: DropdownButton<String>(
                value: _selectedPriority,
                items: _priorityLevels.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value!;
                  });
                },
              ),
            ),
            const Divider(),
            // Category dropdown
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Category'),
              subtitle: Text(_selectedCategory),
              trailing: DropdownButton<String>(
                value: _selectedCategory,
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds assignment card
  /// Contains member selection
  Widget _buildAssignmentCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assignment',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            // Member dropdown
            DropdownButtonFormField<String>(
              value: _selectedMember,
              decoration: const InputDecoration(
                labelText: 'Assign to *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              items: _memberList.map((member) {
                return DropdownMenuItem(
                  value: member,
                  child: Text(member),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMember = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a team member';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds project card
  /// Contains project selection
  Widget _buildProjectCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Project',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            // Project dropdown
            DropdownButtonFormField<String>(
              value: _selectedProjectId,
              decoration: const InputDecoration(
                labelText: 'Select Project *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.assignment),
              ),
              items: widget.availableProjects.map((project) {
                return DropdownMenuItem(
                  value: project,
                  child: Text(project),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProjectId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a project';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Creates task when pressed
  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _canCreateTask() ? _createTask : null,
      child: const Text('Create Task'),
    );
  }

  /// Builds loading overlay
  /// Shows loading indicator during operations
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Creating task...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Creates new task using TaskDatabase
  /// Validates form and saves task with proper error handling
  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedMember == null || _selectedProjectId == null) {
      setState(() {
        _errorMessage = 'Please select a member and project';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create new task object with proper TaskEntity structure
      final newTask = TaskEntity(
        id: '', // Will be generated by database
        title: _taskNameController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDueDate,
        assignedMembers: [_selectedMember!],
        assignedTo: _selectedMember!,
        projectId: _selectedProjectId!,
        attachments: const [],
        isCompleted: false,
        status: TaskStatus.todo,
        priority: _getTaskPriorityEnum(_selectedPriority),
        tags: [_selectedCategory],
        createdBy: _selectedMember!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save task using TaskDatabase
      final taskId = await _taskDatabase.addTask(newTask);
      
      // Update project with new task reference
      await _updateProjectTask(_selectedProjectId!, taskId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Show success message and navigate back
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to create task: ${e.toString()}';
        });
      }
    }
  }

  /// Converts priority string to TaskPriority enum
  TaskPriority _getTaskPriorityEnum(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.medium;
    }
  }

  /// Updates project with new task reference
  /// Maintains project-task relationship
  Future<void> _updateProjectTask(String projectId, String taskTitle) async {
    try {
      await _projectsCollection.doc(projectId).update({
        'lastUpdated': FieldValue.serverTimestamp(),
        'taskCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Failed to update project: $e');
    }
  }

  /// Shows date picker for due date selection
  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDueDate) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  /// Validates if task can be created
  bool _canCreateTask() {
    return !_isLoading &&
        _taskNameController.text.trim().isNotEmpty &&
        _selectedMember != null &&
        _selectedProjectId != null;
  }
}
