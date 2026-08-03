/// Single source of truth for TaskHub's navigation destinations.
///
/// Replaces the old triple system (TabBar + BottomNavigationBar + app-bar
/// icon buttons). Anything that used to be an app-bar IconButton is either a
/// destination here, or a fixed affordance in the shell top bar (search),
/// or reachable from a destination.
import 'package:flutter/material.dart';
import 'package:task_management/authentication/user.dart' show UserRole;

enum AppDestination { today, tasks, projects, teams, calendar, inbox }

extension AppDestinationX on AppDestination {
  String get label => switch (this) {
        AppDestination.today => 'Today',
        AppDestination.tasks => 'Tasks',
        AppDestination.projects => 'Projects',
        AppDestination.teams => 'Teams',
        AppDestination.calendar => 'Calendar',
        AppDestination.inbox => 'Inbox',
      };

  IconData get icon => switch (this) {
        AppDestination.today => Icons.today_outlined,
        AppDestination.tasks => Icons.checklist_rounded,
        AppDestination.projects => Icons.folder_outlined,
        AppDestination.teams => Icons.group_outlined,
        AppDestination.calendar => Icons.calendar_month_outlined,
        AppDestination.inbox => Icons.notifications_outlined,
      };

  IconData get selectedIcon => switch (this) {
        AppDestination.today => Icons.today,
        AppDestination.tasks => Icons.checklist_rounded,
        AppDestination.projects => Icons.folder,
        AppDestination.teams => Icons.group,
        AppDestination.calendar => Icons.calendar_month,
        AppDestination.inbox => Icons.notifications,
      };

  /// Members (`UserRole.regular`) have no org-wide view, so Teams disappears
  /// for them entirely -- nav item and route both. This is the one place
  /// that rule lives.
  bool visibleTo(UserRole role) =>
      !(this == AppDestination.teams && role == UserRole.regular);
}

/// Bottom-bar / sidebar order. Inbox is deliberately NOT here: on desktop it
/// is pinned below the destination list, on mobile it is a top-bar icon.
const kPrimaryDestinations = [
  AppDestination.today,
  AppDestination.tasks,
  AppDestination.projects,
  AppDestination.teams,
  AppDestination.calendar,
];

List<AppDestination> destinationsFor(UserRole role) =>
    kPrimaryDestinations.where((d) => d.visibleTo(role)).toList();
