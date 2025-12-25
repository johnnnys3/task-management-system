// screens/team_management_screen.dart
import 'package:flutter/material.dart';
import 'package:task_management/models/team.dart';

class TeamManagementScreen extends StatefulWidget {
  final String userId;

  TeamManagementScreen({required this.userId});

  @override
  _TeamManagementScreenState createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  List<Team> teams = []; // Populate this list with teams from Firestore or another database

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Management'),
      ),
      body: ListView.builder(
        itemCount: teams.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(teams[index].name),
            onTap: () {
              // Handle team details or updates
            },
          );
        },
      ),
    );
  }
}
