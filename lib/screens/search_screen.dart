/// Search screen for finding tasks, projects, and people across the app.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_management/models/project.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/models/team.dart';
import 'package:task_management/data/project_store.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/data/team_store.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/theme/app_theme.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/widgets/avatar_badge.dart';
import 'package:task_management/widgets/pill_button.dart';
import 'package:task_management/navigation/app_shell.dart';
import 'project_details_screen.dart';
import 'task_details_screen.dart';
import 'team_details_screen.dart';

class SearchScreen extends StatefulWidget implements ShellPage {
  const SearchScreen({super.key});

  @override
  String get title => 'Search';

  @override
  String? get subtitle => null;

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

const List<String> _kSuggestions = ['Overdue', 'Due today', 'High priority', 'Unassigned'];

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final TaskStore _taskStore;
  late final ProjectStore _projectStore;
  late final TeamStore _teamStore;

  List<Task> _allTasks = [];
  List<Project> _allProjects = [];
  List<Team> _allTeams = [];

  List<Task> _taskResults = [];
  List<Project> _projectResults = [];
  List<String> _peopleResults = [];

  bool _isLoading = true;
  String _errorMessage = '';
  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _taskStore = context.read<TaskStore>();
    _projectStore = context.read<ProjectStore>();
    _teamStore = context.read<TeamStore>();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      final results = await Future.wait([
        _taskStore.fetch(),
        _projectStore.fetch(),
        _teamStore.fetch(),
      ]);
      if (!mounted) return;
      setState(() {
        _allTasks = results[0] as List<Task>;
        _allProjects = results[1] as List<Project>;
        _allTeams = results[2] as List<Team>;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load search data: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _taskResults = [];
        _projectResults = [];
        _peopleResults = [];
      });
      return;
    }
    _performSearch(query);
  }

  void _performSearch(String query) {
    final lowerQuery = query.toLowerCase();

    final taskResults = _allTasks
        .where((task) =>
            task.title.toLowerCase().contains(lowerQuery) ||
            task.description.toLowerCase().contains(lowerQuery))
        .toList();

    final projectResults = _allProjects
        .where((project) =>
            project.name.toLowerCase().contains(lowerQuery) ||
            project.description.toLowerCase().contains(lowerQuery))
        .toList();

    // ponytail: no dedicated user directory, so "people" search is drawn
    // from team member ids matching the query.
    final peopleResults = _allTeams
        .expand((team) => team.members.keys)
        .toSet()
        .where((id) => id.toLowerCase().contains(lowerQuery))
        .toList();

    setState(() {
      _taskResults = taskResults;
      _projectResults = projectResults;
      _peopleResults = peopleResults;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(child: _isLoading ? _buildLoadingWidget() : _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.edge),
      ),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: AppColors.ink),
        decoration: InputDecoration(
          hintText: 'Search tasks, projects, people...',
          hintStyle: const TextStyle(color: AppColors.ink3),
          prefixIcon: const Icon(Icons.search, color: AppColors.ink2),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.clear, color: AppColors.ink2),
                  onPressed: _clearSearch,
                )
              : null,
          filled: true,
          fillColor: AppColors.paper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(99),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.terra),
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(_errorMessage, style: const TextStyle(color: AppColors.rust)),
      );
    }
    if (!_isSearching) return _buildSuggestions();

    final hasResults = _taskResults.isNotEmpty || _projectResults.isNotEmpty || _peopleResults.isNotEmpty;
    if (!hasResults) return _buildNoResults();

    return ListView(
      children: [
        if (_taskResults.isNotEmpty) _buildSection('Tasks', _taskResults.length, _buildTaskRows()),
        if (_projectResults.isNotEmpty) _buildSection('Projects', _projectResults.length, _buildProjectRows()),
        if (_peopleResults.isNotEmpty) _buildSection('People', _peopleResults.length, _buildPeopleRows()),
      ],
    );
  }

  Widget _buildSection(String label, int count, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              '${label.toUpperCase()} ($count)',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.ink2),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  rows[i],
                  if (i != rows.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTaskRows() {
    return _taskResults
        .map((task) => _ResultRow(
              icon: Icons.task_alt,
              iconColor: task.isCompleted ? AppColors.sage : AppColors.terra,
              title: task.title,
              subtitle: task.description.isNotEmpty ? task.description : 'No description',
              onTap: () => _navigateTo(TaskDetailsScreen(task: task)),
            ))
        .toList();
  }

  List<Widget> _buildProjectRows() {
    return _projectResults
        .map((project) => _ResultRow(
              icon: Icons.folder,
              iconColor: AppColors.statusReview,
              title: project.name,
              subtitle: project.description.isNotEmpty ? project.description : 'No description',
              onTap: () => _navigateTo(ProjectDetailsScreen(project: project)),
            ))
        .toList();
  }

  List<Widget> _buildPeopleRows() {
    return _peopleResults.map((userId) {
      final team = _allTeams.firstWhere((t) => t.members.containsKey(userId));
      return _ResultRow(
        avatarName: userId,
        title: userId,
        subtitle: '${team.members[userId]!.value} · ${team.name}',
        // ponytail: no per-user isAdmin lookup here, so the team opens read-only.
        onTap: () => _navigateTo(TeamDetailsScreen(team: team, isAdmin: false)),
      );
    }).toList();
  }

  Widget _buildSuggestions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Try',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppColors.ink2),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kSuggestions
              .map((suggestion) => PillButton(
                    label: suggestion,
                    outlined: true,
                    onPressed: () {
                      _searchController.text = suggestion;
                      _onSearchChanged();
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: AppCard(
        color: AppColors.sand,
        child: Text(
          'No matches for "${_searchController.text.trim()}".',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.ink2),
        ),
      ),
    );
  }

  void _clearSearch() {
    _searchController.clear();
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }
}

/// A single search result row: icon circle, title, subtitle.
class _ResultRow extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String? avatarName;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ResultRow({
    this.icon,
    this.iconColor,
    this.avatarName,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (avatarName != null)
                AvatarBadge(name: avatarName!, size: 34)
              else
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: iconColor ?? AppColors.terra, shape: BoxShape.circle),
                  child: Icon(icon, color: Colors.white, size: 17),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: AppTheme.display(size: 14.5, weight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(fontSize: 12.5, color: AppColors.ink2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
