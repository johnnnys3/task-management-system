/// Modern home screen with enhanced UI design
/// Features modern tab navigation, dashboard cards, and improved visual hierarchy
/// Implements purple productivity theme with contemporary design patterns
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/authentication_service.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/screens/dashboard_screen.dart';
import 'package:task_management/screens/login_screen.dart';
import 'package:task_management/screens/notification_screen.dart';
import 'package:task_management/screens/reporting_screen.dart';
import 'package:task_management/screens/task_list_screen.dart';
import 'package:task_management/screens/calendar_integration_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  final CustomUser user;
  final bool isAdmin;

  const HomeScreen({
    super.key,
    required this.userId, 
    required this.user, 
    required this.isAdmin
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AuthenticationService authService;
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    authService = Provider.of<AuthenticationService>(context, listen: false);
    
    _tabController = TabController(length: 3, vsync: this);
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  /// Builds modern app bar with user profile and actions
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'TaskFlow',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          Text(
            'Welcome back, ${widget.user.name.split(' ').first}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        _buildNotificationButton(),
        _buildUserMenuButton(),
      ],
      bottom: _buildTabBar(),
    );
  }

  /// Builds modern notification button with badge
  Widget _buildNotificationButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationScreen()),
              );
            },
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds modern user menu button
  Widget _buildUserMenuButton() {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      child: PopupMenuButton<String>(
        icon: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        onSelected: (value) {
          if (value == 'logout') {
            _handleLogout();
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'profile',
            child: Row(
              children: [
                Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Profile'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'settings',
            child: Row(
              children: [
                Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Settings'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'divider',
            enabled: false,
            child: Divider(),
          ),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                Icon(Icons.logout_outlined, color: Colors.red[400]),
                const SizedBox(width: 12),
                Text('Logout', style: TextStyle(color: Colors.red[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds modern tab bar with enhanced styling
  PreferredSizeWidget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      ),
      labelColor: Theme.of(context).colorScheme.primary,
      unselectedLabelColor: Colors.grey[600],
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      tabs: const [
        Tab(
          icon: Icon(Icons.dashboard_outlined),
          text: 'Dashboard',
        ),
        Tab(
          icon: Icon(Icons.task_outlined),
          text: 'Tasks',
        ),
        Tab(
          icon: Icon(Icons.analytics_outlined),
          text: 'Reports',
        ),
      ],
    );
  }

  /// Builds modern floating action button
  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to task creation based on current tab
            switch (_tabController.index) {
              case 0: // Dashboard
                _showQuickActionMenu();
                break;
              case 1: // Tasks
                _navigateToTaskCreation();
                break;
              case 2: // Reports
                _navigateToReportCreation();
                break;
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Icon(
            _getFabIcon(),
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  /// Gets appropriate icon for FAB based on current tab
  IconData _getFabIcon() {
    switch (_tabController.index) {
      case 0:
        return Icons.add;
      case 1:
        return Icons.add_task;
      case 2:
        return Icons.add_chart;
      default:
        return Icons.add;
    }
  }

  /// Shows quick action menu for dashboard
  void _showQuickActionMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            _buildQuickActionItem(
              icon: Icons.add_task,
              title: 'Create Task',
              subtitle: 'Add a new task to your list',
              onTap: () {
                Navigator.pop(context);
                _navigateToTaskCreation();
              },
            ),
            _buildQuickActionItem(
              icon: Icons.create_new_folder,
              title: 'Create Project',
              subtitle: 'Start a new project',
              onTap: () {
                Navigator.pop(context);
                _navigateToProjectCreation();
              },
            ),
            _buildQuickActionItem(
              icon: Icons.calendar_today,
              title: 'Schedule Event',
              subtitle: 'Add to your calendar',
              onTap: () {
                Navigator.pop(context);
                _navigateToCalendar();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds quick action item for bottom sheet
  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Navigates to task creation screen
  void _navigateToTaskCreation() {
    // Navigate to task creation screen
    // Implementation depends on your task creation screen
  }

  /// Navigates to project creation screen
  void _navigateToProjectCreation() {
    // Navigate to project creation screen
    // Implementation depends on your project creation screen
  }

  /// Navigates to calendar
  void _navigateToCalendar() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TaskCalendar()),
    );
  }

  /// Navigates to report creation
  void _navigateToReportCreation() {
    // Navigate to report creation screen
    // Implementation depends on your report creation screen
  }

  /// Handles logout with enhanced UI feedback
  Future<void> _handleLogout() async {
    try {
      await authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: ${e.toString()}'),
            backgroundColor: Colors.red[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          const TaskStatsPage(),
          // Tasks Tab
          TaskListScreen(
            userId: widget.userId,
            user: widget.user,
            isAdmin: widget.isAdmin,
            tasks: [], // Empty initial list, will be loaded by the screen
          ),
          // Reports Tab
          const ReportingScreen(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }
}
