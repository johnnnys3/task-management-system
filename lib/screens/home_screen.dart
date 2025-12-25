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
  final String userId;
  final CustomUser user;
  final bool isAdmin;

  HomeScreen({required this.userId, required this.user, required this.isAdmin});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AuthenticationService authService;

  @override
  void initState() {
    super.initState();
    authService = Provider.of<AuthenticationService>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Task Management'),
          actions: [
            _buildIconButton(Icons.business, 'projectManagement'),
            _buildIconButton(Icons.notifications, 'notification'),
            _buildIconButton(Icons.calendar_today, 'calendar'),
            _buildIconButton(Icons.assignment, 'taskList'),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
            ),
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _logout();
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.insert_chart)),
              Tab(icon: Icon(Icons.dashboard)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ReportingScreen(),
            TaskStatsPage(),
          ],
        ),
      ),
    );
  }

  IconButton _buildIconButton(IconData icon, String routeName) {
    return IconButton(
      icon: Icon(icon),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => _buildRoute(routeName)),
        );
      },
    );
  }

  Widget _buildRoute(String routeName) {
    switch (routeName) {
      case 'notification':
        return NotificationScreen();
      case 'calendar':
        return TaskCalendar();
      case 'taskList':
        return TaskListScreen(userId: widget.userId, user: widget.user, isAdmin: widget.isAdmin, tasks: [],);
      case 'projectManagement':
        return ProjectManagementScreen(userId: widget.userId, isAdmin: widget.isAdmin, user: widget.user);
      default:
        return Scaffold(
          appBar: AppBar(title: Text('Error')),
          body: Center(child: Text('Invalid route name')),
        );
    }
  }

  void _logout() async {
    await authService.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }
}
