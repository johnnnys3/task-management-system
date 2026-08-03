/// Thin wrapper around the single navigation shell.
/// See lib/navigation/app_shell.dart for the actual nav/top-bar logic.
import 'package:flutter/material.dart';
import 'package:task_management/authentication/user.dart';
import 'package:task_management/navigation/app_shell.dart';

class HomeScreen extends StatelessWidget {
  final String userId;
  final CustomUser user;
  final bool isAdmin;

  const HomeScreen({
    Key? key,
    required this.userId,
    required this.user,
    required this.isAdmin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppShell(user: user, userId: userId, isAdmin: isAdmin);
  }
}
