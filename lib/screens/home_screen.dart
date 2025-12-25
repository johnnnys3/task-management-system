/// Main navigation screen for the task management application
/// Provides access to all major features through tabs and navigation
/// Handles user authentication and role-based access
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/authentication_service.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/screens/calendar_integration_screen.dart';
import 'package:task_management/screens/dashboard_screen.dart';
import 'package:task_management/screens/login_screen.dart';
import 'package:task_management/screens/notification_screen.dart';
import 'package:task_management/screens/project_management_screen.dart';
import 'package:task_management/screens/reporting_screen.dart';
import 'package:task_management/screens/search_screen.dart';
import 'package:task_management/screens/task_list_screen.dart';

class HomeScreen extends StatefulWidget {
  // User and session information
  final String userId; // Unique identifier for current user
  final CustomUser user; // User object with profile information
  final bool isAdmin; // Administrative privileges flag

  const HomeScreen({
    Key? key,
    required this.userId, 
    required this.user, 
    required this.isAdmin
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AuthenticationService authService; // Authentication service instance
  int _currentIndex = 0; // Current tab index for bottom navigation
  bool _isLoggingOut = false; // Loading state for logout process

  @override
  void initState() {
    super.initState();
    // Initialize authentication service without listening to changes
    authService = Provider.of<AuthenticationService>(context, listen: false);
  }

  /// Builds the main application interface
  /// Creates tabbed navigation with app bar and body content
  /// Includes user actions and logout functionality
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Two main tabs: Reports and Dashboard
      child: Scaffold(
        appBar: _buildAppBar(context), // Custom app bar with user info and actions
        body: TabBarView(
          // Tab content: Reports and Dashboard
          children: [
            ReportingScreen(), // Analytics and reports
            TaskStatsPage(), // Task statistics and management
          ],
        ),
        // Bottom navigation for quick access
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  /// Builds the application header with user information and actions
  /// Includes title, user profile, and navigation buttons
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          // App title/icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'TaskHub',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const Spacer(),
          // User information display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.user.name ?? 'User',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
              Text(
                widget.isAdmin ? 'Admin' : 'User',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      foregroundColor: Colors.white,
      // Primary navigation actions
      actions: [
        _buildNavigationButton(Icons.business, 'Projects', 'projectManagement'),
        _buildNavigationButton(Icons.notifications, 'Notifications', 'notification'),
        _buildNavigationButton(Icons.calendar_today, 'Calendar', 'calendar'),
        _buildNavigationButton(Icons.assignment, 'Tasks', 'taskList'),
        // Search button with direct navigation
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: 'Search Tasks',
          onPressed: () => _navigateToScreen(SearchScreen()),
        ),
        // Logout button with loading state
        _isLoggingOut
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => _showLogoutConfirmation(),
              ),
      ],
      // Tab navigation for main sections
      bottom: TabBar(
        tabs: const [
          Tab(
            icon: Icon(Icons.insert_chart),
            text: 'Reports',
          ),
          Tab(
            icon: Icon(Icons.dashboard),
            text: 'Dashboard',
          ),
        ],
        indicatorColor: Colors.white,
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }

  /// Builds navigation button with consistent styling and tooltips
  /// Provides visual feedback and proper navigation
  Widget _buildNavigationButton(IconData icon, String tooltip, String routeName) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () => _navigateToRoute(routeName),
    );
  }

  /// Handles navigation to different screens based on route name
  /// Passes user information to destination screens
  /// Includes error handling for invalid routes
  void _navigateToRoute(String routeName) {
    try {
      final screen = _buildRoute(routeName);
      if (screen is Scaffold && 
          (screen as Scaffold).body?.toString().contains('Invalid route name')) {
        _showErrorSnackBar('Navigation error: Invalid route');
        return;
      }
      _navigateToScreen(screen);
    } catch (e) {
      _showErrorSnackBar('Navigation failed: ${e.toString()}');
    }
  }

  /// Generic navigation method with error handling
  /// Wraps Navigator.push with try-catch for safety
  void _navigateToScreen(Widget screen) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    } catch (e) {
      _showErrorSnackBar('Navigation error: ${e.toString()}');
    }
  }

  /// Builds destination screen based on route name
  /// Includes proper parameter passing for each screen
  /// Returns error screen for invalid routes
  Widget _buildRoute(String routeName) {
    switch (routeName) {
      case 'notification':
        return const NotificationScreen();
      case 'calendar':
        return const TaskCalendar();
      case 'taskList':
        return TaskListScreen(
          userId: widget.userId, 
          user: widget.user, 
          isAdmin: widget.isAdmin, 
          tasks: [], // Will be populated by the screen itself
        );
      case 'projectManagement':
        return ProjectManagementScreen(
          userId: widget.userId, 
          isAdmin: widget.isAdmin, 
          user: widget.user
        );
      default:
        return Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
            backgroundColor: Colors.red,
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                Text(
                  'Invalid route: $routeName',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please contact support if this issue persists.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
    }
  }

  /// Shows confirmation dialog before logging out
  /// Prevents accidental logout and provides user feedback
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: Text('Are you sure you want to logout, ${widget.user.name ?? 'User'}?'),
        actions: [
          // Cancel button - stays logged in
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          // Logout button - proceeds with logout
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  /// Performs the actual logout operation
  /// Shows loading state and handles errors gracefully
  Future<void> _performLogout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      // Sign out from authentication service
      await authService.signOut();
      
      // Navigate to login screen and clear stack
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      // Handle logout errors
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
        _showErrorSnackBar('Logout failed: ${e.toString()}');
      }
    }
  }

  /// Builds bottom navigation bar for quick access
  /// Provides visual feedback for current tab
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
        ],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.7),
        backgroundColor: Colors.transparent,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }

  /// Shows error message in a snackbar
  /// Provides consistent error feedback across the app
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 4),
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
