/// Notification screen for displaying task-related alerts and updates
/// Provides comprehensive notification management with filtering and actions
/// Includes real-time updates and user interaction features
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/widgets/pill_button.dart';
import 'package:task_management/navigation/app_shell.dart';
import 'task_details_screen.dart';

/// Enum for notification types
/// Classifies different notification categories
enum NotificationType {
  taskDue,
  taskOverdue,
  taskCompleted,
  taskAssigned,
  taskUpdated,
}

/// Model class for notification data
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final Task? relatedTask;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.relatedTask,
  });

  /// Creates a notification from a task
  factory NotificationItem.fromTask(Task task) {
    final now = DateTime.now();
    
    if (task.isCompleted) {
      return NotificationItem(
        id: 'completed_${task.id}',
        title: 'Task Completed',
        message: 'You have completed "${task.title}"',
        type: NotificationType.taskCompleted,
        timestamp: task.updatedAt ?? now,
        isRead: false,
        relatedTask: task,
      );
    } else if (task.dueDate != null && task.dueDate!.isBefore(now)) {
      return NotificationItem(
        id: 'overdue_${task.id}',
        title: 'Task Overdue',
        message: '"${task.title}" is overdue by ${now.difference(task.dueDate!).inDays} days',
        type: NotificationType.taskOverdue,
        timestamp: now,
        isRead: false,
        relatedTask: task,
      );
    } else if (task.dueDate != null && task.dueDate!.difference(now).inDays <= 1) {
      return NotificationItem(
        id: 'due_${task.id}',
        title: 'Task Due Soon',
        message: '"${task.title}" is due ${DateFormat.jm().format(task.dueDate!)} today',
        type: NotificationType.taskDue,
        timestamp: now,
        isRead: false,
        relatedTask: task,
      );
    } else {
      return NotificationItem(
        id: 'updated_${task.id}',
        title: 'Task Updated',
        message: '"${task.title}" has been updated',
        type: NotificationType.taskUpdated,
        timestamp: task.updatedAt ?? now,
        isRead: false,
        relatedTask: task,
      );
    }
  }
}

class NotificationScreen extends StatefulWidget implements ShellPage {
  const NotificationScreen({super.key});

  @override
  String get title => 'Inbox';

  @override
  String? get subtitle => null;

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // State management
  late final TaskStore _taskStore;
  List<NotificationItem> _notifications = [];
  List<NotificationItem> _filteredNotifications = [];
  bool _isLoading = true;
  String _errorMessage = '';
  NotificationType? _selectedFilter;
  bool _showUnreadOnly = false;
  
  @override
  void initState() {
    super.initState();
    _taskStore = context.read<TaskStore>();
    _loadNotifications();
  }

