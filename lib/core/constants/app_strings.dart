/// App-wide string constants
class AppStrings {
  
  // Private constructor to prevent instantiation
  AppStrings._();
  // App Info
  static const String appName = 'Task Management';
  static const String appVersion = '1.0.0';
  
  // General
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String add = 'Add';
  static const String update = 'Update';
  static const String create = 'Create';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String refresh = 'Refresh';
  static const String retry = 'Retry';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String success = 'Success';
  static const String warning = 'Warning';
  static const String info = 'Info';
  
  // Auth
  static const String login = 'Login';
  static const String logout = 'Logout';
  static const String signUp = 'Sign Up';
  static const String signIn = 'Sign In';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String welcomeBack = 'Welcome Back!';
  static const String createAccount = 'Create Account';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String dontHaveAccount = "Don't have an account?";
  
  // Tasks
  static const String tasks = 'Tasks';
  static const String task = 'Task';
  static const String taskTitle = 'Task Title';
  static const String taskDescription = 'Task Description';
  static const String taskStatus = 'Task Status';
  static const String taskPriority = 'Task Priority';
  static const String taskDueDate = 'Due Date';
  static const String taskAssignedTo = 'Assigned To';
  static const String taskCreated = 'Task Created';
  static const String taskUpdated = 'Task Updated';
  static const String taskDeleted = 'Task Deleted';
  static const String createTask = 'Create Task';
  static const String updateTask = 'Update Task';
  static const String deleteTask = 'Delete Task';
  static const String noTasks = 'No tasks found';
  static const String noTasksDescription = 'You don\'t have any tasks yet. Create your first task to get started!';
  
  // Task Status
  static const String statusTodo = 'To Do';
  static const String statusInProgress = 'In Progress';
  static const String statusReview = 'Review';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';
  
  // Task Priority
  static const String priorityLow = 'Low';
  static const String priorityMedium = 'Medium';
  static const String priorityHigh = 'High';
  static const String priorityUrgent = 'Urgent';
  
  // Dashboard
  static const String dashboard = 'Dashboard';
  static const String goodMorning = 'Good Morning';
  static const String goodAfternoon = 'Good Afternoon';
  static const String goodEvening = 'Good Evening';
  static const String tasksDueToday = 'tasks due today';
  static const String completed = 'Completed';
  static const String inProgress = 'In Progress';
  static const String pending = 'Pending';
  static const String productivity = 'Productivity';
  static const String todaysTasks = "Today's Tasks";
  static const String recentActivity = 'Recent Activity';
  static const String seeAll = 'See All';
  
  // Projects
  static const String projects = 'Projects';
  static const String project = 'Project';
  static const String projectName = 'Project Name';
  static const String projectDescription = 'Project Description';
  static const String createProject = 'Create Project';
  static const String updateProject = 'Update Project';
  static const String deleteProject = 'Delete Project';
  static const String noProjects = 'No projects found';
  
  // Users
  static const String users = 'Users';
  static const String user = 'User';
  static const String userName = 'User Name';
  static const String userRole = 'User Role';
  static const String userAdmin = 'Admin';
  static const String userManager = 'Manager';
  static const String userRegular = 'Regular';
  
  // Notifications
  static const String notifications = 'Notifications';
  static const String notification = 'Notification';
  static const String noNotifications = 'No notifications';
  
  // Settings
  static const String settings = 'Settings';
  static const String profile = 'Profile';
  static const String about = 'About';
  static const String help = 'Help';
  static const String feedback = 'Feedback';
  
  // Error Messages
  static const String errorNetwork = 'No internet connection. Please check your network and try again.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorValidation = 'Please check your input and try again.';
  static const String errorAuth = 'Authentication failed. Please login again.';
  static const String errorNotFound = 'The requested resource was not found.';
  static const String errorUnknown = 'An unexpected error occurred. Please try again.';
  
  // Success Messages
  static const String successTaskCreated = 'Task created successfully!';
  static const String successTaskUpdated = 'Task updated successfully!';
  static const String successTaskDeleted = 'Task deleted successfully!';
  static const String successProjectCreated = 'Project created successfully!';
  static const String successProjectUpdated = 'Project updated successfully!';
  static const String successProjectDeleted = 'Project deleted successfully!';
  
  // Validation Messages
  static const String validationRequired = 'This field is required';
  static const String validationEmail = 'Please enter a valid email address';
  static const String validationPassword = 'Password must be at least 6 characters';
  static const String validationPasswordMatch = 'Passwords do not match';
  static const String validationTaskTitle = 'Task title is required';
  static const String validationTaskDescription = 'Task description is required';
  static const String validationProjectName = 'Project name is required';
  
  // Empty States
  static const String emptyStateTasks = 'No tasks yet';
  static const String emptyStateTasksDescription = 'Create your first task to get started!';
  static const String emptyStateProjects = 'No projects yet';
  static const String emptyStateProjectsDescription = 'Create your first project to organize your tasks!';
  static const String emptyStateSearch = 'No results found';
  static const String emptyStateSearchDescription = 'Try adjusting your search terms or filters';
  
  // Time Filters
  static const String filterDaily = 'Daily';
  static const String filterWeekly = 'Weekly';
  static const String filterMonthly = 'Monthly';
  
  // Days of week
  static const String monday = 'M';
  static const String tuesday = 'T';
  static const String wednesday = 'W';
  static const String thursday = 'T';
  static const String friday = 'F';
  static const String saturday = 'S';
  static const String sunday = 'S';
}
