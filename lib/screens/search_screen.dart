/// Advanced search screen for comprehensive task discovery
/// Provides real-time search, filtering, and advanced search options
/// Includes search history, suggestions, and result management
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:task_management/models/task.dart';
import 'package:task_management/data/task_store.dart';
import 'task_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

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
    return Scaffold(
      // Modern app bar with clear action
      appBar: _buildAppBar(context),
      // Main content with loading/error states
      body: _isLoading ? _buildLoadingWidget() : _buildContent(),
    );
  }

  /// Builds modern app bar
  /// Includes title and clear search action
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Search Tasks',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
      actions: [
        // Clear search button
        if (_isSearching)
          IconButton(
            icon: const Icon(Icons.clear, color: Colors.white),
            tooltip: 'Clear Search',
            onPressed: _clearSearch,
          ),
        // Search options
        PopupMenuButton<String>(
          icon: const Icon(Icons.filter_list, color: Colors.white),
          tooltip: 'Search Options',
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'filters',
              child: Row(
                children: [
                  Icon(Icons.tune),
                  SizedBox(width: 8),
                  Text('Search Filters'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('Search History'),
                ],
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 16),
          Text(
            'Loading tasks...',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
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
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search tasks by title, description...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearSearch,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
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
          'Status Filter',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        // Search options
        const Text(
          'Search In',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final task = _searchResults[index];
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
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _clearSearchHistory,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return _buildHistoryItem(query);
            },
          ),
        ],
      ),
    );
  }

  /// Builds individual task card
  /// Creates styled card for search result
  Widget _buildTaskCard(Task task) {
    final isOverdue = !task.isCompleted && task.dueDate != null && task.dueDate!.isBefore(DateTime.now());
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToTaskDetails(task),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task header with status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
                          ? Colors.green 
                          : isOverdue 
                              ? Colors.red 
                              : Colors.orange,
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              // Task metadata
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.hasDueDate 
                        ? 'Due: ${DateFormat('MMM dd, yyyy').format(task.dueDate!)}'
                        : 'No due date',
                    style: TextStyle(
                      fontSize: 12,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  if (task.associatedProject?.id != null && task.associatedProject!.id.isNotEmpty) ...[
                    const SizedBox(width: 16),
                    Icon(
                      Icons.folder,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Project: ${task.associatedProject!.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds search history item
  /// Creates clickable history item
  Widget _buildHistoryItem(String query) {
    return ListTile(
      leading: const Icon(Icons.history),
      title: Text(query),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        _searchController.text = query;
        _onSearchChanged();
      },
    );
  }

  /// Builds no results widget
  /// Shows message when search yields no results
  Widget _buildNoResultsWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No search history',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your recent searches will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
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
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
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