  /// Loads notifications from database
  /// Converts tasks to notification items and handles errors
  Future<void> _loadNotifications() async {
    try {
      // Fetch tasks from database
      List<Task> tasks = await _taskStore.fetch();
      
      // Convert tasks to notification items
      final notifications = tasks.map((task) => NotificationItem.fromTask(task)).toList();
      
      // Sort notifications by timestamp (newest first)
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _filteredNotifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load notifications: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Builds the main notification interface
  /// Creates modern layout with filtering and management features
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            _buildFilterHeader(),
            Expanded(child: _isLoading ? _buildLoadingWidget() : _buildNotificationList()),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: _clearAllNotifications,
            backgroundColor: Theme.of(context).primaryColor,
            tooltip: 'Clear All Notifications',
            child: const Icon(Icons.clear_all, color: Colors.white),
          ),
        ),
      ],
    );
  }

  /// Filter menu, unread toggle, and mark-all-read -- previously app bar actions.
  Widget _buildFilterHeader() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8, right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.rust,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          const Spacer(),
          PopupMenuButton<NotificationType>(
            icon: const Icon(Icons.filter_list, color: AppColors.ink2),
            tooltip: 'Filter Notifications',
            onSelected: (NotificationType? type) {
              setState(() {
                _selectedFilter = type;
                _applyFilter();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Notifications')),
              const PopupMenuItem(value: NotificationType.taskDue, child: Text('Due Soon')),
              const PopupMenuItem(value: NotificationType.taskOverdue, child: Text('Overdue')),
              const PopupMenuItem(value: NotificationType.taskCompleted, child: Text('Completed')),
            ],
          ),
          IconButton(
            icon: Icon(_showUnreadOnly ? Icons.mark_email_read : Icons.email, color: AppColors.ink2),
            tooltip: _showUnreadOnly ? 'Show All' : 'Show Unread Only',
            onPressed: () {
              setState(() {
                _showUnreadOnly = !_showUnreadOnly;
                _applyFilter();
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: PillButton(
              label: 'Mark all read',
              outlined: true,
              onPressed: unreadCount > 0 ? _markAllAsRead : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds loading widget with modern styling
  /// Shows centered loading indicator with message
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.terra),
          ),
          SizedBox(height: 16),
          Text(
            'Loading notifications...',
            style: TextStyle(
              color: AppColors.ink2,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the main notification list
  /// Displays filtered notifications with proper styling
  Widget _buildNotificationList() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }
    
    if (_filteredNotifications.isEmpty) {
      return _buildEmptyState();
    }
    
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = _filteredNotifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  /// Builds individual notification card
  /// Includes status indicators and action buttons
  Widget _buildNotificationCard(NotificationItem notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 0,
      color: notification.isRead ? AppColors.paper : AppColors.sand,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _handleNotificationTap(notification),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon and status
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ink2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTimestamp(notification.timestamp),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.ink3,
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Column(
                children: [
                  if (!notification.isRead)
                    IconButton(
                      icon: const Icon(Icons.mark_email_read, size: 20, color: AppColors.ink2),
                      tooltip: 'Mark as Read',
                      onPressed: () => _markAsRead(notification),
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: AppColors.ink2),
                    tooltip: 'More Options',
                    onPressed: () => _showNotificationMenu(notification),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds error state widget
  /// Shows error message with retry option
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.rust,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadNotifications,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Builds empty state widget
  /// Shows message when no notifications are available
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.notifications_none,
            size: 64,
            color: AppColors.ink3,
          ),
          const SizedBox(height: 16),
          const Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _showUnreadOnly
                ? 'No unread notifications to display'
                : 'You\'re all caught up!',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilter() {
    if (_selectedFilter != null) {
      _filteredNotifications = _notifications.where((n) => n.type == _selectedFilter).toList();
    } else {
      _filteredNotifications = _notifications;
    }

    if (_showUnreadOnly) {
      _filteredNotifications = _filteredNotifications.where((n) => !n.isRead).toList();
    }
  }

  void _clearAllNotifications() {
    setState(() {
      _notifications = [];
      _filteredNotifications = [];
    });
  }

  void _handleNotificationTap(NotificationItem notification) {
    if (notification.relatedTask != null) {
      _navigateToTaskDetails(notification.relatedTask!);
    }
  }

  void _markAsRead(NotificationItem notification) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          type: notification.type,
          timestamp: notification.timestamp,
          isRead: true,
          relatedTask: notification.relatedTask,
        );
      }
    });
  }

  /// Marks every notification as read
  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications
          .map((n) => NotificationItem(
                id: n.id,
                title: n.title,
                message: n.message,
                type: n.type,
                timestamp: n.timestamp,
                isRead: true,
                relatedTask: n.relatedTask,
              ))
          .toList();
      _applyFilter();
    });
  }

  void _navigateToTaskDetails(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(task: task),
      ),
    );
  }

  void _showNotificationMenu(NotificationItem notification) {
    // Implement notification menu
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.taskDue:
        return AppColors.statusReview;
      case NotificationType.taskOverdue:
        return AppColors.rust;
      case NotificationType.taskCompleted:
        return AppColors.sage;
      case NotificationType.taskAssigned:
        return AppColors.terra;
      case NotificationType.taskUpdated:
        return AppColors.ink2;
      }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.taskDue:
        return Icons.timer;
      case NotificationType.taskOverdue:
        return Icons.error;
      case NotificationType.taskCompleted:
        return Icons.check;
      case NotificationType.taskAssigned:
        return Icons.person;
      case NotificationType.taskUpdated:
        return Icons.update;
      }
  }

  String _formatTimestamp(DateTime timestamp) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
  }
}
