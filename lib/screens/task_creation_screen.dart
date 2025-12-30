/// Advanced task creation screen for comprehensive task management
/// Provides form validation, member assignment, and project integration
/// Includes modern UI with proper error handling and loading states
library;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:task_management/models/project.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/models/task_list_notifier.dart';

class CreateTask extends StatefulWidget {
  /// List of available projects for task assignment
  final List<String> availableProjects;

  const CreateTask({
    super.key,
    required this.availableProjects,
  });

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
  String? _selectedProjectName;
  List<String> _memberList = []; // Available team members
  bool _isLoading = false; // Loading state for operations
  String _errorMessage = ''; // Error message for user feedback
  
  // Priority levels for tasks
  final List<String> _priorityLevels = ['Low', 'Medium', 'High', 'Urgent'];
  String _selectedPriority = 'Medium';
  
  // Task categories
  final List<String> _categories = ['Work', 'Personal', 'Shopping', 'Health', 'Other'];
  String _selectedCategory = 'Work';
  
  // Firestore references
  final CollectionReference _tasksCollection = FirebaseFirestore.instance.collection('tasks');
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
      
      final QuerySnapshot usersSnapshot = await _usersCollection.get();
      
      if (usersSnapshot.docs.isNotEmpty) {
        final List<String> users = usersSnapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>?)?['name']?.toString() ?? 'Unknown')
            .where((name) => name.isNotEmpty && name != 'Unknown')
            .toList();
        
        if (mounted) {
          setState(() {
            _memberList = users;
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

  /// Builds loading overlay
  /// Shows loading indicator during operations
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Creating task...'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Builds task information card
  /// Includes task name, description, and due date
  Widget _buildTaskInformationCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Task Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taskNameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a task name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Task Description',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Due Date: '),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDueDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null && pickedDate != _selectedDueDate) {
                      setState(() {
                        _selectedDueDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    "${_selectedDueDate.toLocal()}".split(' ')[0],
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds task details card
  /// Includes task priority and category
  Widget _buildTaskDetailsCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Task Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Priority',
              ),
              items: _priorityLevels
                  .map((priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      ))
                  .toList(),
              initialValue: _selectedPriority,
              onChanged: (value) {
                setState(() {
                  _selectedPriority = value as String;
                });
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Category',
              ),
              items: _categories
                  .map((category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ))
                  .toList(),
              initialValue: _selectedCategory,
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value as String;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds assignment card
  /// Includes member selection
  Widget _buildAssignmentCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Assign Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_selectedMember ?? 'Select Member'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _selectMember(context);
                  },
                  child: const Text('Choose'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds project card
  /// Includes project selection
  Widget _buildProjectCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Project Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_selectedProjectName ?? 'Select Project'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _selectProject(context);
                  },
                  child: const Text('Choose'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds create button
  /// Creates task when pressed
  Widget _buildCreateButton() {
    return ElevatedButton(
      onPressed: _canCreateTask() ? _createTask : null,
      child: const Text('Create Task'),
    );
  }

  /// Checks if task can be created
  /// Validates form and checks for member and project selection
  bool _canCreateTask() {
    return _formKey.currentState!.validate() &&
        _selectedMember != null &&
        _selectedProjectId != null;
  }

  /// Shows member selection modal
  /// Displays available team members for assignment
  void _selectMember(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Team Member',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Member list
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _memberList.length,
                  itemBuilder: (context, index) {
                    final member = _memberList[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        child: Text(
                          member.isNotEmpty ? member[0].toUpperCase() : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(member),
                      trailing: _selectedMember == member
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedMember = member;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Shows project selection modal
  /// Displays available projects for task assignment
  void _selectProject(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Project',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Project list
              SizedBox(
                height: 300,
                child: FutureBuilder<List<Project>>(
                  future: _fetchAvailableProjects(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading projects: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    
                    final projects = snapshot.data ?? [];
                    return ListView.builder(
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(
                              Icons.folder,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(project.name),
                          subtitle: project.description.isNotEmpty
                              ? Text(
                                  project.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                          trailing: _selectedProjectId == project.id
                              ? const Icon(Icons.check, color: Colors.green)
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedProjectId = project.id;
                              _selectedProjectName = project.name;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Fetches available projects from Firestore
  /// Returns list of projects for selection
  Future<List<Project>> _fetchAvailableProjects() async {
    try {
      final QuerySnapshot result = await _projectsCollection.get();
      final List<DocumentSnapshot> documents = result.docs;

      List<Project> projects = documents.map((doc) {
        final Timestamp? dueDateTimestamp = doc['dueDate'] as Timestamp?;
        final DateTime dueDate = dueDateTimestamp?.toDate() ?? DateTime.now();

        return Project(
          id: doc.id,
          name: doc['name'] ?? '',
          description: doc['description'] ?? '',
          dueDate: dueDate,
          tasks: [],
          isCompleted: false,
        );
      }).toList();

      return projects;
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching projects: ${e.toString()}';
      });
      return [];
    }
  }

  /// Creates new task in Firestore
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
      // Create new task object
      final newTask = Task(
        id: DateTime.now().toIso8601String(),
        title: _taskNameController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _selectedDueDate,
        assignedMembers: [_selectedMember!],
        associatedProject: Project(
          id: _selectedProjectId!,
          name: _selectedProjectName ?? _selectedProjectId!,
          description: '',
          dueDate: DateTime.now(),
          tasks: [],
          isCompleted: false,
        ),
        attachments: [],
        isCompleted: false,
      );

      // Save task to Firestore
      await _tasksCollection.add(newTask.toMap());
      
      // Update project with new task
      await _updateProjectTask(_selectedProjectId!, newTask.title);
      
      // Update local state
      Provider.of<TaskListNotifier>(context, listen: false).addTask(newTask);
      
      // Show success message
      _showSuccessSnackBar('Task created successfully!');
      
      // Return to previous screen with task data
      Navigator.pop(context, newTask);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to create task: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Updates project with new task reference
  /// Maintains project-task relationship
  Future<void> _updateProjectTask(String projectId, String taskTitle) async {
    try {
      await _projectsCollection.doc(projectId).update({
        'tasks': FieldValue.arrayUnion([
          {
            'title': taskTitle,
            'projectId': projectId,
            'createdAt': FieldValue.serverTimestamp(),
          }
        ]),
      });
    } catch (e) {
      // Log error but don't fail task creation
      print('Error updating project task: $e');
    }
  }

  /// Shows success snackbar message
  /// Provides positive feedback for successful operations
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
        backgroundColor: Colors.green[600],
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
}
