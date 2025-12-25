 # Task Management System

A comprehensive Flutter application for managing tasks, projects, and teams with modern UI/UX and advanced features.

## 🚀 Features

### Core Functionality
- **Task Management**: Create, read, update, and delete tasks with rich metadata
- **Project Management**: Organize tasks into projects with progress tracking
- **Team Collaboration**: Assign tasks to team members with role-based permissions
- **Real-time Updates**: Live synchronization with Firebase backend
- **Advanced Search**: Filter and sort tasks by multiple criteria

### User Experience
- **Modern UI**: Material Design 3 with light/dark theme support
- **Responsive Design**: Optimized for mobile, tablet, and desktop
- **Accessibility**: WCAG compliant with proper semantic markup
- **Offline Support**: Local caching and synchronization when online
- **Push Notifications**: Task reminders and deadline alerts

### Advanced Features
- **Batch Operations**: Select and manage multiple tasks simultaneously
- **Priority Management**: Color-coded priority levels with visual indicators
- **Due Date Tracking**: Calendar integration with overdue warnings
- **Progress Analytics**: Visual charts and productivity insights
- **File Attachments**: Upload and manage task-related documents

## 🛠️ Installation

### Prerequisites
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Firebase account and project setup
- Android Studio / VS Code with Flutter extensions

### Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-repo/task-management.git
   cd task-management
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place files in respective platform folders
   - Run `flutterfire configure` to initialize Firebase

4. **Environment Setup**
   ```bash
   flutter doctor
   flutter devices
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

## 📱 Architecture

### Project Structure
```
lib/
├── authentication/          # Authentication services and screens
├── data/                 # Database helpers and data sources
├── models/                # Data models (Task, Project, User)
├── provider/              # State management with Provider pattern
├── screens/               # UI screens and components
├── service/               # Business logic and API services
└── widgets/               # Reusable UI components
```

### Data Flow
1. **Authentication**: Firebase Auth handles user login/registration
2. **State Management**: Provider pattern manages global application state
3. **Database**: Firestore stores tasks, projects, and user data
4. **Local Storage**: SQLite for offline data caching
5. **Synchronization**: Background service syncs local and remote data

### Key Components

#### Task Management
- **TaskCreationScreen**: Form for creating new tasks
- **TaskListScreen**: Display and manage task lists
- **TaskDetailsScreen**: View and edit individual tasks
- **UpdateTaskScreen**: Modify existing task properties

#### Project Management
- **ProjectListScreen**: Overview of all projects
- **UpdateProjectScreen**: Edit project details and settings

#### Team Features
- **TeamManagementScreen**: Manage team members and permissions
- **UserRoles**: Admin, member, and viewer access levels

## 🔧 Development

### Code Standards
- **Dart Style**: Follow official Dart style guide
- **Flutter Best Practices**: Use stateless widgets when possible
- **Error Handling**: Comprehensive try-catch blocks with user feedback
- **Testing**: Unit tests for business logic, widget tests for UI

### Key Technologies
- **Flutter**: Cross-platform UI framework
- **Firebase**: Backend services (Auth, Firestore, Storage)
- **Provider**: State management solution
- **Material Design 3**: Modern UI design system
- **SQLite**: Local database for offline support

### Screen Implementations

#### Task Creation Screen
```dart
import 'package:flutter/material.dart';
import 'package:task_management/data/database_helper(task).dart';
import 'package:task_management/models/task.dart';

class TaskCreationScreen extends StatefulWidget {
  @override
  _TaskCreationScreenState createState() => _TaskCreationScreenState();
}

class _TaskCreationScreenState extends State<TaskCreationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  DateTime selectedDueDate = DateTime.now();
  bool isLoading = false;
  int _lastId = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Task')),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              ListTile(
                title: Text('Due Date'),
                subtitle: Text(DateFormat.yMd().format(selectedDueDate)),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDueDate,
                    firstDate: DateTime.now(),
                  );
                  if (date != null) setState(() => selectedDueDate = date);
                },
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : () => _createTask(),
                child: isLoading 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Create Task'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => isLoading = true);
    
    try {
      final task = Task(
        id: (++_lastId).toString(),
        title: titleController.text,
        description: descriptionController.text,
        dueDate: selectedDueDate,
        isCompleted: false,
        createdAt: DateTime.now(),
      );
      
      await TaskDatabase().insertTask(task);
      Navigator.pop(context, task);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating task: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
```

## 🧪 Testing

### Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/task_test.dart

# Generate test coverage
flutter test --coverage
```

### Test Categories
- **Unit Tests**: Business logic and data models
- **Widget Tests**: UI components and screen layouts
- **Integration Tests**: End-to-end user flows

## 📦 Build & Deployment

### Development Build
```bash
flutter build apk --debug
flutter build ios --debug
```

### Production Build
```bash
flutter build apk --release
flutter build ios --release
```

### Web Deployment
```bash
flutter build web
```

## 🔧 Configuration

### Environment Variables
Create `.env` file in project root:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

### Firebase Configuration
- Enable Authentication (Email/Password, Google Sign-In)
- Configure Firestore database rules
- Set up Storage for file uploads
- Configure Cloud Functions for backend logic

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Review Guidelines
- Ensure code follows style guidelines
- Add tests for new functionality
- Update documentation as needed
- Verify all tests pass before merging


## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Check the [documentation](docs/) for detailed guides
- Review the [FAQ](docs/FAQ.md) for common questions
