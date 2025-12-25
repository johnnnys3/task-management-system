import 'package:flutter/material.dart';
import 'package:task_management/models/task.dart'; // Import the Task model
import 'package:task_management/data/database_helper(task).dart'; // Import your TaskDatabase class
import 'task_details_screen.dart'; // Import the screen where you want to show task details

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TaskDatabase _taskDatabase = TaskDatabase();
  List<Task> _searchResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchBar(),
            SizedBox(height: 20),
            _buildSearchResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search tasks',
        prefixIcon: Icon(Icons.search),
        border: OutlineInputBorder(),
      ),
      onChanged: _onSearchTextChanged,
    );
  }

  void _onSearchTextChanged(String query) async {
    // Perform search and update the search results
    List<Task> tasks = await _taskDatabase.fetchTasks();
    List<Task> searchResults = tasks.where((task) {
      return task.title.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _searchResults = searchResults;
    });
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          Task task = _searchResults[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text('Due Date: ${task.dueDate}'),
            onTap: () {
              // Handle tapping on a search result
              _navigateToTaskDetails(task);
            },
          );
        },
      ),
    );
  }

  // Function to navigate to the Task Details screen
  void _navigateToTaskDetails(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(task: task),
      ),
    );
  }
}
