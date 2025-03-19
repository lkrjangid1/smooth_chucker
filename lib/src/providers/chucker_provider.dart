import 'package:flutter/material.dart';

import '../models/api_response.dart';
import '../services/database_service.dart';

/// Provider for SmoothChucker state and configuration
class SmoothChuckerProvider extends ChangeNotifier {
  /// Database service
  final DatabaseService _databaseService;

  /// List of API responses
  List<ApiResponse> _apiResponses = [];

  /// Theme mode
  ThemeMode _themeMode = ThemeMode.system;

  /// Primary color
  Color _primaryColor = Colors.blue;

  /// Secondary color
  Color _secondaryColor = Colors.teal;

  /// Whether notifications are enabled
  bool _notificationsEnabled = true;

  /// Maximum body size for displaying in notification (in bytes)
  int _maxNotificationBodySize = 1024;

  /// Notification duration in seconds
  int _notificationDuration = 5;

  /// Maximum number of stored requests
  int _maxStoredRequests = 100;

  /// Active tab index
  int _activeTabIndex = 0;

  /// Search term
  String _searchTerm = '';

  /// API name filter
  String _apiNameFilter = '';

  /// Method filter
  String? _methodFilter;

  /// Status code filter
  int? _statusCodeFilter;

  /// Constructor
  SmoothChuckerProvider({
    DatabaseService? databaseService,
    ThemeMode themeMode = ThemeMode.system,
    Color primaryColor = Colors.blue,
    Color secondaryColor = Colors.teal,
    bool notificationsEnabled = true,
    int maxNotificationBodySize = 1024,
  })  : _databaseService = databaseService ?? DatabaseService(),
        _themeMode = themeMode,
        _primaryColor = primaryColor,
        _secondaryColor = secondaryColor,
        _notificationsEnabled = notificationsEnabled,
        _maxNotificationBodySize = maxNotificationBodySize {
    _loadApiResponses();

    // Listen for changes to API responses
    _databaseService.apiResponses.listen((responses) {
      _apiResponses = responses;
      notifyListeners();
    });
  }

  /// Get all API responses
  List<ApiResponse> get apiResponses => _apiResponses;

  /// Get filtered API responses based on active filters
  List<ApiResponse> get filteredApiResponses {
    List<ApiResponse> filtered = List.from(_apiResponses);

    // Apply search term filter
    if (_searchTerm.isNotEmpty) {
      filtered = filtered.where((response) {
        // Search in URL
        if (response.baseUrl
                .toLowerCase()
                .contains(_searchTerm.toLowerCase()) ||
            response.path.toLowerCase().contains(_searchTerm.toLowerCase())) {
          return true;
        }

        // Search in API name
        if (response.apiName
            .toLowerCase()
            .contains(_searchTerm.toLowerCase())) {
          return true;
        }

        // Search in search keywords
        if (response.searchKeywords.any((keyword) =>
            keyword.toLowerCase().contains(_searchTerm.toLowerCase()))) {
          return true;
        }

        // Search in response body
        if (response.body is Map || response.body is List) {
          final jsonString = response.prettyJson;
          if (jsonString.toLowerCase().contains(_searchTerm.toLowerCase())) {
            return true;
          }
        } else if (response.body is String) {
          final bodyString = response.body as String;
          if (bodyString.toLowerCase().contains(_searchTerm.toLowerCase())) {
            return true;
          }
        }

        // Search in request body
        if (response.request is Map || response.request is List) {
          final jsonString = response.prettyJsonRequest;
          if (jsonString.toLowerCase().contains(_searchTerm.toLowerCase())) {
            return true;
          }
        } else if (response.request is String) {
          final requestString = response.request as String;
          if (requestString.toLowerCase().contains(_searchTerm.toLowerCase())) {
            return true;
          }
        }

        return false;
      }).toList();
    }

    // Apply API name filter
    if (_apiNameFilter.isNotEmpty) {
      filtered = filtered
          .where((response) =>
              response.apiName.toLowerCase() == _apiNameFilter.toLowerCase())
          .toList();
    }

    // Apply method filter
    if (_methodFilter != null && _methodFilter!.isNotEmpty) {
      filtered = filtered
          .where((response) =>
              response.method.toUpperCase() == _methodFilter!.toUpperCase())
          .toList();
    }

    // Apply status code filter
    if (_statusCodeFilter != null) {
      filtered = filtered
          .where((response) => response.statusCode == _statusCodeFilter)
          .toList();
    }

    return filtered;
  }

  /// Get the theme mode
  ThemeMode get themeMode => _themeMode;

  /// Get the primary color
  Color get primaryColor => _primaryColor;

  /// Get the secondary color
  Color get secondaryColor => _secondaryColor;

