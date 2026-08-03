/// The one navigation surface for TaskHub.
///
/// Owns: the destination index, the in-shell push stack, and the single top
/// bar. Child screens are body-only widgets -- they must NOT return their own
/// Scaffold/AppBar, or the nested-app-bar problem comes back.
///
/// Breakpoint: 900px. Below = bottom NavigationBar. Above = labeled sidebar.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/authentication/authentication_service.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/screens/calendar_integration_screen.dart';
import 'package:task_management/screens/notification_screen.dart';
import 'package:task_management/screens/project_management_screen.dart';
import 'package:task_management/screens/search_screen.dart';
import 'package:task_management/screens/task_creation_screen.dart';
import 'package:task_management/screens/task_list_screen.dart';
import 'package:task_management/screens/team_management_screen.dart';
import 'package:task_management/screens/today_screen.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';

import 'app_destination.dart';

/// A body-only screen the shell can render and title.
abstract class ShellPage extends Widget {
  const ShellPage({super.key});
  String get title;
  String? get subtitle;
}

const double kShellBreakpoint = 900;

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.user,
    required this.userId,
    required this.isAdmin,
  });

  final CustomUser user;
  final String userId;
  final bool isAdmin;

  UserRole get role => UserRole.fromString(user.role);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  AppDestination _current = AppDestination.today;

  /// In-shell navigation stack (search, inbox). Pushing here keeps the shell
  /// chrome; detail screens and forms still use Navigator (see README).
  final List<Widget> _stack = [];

  List<AppDestination> get _destinations => destinationsFor(widget.role);

  void _select(AppDestination d) {
    setState(() {
      _current = d;
      _stack.clear();
    });
  }

  void push(Widget page) => setState(() => _stack.add(page));

  bool _pop() {
    if (_stack.isEmpty) return false;
    setState(_stack.removeLast);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= kShellBreakpoint;

    return PopScope(
      canPop: _stack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.shell,
        body: SafeArea(
          child: Row(
            children: [
              if (isDesktop)
                _Sidebar(
                  destinations: _destinations,
                  current: _current,
                  onSelect: _select,
                  userName: widget.user.displayName,
                  role: widget.role,
                  onInbox: () => push(const NotificationScreen()),
                  onLogout: _showLogoutConfirmation,
                ),
              Expanded(
                child: Column(
                  children: [
                    _TopBar(
                      title: _title,
                      subtitle: _subtitle,
                      showBack: _stack.isNotEmpty,
                      onBack: _pop,
                      isDesktop: isDesktop,
                      onSearch: () => push(const SearchScreen()),
                      onInbox: () => push(const NotificationScreen()),
                      onNewTask: _openNewTask,
                    ),
                    Expanded(
                      child: KeyedSubtree(
                        key: PageStorageKey(_stack.isEmpty ? _current : _stack.length),
                        child: _body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: isDesktop
            ? null
            : _BottomBar(
                destinations: _destinations,
                current: _current,
                onSelect: _select,
              ),
        floatingActionButton: isDesktop
            ? null
            : FloatingActionButton(
                backgroundColor: AppColors.terra,
                foregroundColor: AppColors.shell,
                onPressed: _openNewTask,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  void _openNewTask() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateTask(availableProjects: [])),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: Text('Are you sure you want to logout, ${widget.user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rust,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    try {
      await context.read<AuthenticationService>().signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e'), backgroundColor: AppColors.rust),
        );
      }
    }
  }

  Widget get _body {
    if (_stack.isNotEmpty) return _stack.last;
    return switch (_current) {
      AppDestination.today =>
        TodayScreen(currentUserId: widget.userId, role: widget.role),
      AppDestination.tasks => TaskListScreen(
          userId: widget.userId,
          user: widget.user,
          isAdmin: widget.isAdmin,
          tasks: const [],
        ),
      AppDestination.projects => ProjectManagementScreen(
          userId: widget.userId,
          user: widget.user,
          isAdmin: widget.isAdmin,
        ),
      AppDestination.teams =>
        TeamManagementScreen(userId: widget.userId, isAdmin: widget.isAdmin),
      AppDestination.calendar => const TaskCalendar(),
      AppDestination.inbox => const NotificationScreen(),
    };
  }

  String get _title {
    if (_stack.isNotEmpty && _stack.last is ShellPage) {
      return (_stack.last as ShellPage).title;
    }
    return _current.label;
  }

  String? get _subtitle {
    if (_stack.isNotEmpty && _stack.last is ShellPage) {
      return (_stack.last as ShellPage).subtitle;
    }
    return null;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.showBack,
    required this.onBack,
    required this.isDesktop,
    required this.onSearch,
    required this.onInbox,
    required this.onNewTask,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final VoidCallback onBack;
  final bool isDesktop;
  final VoidCallback onSearch;
  final VoidCallback onInbox;
  final VoidCallback onNewTask;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.edge)),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            _CircleButton(icon: Icons.arrow_back, onTap: onBack),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTheme.display(size: 22), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CircleButton(icon: Icons.search, onTap: onSearch),
          if (!isDesktop) ...[
            const SizedBox(width: 10),
            _CircleButton(icon: Icons.notifications, onTap: onInbox),
          ],
          if (isDesktop) ...[
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: onNewTask,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New task'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: AppColors.ink.withOpacity(0.06),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: Icon(icon, size: 21, color: AppColors.ink)),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.destinations,
    required this.current,
    required this.onSelect,
    required this.userName,
    required this.role,
    required this.onInbox,
    required this.onLogout,
  });

  final List<AppDestination> destinations;
  final AppDestination current;
  final ValueChanged<AppDestination> onSelect;
  final String userName;
  final UserRole role;
  final VoidCallback onInbox;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 224,
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.sand,
        border: Border(right: BorderSide(color: AppColors.edge)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(9, 8, 9, 16),
            child: Text('TaskHub', style: AppTheme.display(size: 20)),
          ),
          for (final d in destinations)
            _RailItem(
              destination: d,
              selected: d == current,
              onTap: () => onSelect(d),
            ),
          const Spacer(),
          _RailItem(
            destination: AppDestination.inbox,
            selected: false,
            onTap: onInbox,
          ),
          const Divider(height: 16),
          // User chip -- logout lives here now, not in the app bar.
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onLogout,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.avatarColor(userName),
                      shape: BoxShape.circle,
                    ),
                    child: Text(_initials(userName),
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.shell)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(userName,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(role.value,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.ink2)),
                      ],
                    ),
                  ),
                  const Icon(Icons.logout, size: 18, color: AppColors.ink2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((p) => p.isEmpty ? '' : p[0].toUpperCase())
      .join();
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AppDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: selected ? AppColors.paper : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        child: InkWell(
          borderRadius: BorderRadius.circular(99),
          onTap: onTap,
          hoverColor: AppColors.ink.withOpacity(0.07),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(selected ? destination.selectedIcon : destination.icon,
                    size: 21, color: selected ? AppColors.terra : AppColors.ink2),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? AppColors.ink : AppColors.ink2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.destinations,
    required this.current,
    required this.onSelect,
  });

  final List<AppDestination> destinations;
  final AppDestination current;
  final ValueChanged<AppDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    final index = destinations.indexOf(current);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.sand,
        border: Border(top: BorderSide(color: AppColors.edge)),
      ),
      child: NavigationBar(
        height: 64,
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.mint,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => onSelect(destinations[i]),
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon, color: AppColors.terra),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
