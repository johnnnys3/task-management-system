/// Advanced search screen for comprehensive task discovery
/// Provides real-time search, filtering, and advanced search options
/// Includes search history, suggestions, and result management
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/data/task_store.dart';
import 'package:task_management/theme/app_colors.dart';
import 'package:task_management/widgets/app_card.dart';
import 'package:task_management/navigation/app_shell.dart';
import 'task_details_screen.dart';

class SearchScreen extends StatefulWidget implements ShellPage {
  const SearchScreen({super.key});

  @override
  String get title => 'Search';

  @override
  String? get subtitle => null;

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // State variables
  final TextEditingController _searchController = TextEditingController();
  late final TaskStore _taskStore;
  List<Task> _allTasks = []; // All tasks for searching
  List<Task> _searchResults = []; // Filtered search results
  List<String> _searchHistory = []; // Search history
  bool _isLoading = false; // Loading state
  String _errorMessage = ''; // Error message
  String _selectedFilter = 'All'; // Filter status
  bool _isSearching = false; // Search state
  
  // Search options
  bool _searchInTitle = true;
  bool _searchInDescription = true;
  bool _searchInProject = false;

  @override
  void initState() {
    super.initState();
    _taskStore = context.read<TaskStore>();
    _loadTasks();
    _loadSearchHistory();
    // Listen to search controller changes
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    // Clean up controller to prevent memory leaks
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Loads all tasks from database
  /// Prepares data for searching
  Future<void> _loadTasks() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final tasks = await _taskStore.fetch();
      
      if (mounted) {
        setState(() {
          _allTasks = tasks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load tasks: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  /// Loads search history from preferences
  /// Restores previous search queries
  Future<void> _loadSearchHistory() async {
    // TODO: Implement search history loading from SharedPreferences
    if (!mounted) return;
    setState(() {
      _searchHistory = ['Recent search 1', 'Recent search 2'];
    });
  }

  /// Handles search text changes with debouncing
  /// Performs real-time search with delay
  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (!mounted) return;
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    
    // Debounce search to avoid excessive calls
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (_searchController.text.trim() == query) {
        _performSearch(query);
      }
    });
  }

  /// Performs search with current filters
  /// Updates search results based on query and filters
  Future<void> _performSearch(String query) async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });
      
      final results = _allTasks.where((task) {
        final lowerQuery = query.toLowerCase();
        bool matches = false;
        
        // Search in title
        if (_searchInTitle) {
          matches = matches || task.title.toLowerCase().contains(lowerQuery);
        }
        
        // Search in description
        if (_searchInDescription && task.description.isNotEmpty) {
          matches = matches || task.description.toLowerCase().contains(lowerQuery);
        }
        
        // Search in project
        if (_searchInProject && task.associatedProject?.id != null) {
          // TODO: Add project name search when project data is available
        }
        
        // Apply due date filter
        if (_selectedFilter == 'Overdue') {
          matches = matches && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
        }
        
        // Apply status filter
        if (_selectedFilter != 'All') {
          matches = matches && (
            (_selectedFilter == 'Completed' && task.isCompleted) ||
            (_selectedFilter == 'Pending' && !task.isCompleted)
          );
        }
        
        return matches;
      }).toList();
      
      // Add to search history
      if (query.isNotEmpty && !_searchHistory.contains(query)) {
        setState(() {
          _searchHistory.insert(0, query);
          if (_searchHistory.length > 10) {
            _searchHistory = _searchHistory.take(10).toList();
          }
        });
        // TODO: Save search history to SharedPreferences
      }
      
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Search failed: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Builds comprehensive search interface
  /// Creates modern layout with search bar, filters, and results
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildActionsHeader(),
        Expanded(child: _isLoading ? _buildLoadingWidget() : _buildContent()),
      ],
    );
  }

  /// Clear-search and search-options actions, previously app bar actions.
  Widget _buildActionsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.clear, color: AppColors.ink2),
            tooltip: 'Clear Search',
            onPressed: _clearSearch,
          ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list, color: AppColors.ink2),
          tooltip: 'Search Options',
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'filters',
              child: Row(
                children: [Icon(Icons.tune), SizedBox(width: 8), Text('Search Filters')],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [Icon(Icons.history), SizedBox(width: 8), Text('Search History')],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds loading widget
  /// Shows centered loading indicator
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
            'Loading tasks...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.ink2,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds main content area
  /// Shows search interface or error state
  Widget _buildContent() {
    if (_errorMessage.isNotEmpty) {
      return _buildErrorWidget();
    }
    
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: Column(
        children: [
          // Search section
          _buildSearchSection(),
          // Results or history
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildSearchHistory(),
          ),
        ],
      ),
    );
  }

  /// Builds search section with bar and filters
  /// Creates advanced search interface
  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 16),
          // Filter chips
          _buildFilterChips(),
        ],
      ),
    );
  }

  /// Builds advanced search bar
  /// Creates modern search input with clear button
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
          hintText: 'Search tasks by title, description...',
          hintStyle: const TextStyle(color: AppColors.ink3),
          prefixIcon: const Icon(Icons.search, color: AppColors.ink2),
          suffixIcon: _searchController.text.isNotEmpty
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Builds filter chips for status and search options
  /// Creates interactive filter selection
  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status filters
        const Text(
          'STATUS FILTER',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['All', 'Pending', 'Completed', 'Overdue'].map((filter) {
            return FilterChip(
              label: Text(filter),
              selected: _selectedFilter == filter,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
                if (_isSearching) {
                  _performSearch(_searchController.text.trim());
                }
              },
              selectedColor: AppColors.terra.withOpacity(0.2),
              checkmarkColor: AppColors.terra,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Search options
        const Text(
          'SEARCH IN',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: AppColors.ink2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Title'),
              selected: _searchInTitle,
              onSelected: (selected) {
                setState(() {
                  _searchInTitle = selected;
                });
                if (_isSearching) {
                  _performSearch(_searchController.text.trim());
                }
              },
            ),
            FilterChip(
              label: const Text('Description'),
              selected: _searchInDescription,
              onSelected: (selected) {
                setState(() {
                  _searchInDescription = selected;
                });
                if (_isSearching) {
                  _performSearch(_searchController.text.trim());
                }
              },
            ),
            FilterChip(
              label: const Text('Project'),
              selected: _searchInProject,
              onSelected: (selected) {
                setState(() {
                  _searchInProject = selected;
                });
                if (_isSearching) {
                  _performSearch(_searchController.text.trim());
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  /// Builds search results list
  /// Displays filtered tasks with modern cards
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildNoResultsWidget();
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'TASKS (${_searchResults.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.ink2,
              ),
            ),
          );
        }
        final task = _searchResults[index - 1];
        return _buildTaskCard(task);
      },
    );
  }

  /// Builds search history list
  /// Shows recent search queries
  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return _buildEmptyHistoryWidget();
    }
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT SEARCHES',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.ink2,
                ),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory.map((query) {
              return OutlinedButton(
                onPressed: () {
                  _searchController.text = query;
                  _onSearchChanged();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink2,
                  side: const BorderSide(color: AppColors.edge),
                ),
                child: Text(query),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Builds individual task card
  /// Creates styled card for search result
  Widget _buildTaskCard(Task task) {
    final isOverdue = !task.isCompleted && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => _navigateToTaskDetails(task),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.task_alt, color: AppColors.rust),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: task.isCompleted
                              ? AppColors.sage
                              : isOverdue
                                  ? AppColors.rust
                                  : AppColors.statusReview,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          task.isCompleted
                              ? 'Completed'
                              : isOverdue
                                  ? 'Overdue'
                                  : 'Pending',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Task description
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.ink2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  // Task metadata
                  Row(
                    children: [
                      const Icon(
                        Icons.event,
                        size: 16,
                        color: AppColors.ink3,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.hasDueDate
                            ? 'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}'
                            : 'No due date',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? AppColors.rust : AppColors.ink3,
                        ),
                      ),
                      if (task.associatedProject?.id != null && task.associatedProject!.id.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.folder,
                          size: 16,
                          color: AppColors.ink3,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Project: ${task.associatedProject!.id}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.ink3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds no results widget
  /// Shows message when search yields no results
  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.ink3,
          ),
          const SizedBox(height: 16),
          const Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.ink3,
            ),
          ),
        ],
      ),
    );
  }

  /// Builds empty history widget
  /// Shows message when no search history
  Widget _buildEmptyHistoryWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.history,
            size: 64,
            color: AppColors.ink3,
          ),
          const SizedBox(height: 16),
          const Text(
            'No search history',
            style: TextStyle(
              fontSize: 18,
              color: AppColors.ink2,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your recent searches will appear here',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.ink3,
            ),
          ),
        ],
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
            onPressed: _loadTasks,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  /// Handles menu actions from app bar
  /// Processes filter and history options
  void _handleMenuAction(String action) {
    switch (action) {
      case 'filters':
        _showFilterDialog();
        break;
      case 'history':
        _showHistoryDialog();
        break;
    }
  }

  /// Shows advanced filter dialog
  /// Displays comprehensive filter options
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Filters'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Search in:'),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Title'),
                  value: _searchInTitle,
                  onChanged: (value) {
                    setState(() {
                      _searchInTitle = value ?? false;
                    });
                    this.setState(() {});
                  },
                ),
                CheckboxListTile(
                  title: const Text('Description'),
                  value: _searchInDescription,
                  onChanged: (value) {
                    setState(() {
                      _searchInDescription = value ?? false;
                    });
                    this.setState(() {});
                  },
                ),
                CheckboxListTile(
                  title: const Text('Project'),
                  value: _searchInProject,
                  onChanged: (value) {
                    setState(() {
                      _searchInProject = value ?? false;
                    });
                    this.setState(() {});
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Shows search history dialog
  /// Displays recent search queries
  void _showHistoryDialog() {
    if (_searchHistory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No search history available')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    Navigator.pop(context);
                    _searchController.text = query;
                    _onSearchChanged();
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearSearchHistory();
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  /// Clears search query and results
  /// Resets search interface to initial state
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _isSearching = false;
    });
  }

  /// Clears search history
  /// Removes all saved search queries
  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
    // TODO: Save to SharedPreferences
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search history cleared')),
    );
  }

  /// Navigates to task details screen
  /// Opens detailed view for selected task
  void _navigateToTaskDetails(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailsScreen(task: task),
      ),
    );
  }

}
