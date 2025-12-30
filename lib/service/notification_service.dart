/// Notification service for sending email notifications
/// Handles task and project due date reminders
library;
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_management/models/task.dart' as TaskModel;
import 'package:task_management/models/project.dart' as ProjectModel;

class NotificationService {
  static final Logger _logger = Logger('NotificationService');
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _notificationTimer;

  /// Initializes the notification service
  /// Sets up any required initial state
  Future<void> initialize() async {
    // Can be used for one-time setup if needed
    _logger.info('Notification service initialized');
  }

  /// Starts the notification scheduler
  /// Should be called during app initialization
  Future<void> startNotificationScheduler() async {
    try {
      // Trigger initial check for any immediate notifications
      await triggerDueDateCheck();
      
      // Set up hourly timer to check for upcoming due dates
      _notificationTimer?.cancel();
      _notificationTimer = Timer.periodic(const Duration(hours: 1), (timer) {
        _checkUpcomingDueDates();
      });
      
      _logger.info('Notification scheduler started');
    } catch (e) {
      _logger.severe('Error starting notification scheduler', e);
      rethrow;
    }
  }

  /// Stops the notification scheduler
  void stopNotificationScheduler() {
    _notificationTimer?.cancel();
    _logger.info('Notification scheduler stopped');
  }

  /// Checks for tasks and projects due in 3 days
  Future<void> _checkUpcomingDueDates() async {
    try {
      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));
      final startOfTargetDay = DateTime(
        threeDaysFromNow.year,
        threeDaysFromNow.month,
        threeDaysFromNow.day,
      );
      final endOfTargetDay = startOfTargetDay.add(const Duration(days: 1));

      // Check for tasks due in 3 days
      await _checkTasksDueInDateRange(startOfTargetDay, endOfTargetDay);
      
