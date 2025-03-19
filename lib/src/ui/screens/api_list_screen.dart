import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api_response.dart';
import '../../providers/chucker_provider.dart';
import '../widgets/api_list_item.dart';
import '../widgets/search_filter_bar.dart';
import 'api_detail_screen.dart';
import 'settings_screen.dart';

/// Screen showing the list of API requests
class ApiListScreen extends StatefulWidget {
  /// Constructor
  const ApiListScreen({super.key});

  @override
  State<ApiListScreen> createState() => _ApiListScreenState();
}

class _ApiListScreenState extends State<ApiListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context
            .read<SmoothChuckerProvider>()
            .setActiveTabIndex(_tabController.index);
      }
    });

    // Restore active tab index
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SmoothChuckerProvider>();
      _tabController.index = provider.activeTabIndex;
    });

    // Setup search controller
    _searchController.addListener(() {
      context
          .read<SmoothChuckerProvider>()
          .setSearchTerm(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: _buildFab(),
    );
  }

  /// Build the app bar
  PreferredSizeWidget _buildAppBar() {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              decoration: InputDecoration(
                hintText: 'Search API requests...',
                border: InputBorder.none,
                hintStyle: TextStyle(
                  color: isLight ? Colors.black54 : Colors.white70,
                ),
              ),
              style: TextStyle(
                color: isLight ? Colors.black : Colors.white,
              ),
              autofocus: true,
            )
          : const Text('Smooth Chucker'),
      actions: _buildAppBarActions(),
      bottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Successful'),
          Tab(text: 'Redirects'),
          Tab(text: 'Client Errors'),
          Tab(text: 'Server Errors'),
        ],
      ),
    );
  }

  /// Build app bar actions
  List<Widget> _buildAppBarActions() {
    return [
      if (_isSearching)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            _searchController.clear();
            setState(() {
              _isSearching = false;
            });
          },
        )
      else
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
      IconButton(
        icon: const Icon(Icons.filter_list),
        onPressed: _showFilterDialog,
      ),
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
        },
      ),
    ];
  }

  /// Build the body
  Widget _buildBody() {
    return Column(
      children: [
        // Add the SearchFilterBar as an indicator of active filters
        Consumer<SmoothChuckerProvider>(
          builder: (context, provider, child) {
            final hasFilters = provider.apiNameFilter.isNotEmpty ||
                provider.methodFilter != null ||
                provider.statusCodeFilter != null;

            return hasFilters
                ? const SearchFilterBar()
                : const SizedBox.shrink();
          },
        ),

        // Main content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildApiListTab(null),
              _buildApiListTab(200),
              _buildApiListTab(300),
              _buildApiListTab(400),
              _buildApiListTab(500),
            ],
          ),
        ),
      ],
    );
  }

  /// Build a tab for API list
  Widget _buildApiListTab(int? statusCodePrefix) {
    return Consumer<SmoothChuckerProvider>(
      builder: (context, provider, child) {
        List<ApiResponse> filteredResponses = provider.filteredApiResponses;

        // Apply additional status code filtering based on tab
        if (statusCodePrefix != null) {
          filteredResponses = filteredResponses.where((response) {
            final statusCode = response.statusCode;
            return statusCode >= statusCodePrefix &&
                statusCode < statusCodePrefix + 100;
          }).toList();
        }

        if (filteredResponses.isEmpty) {
          return const Center(
            child: Text('No API requests found'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.reloadApiResponses();
          },
          child: ListView.builder(
            itemCount: filteredResponses.length,
            itemBuilder: (context, index) {
              final apiResponse = filteredResponses[index];
              return ApiListItem(
                apiResponse: apiResponse,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ApiDetailScreen(apiResponse: apiResponse),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  /// Build the floating action button
  Widget? _buildFab() {
    return Consumer<SmoothChuckerProvider>(
      builder: (context, provider, child) {
        if (provider.apiResponses.isEmpty) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: _showClearConfirmationDialog,
          tooltip: 'Clear all',
          child: const Icon(Icons.delete),
        );
      },
    );
  }

  /// Show filter dialog
  void _showFilterDialog() {
    final provider = context.read<SmoothChuckerProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          provider.clearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // API Name filter
                  const Text('API Name'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text('Select API Name'),
                    value: provider.apiNameFilter.isEmpty
                        ? null
                        : provider.apiNameFilter,
                    items: [
                      const DropdownMenuItem<String>(
                        value: '',
                        child: Text('All'),
                      ),
                      ...provider.uniqueApiNames.map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        provider.setApiNameFilter(value ?? '');
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Method filter
                  const Text('HTTP Method'),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    isExpanded: true,
                    hint: const Text('Select HTTP Method'),
                    value: provider.methodFilter,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...provider.uniqueMethods.map((method) {
                        return DropdownMenuItem<String?>(
                          value: method,
                          child: Text(method),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        provider.setMethodFilter(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Status code filter
                  const Text('Status Code'),
                  const SizedBox(height: 8),
                  DropdownButton<int?>(
                    isExpanded: true,
                    hint: const Text('Select Status Code'),
                    value: provider.statusCodeFilter,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...provider.uniqueStatusCodes.map((code) {
                        return DropdownMenuItem<int?>(
                          value: code,
                          child: Text(code.toString()),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        provider.setStatusCodeFilter(value);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                  // Add padding for bottom sheet safe area
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Show confirmation dialog for clearing all requests
  void _showClearConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Requests'),
          content:
              const Text('Are you sure you want to delete all API requests?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<SmoothChuckerProvider>().deleteAllApiResponses();
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }
}