  /// Get whether notifications are enabled
  bool get notificationsEnabled => _notificationsEnabled;

  /// Get the maximum body size for displaying in notification
  int get maxNotificationBodySize => _maxNotificationBodySize;

  /// Get the notification duration in seconds
  int get notificationDuration => _notificationDuration;

  /// Get the maximum number of stored requests
  int get maxStoredRequests => _maxStoredRequests;

  /// Get the active tab index
  int get activeTabIndex => _activeTabIndex;

  /// Get the search term
  String get searchTerm => _searchTerm;

  /// Get the API name filter
  String get apiNameFilter => _apiNameFilter;

  /// Get the method filter
  String? get methodFilter => _methodFilter;

  /// Get the status code filter
  int? get statusCodeFilter => _statusCodeFilter;

  /// Get unique API names from all responses
  List<String> get uniqueApiNames {
    final names = <String>{};
    for (final response in _apiResponses) {
      if (response.apiName.isNotEmpty) {
        names.add(response.apiName);
      }
    }
    return names.toList()..sort();
  }

  /// Get unique HTTP methods from all responses
  List<String> get uniqueMethods {
    final methods = <String>{};
    for (final response in _apiResponses) {
      methods.add(response.method.toUpperCase());
    }
    return methods.toList()..sort();
  }

  /// Get unique status codes from all responses
  List<int> get uniqueStatusCodes {
    final codes = <int>{};
    for (final response in _apiResponses) {
      if (response.statusCode > 0) {
        codes.add(response.statusCode);
      }
    }
    return codes.toList()..sort();
  }

  /// Set the theme mode
  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }

  /// Set the primary color
  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  /// Set the secondary color
  void setSecondaryColor(Color color) {
    _secondaryColor = color;
    notifyListeners();
  }

  /// Set whether notifications are enabled
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    notifyListeners();
  }

  /// Set the maximum body size for displaying in notification
  void setMaxNotificationBodySize(int size) {
    _maxNotificationBodySize = size;
    notifyListeners();
  }

  /// Set the notification duration in seconds
  void setNotificationDuration(int seconds) {
    _notificationDuration = seconds;
    notifyListeners();
  }

  /// Set the maximum number of stored requests
  void setMaxStoredRequests(int count) {
    _maxStoredRequests = count;
    notifyListeners();
    _trimOldRecords();
  }

  /// Set the active tab index
  void setActiveTabIndex(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  /// Set the search term
  void setSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  /// Set the API name filter
  void setApiNameFilter(String name) {
    _apiNameFilter = name;
    notifyListeners();
  }

  /// Set the method filter
  void setMethodFilter(String? method) {
    _methodFilter = method;
    notifyListeners();
  }

  /// Set the status code filter
  void setStatusCodeFilter(int? statusCode) {
    _statusCodeFilter = statusCode;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchTerm = '';
    _apiNameFilter = '';
    _methodFilter = null;
    _statusCodeFilter = null;
    notifyListeners();
  }

  /// Load API responses from database
  Future<void> _loadApiResponses() async {
    final responses = await _databaseService.getAllApiResponses();
    _apiResponses = responses;
    notifyListeners();
  }

  /// Reload API responses from database
  Future<void> reloadApiResponses() async {
    await _loadApiResponses();
  }

  /// Delete all API responses
  Future<void> deleteAllApiResponses() async {
    await _databaseService.deleteAllApiResponses();
    _apiResponses = [];
    notifyListeners();
  }

  /// Delete a specific API response
  Future<void> deleteApiResponse(ApiResponse response) async {
    await _databaseService.deleteApiResponse(response);
    _apiResponses.removeWhere((r) => r == response);
    notifyListeners();
  }

  /// Search API responses
  Future<List<ApiResponse>> searchApiResponses({
    String? searchTerm,
    String? apiName,
    String? method,
    int? statusCode,
    String? path,
  }) async {
    return await _databaseService.searchApiResponses(
      searchTerm: searchTerm,
      apiName: apiName,
      method: method,
      statusCode: statusCode,
      path: path,
    );
  }

  /// Helper method to remove old records if we exceed the maximum
  Future<void> _trimOldRecords() async {
    if (_apiResponses.length > _maxStoredRequests) {
      // Sort by request time descending
      _apiResponses.sort((a, b) => b.requestTime.compareTo(a.requestTime));

      // Get the records to delete
      final recordsToDelete = _apiResponses.sublist(_maxStoredRequests);

      // Delete from database
      for (final record in recordsToDelete) {
        await _databaseService.deleteApiResponse(record);
      }

      // Update the list
      _apiResponses = _apiResponses.sublist(0, _maxStoredRequests);
      notifyListeners();
    }
  }
}