      // Check for projects due in 3 days
      await _checkProjectsDueInDateRange(startOfTargetDay, endOfTargetDay);
      
    } catch (e) {
      _logger.severe('Error checking upcoming due dates', e);
    }
  }

  /// Checks for tasks due within the specified date range
  Future<void> _checkTasksDueInDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('dueDate', isGreaterThanOrEqualTo: startDate)
          .where('dueDate', isLessThan: endDate)
          .where('isCompleted', isEqualTo: false)
          .get();

      for (final doc in tasksQuery.docs) {
        final task = TaskModel.Task.fromMap(doc.data(), doc.id);
        await _sendTaskDueNotification(task);
      }
    } catch (e) {
      _logger.warning('Error checking tasks due in date range', e);
    }
  }

  /// Checks for projects due within the specified date range
  Future<void> _checkProjectsDueInDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final projectsQuery = await _firestore
          .collection('projects')
          .where('dueDate', isGreaterThanOrEqualTo: startDate)
          .where('dueDate', isLessThan: endDate)
          .where('isCompleted', isEqualTo: false)
          .get();

      for (final doc in projectsQuery.docs) {
        final project = ProjectModel.Project.fromMap(doc.data(), doc.id);
        await _sendProjectDueNotification(project);
      }
    } catch (e) {
      _logger.warning('Error checking projects due in date range', e);
    }
  }

  /// Sends notification for task due in 3 days
  Future<void> _sendTaskDueNotification(TaskModel.Task task) async {
    try {
      // Get assigned users for the task
      final assignedUsers = await _getAssignedUsers(task.id, 'task');
      
      for (final user in assignedUsers) {
        final email = user['email'];
        final name = user['name'];
        if (email != null && email.isNotEmpty) {
          await _sendEmailNotification(
            email: email,
            subject: 'Task Due Reminder: ${task.title}',
            body: _buildTaskDueEmailBody(task, name ?? 'User'),
          );
        }
      }
      
      _logger.info('Sent due notification for task: ${task.title}');
    } catch (e) {
      _logger.warning('Error sending task due notification', e);
    }
  }

  /// Sends notification for project due in 3 days
  Future<void> _sendProjectDueNotification(ProjectModel.Project project) async {
    try {
      // Get assigned users for the project
      final assignedUsers = await _getAssignedUsers(project.id, 'project');
      
      for (final user in assignedUsers) {
        final email = user['email'];
        final name = user['name'];
        if (email != null && email.isNotEmpty) {
          await _sendEmailNotification(
            email: email,
            subject: 'Project Due Reminder: ${project.name}',
            body: _buildProjectDueEmailBody(project, name ?? 'User'),
          );
        }
      }
      
      _logger.info('Sent due notification for project: ${project.name}');
    } catch (e) {
      _logger.warning('Error sending project due notification', e);
    }
  }

  /// Gets assigned users for a task or project
  Future<List<Map<String, String>>> _getAssignedUsers(String itemId, String itemType) async {
    try {
      final assignedUsers = <Map<String, String>>[];
      
      // Get users assigned to this item
      final assignmentsQuery = await _firestore
          .collection('assignments')
          .where(itemType + 'Id', isEqualTo: itemId)
          .get();

      for (final assignmentDoc in assignmentsQuery.docs) {
        final userId = assignmentDoc.data()['userId'] as String;
        
        // Get user details
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          assignedUsers.add({
            'id': userId,
            'name': userData['name'] ?? 'User',
            'email': userData['email'] ?? '',
          });
        }
      }
      
      return assignedUsers;
    } catch (e) {
      _logger.warning('Error getting assigned users for $itemType $itemId', e);
      return [];
    }
  }

  /// Builds email body for task due notification
  String _buildTaskDueEmailBody(TaskModel.Task task, String userName) {
    final dueDate = task.dueDate;
    final formattedDate = dueDate != null 
        ? '${dueDate.day}/${dueDate.month}/${dueDate.year}'
        : 'No due date set';
    
    return '''
Dear $userName,

This is a friendly reminder that your task "${task.title}" is due in 3 days on $formattedDate.

Task Details:
- Title: ${task.title}
- Description: ${task.description}
- Priority: ${task.priority.name}
- Due Date: $formattedDate

Please make sure to complete this task before the due date.

Best regards,
Task Management System
    ''';
  }

  /// Builds email body for project due notification
  String _buildProjectDueEmailBody(ProjectModel.Project project, String userName) {
    final dueDate = project.dueDate;
    final formattedDate = dueDate != null 
        ? '${dueDate.day}/${dueDate.month}/${dueDate.year}'
        : 'No due date set';
    
    return '''
Dear $userName,

This is a friendly reminder that your project "${project.name}" is due in 3 days on $formattedDate.

Project Details:
- Name: ${project.name}
- Description: ${project.description}
- Status: ${project.status}
- Due Date: $formattedDate

Please make sure to complete this project before the due date.

Best regards,
Task Management System
    ''';
  }

  /// Sends email notification (placeholder implementation)
  /// In a real implementation, this would integrate with an email service
  /// like Firebase Cloud Functions, SendGrid, or AWS SES
  Future<void> _sendEmailNotification({
    required String email,
    required String subject,
    required String body,
  }) async {
    try {
      // TODO: Implement actual email sending
      // For now, we'll just log the notification
      _logger.info('Email notification (not sent - placeholder implementation):');
      _logger.info('To: $email');
      _logger.info('Subject: $subject');
      final bodyPreview = body.length > 100 ? '${body.substring(0, 100)}...' : body;
      _logger.info('Body preview: $bodyPreview');
      
      // In a real implementation, you would:
      // 1. Call a Firebase Cloud Function that sends emails
      // 2. Use an email service API like SendGrid
      // 3. Use Firebase Extensions for email sending
      
      // Example Cloud Function call:
      // await _firestore.collection('mail').add({
      //   'to': email,
      //   'subject': subject,
      //   'text': body,
      //   'createdAt': FieldValue.serverTimestamp(),
      // });
      
    } catch (e) {
      _logger.severe('Error sending email notification to $email', e);
      rethrow;
    }
  }

  /// Manually triggers a check for upcoming due dates
  /// Useful for testing or immediate notifications
  Future<void> triggerDueDateCheck() async {
    await _checkUpcomingDueDates();
  }

  /// Sends a custom notification to specific users
  Future<void> sendCustomNotification({
    required List<String> userIds,
    required String subject,
    required String body,
  }) async {
    try {
      for (final userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final email = userData['email'] as String?;
          
          if (email != null && email.isNotEmpty) {
            await _sendEmailNotification(
              email: email,
              subject: subject,
              body: body,
            );
          }
        }
      }
    } catch (e) {
      _logger.severe('Error sending custom notification', e);
      rethrow;
    }
  }

  /// Disposes the notification service
  void dispose() {
    stopNotificationScheduler();
  }
}
