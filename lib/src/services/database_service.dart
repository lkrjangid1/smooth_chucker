import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/api_response.dart';

/// Database service that handles API responses with isolate support
class DatabaseService {
  static DatabaseService? _instance;
  static const String _databaseName = 'smooth_chucker.db';
  static const int _databaseVersion = 1;

  static const String table = 'api_responses';
  static const String columnId = 'id';
  static const String columnJson = 'json_data';
  static const String columnTimestamp = 'timestamp';
  static const String columnPath = 'path';
  static const String columnMethod = 'method';
  static const String columnStatusCode = 'status_code';
  static const String columnApiName = 'api_name';
  static const String columnSearchKeywords = 'search_keywords';

  /// Upper bound on stored requests. Enforced on every insert, so the table
  /// (and every read of it) stays small no matter how chatty the app is.
  static int maxStoredRequests = 100;

  Database? _database;

  /// This session's responses, newest first. Mirrors the table so inserts
  /// never re-read it — reloading the whole table after every request is what
  /// let a busy session grow to 70MB and OOM the Sqflite thread on one read.
  final List<ApiResponse> _responses = [];
  final StreamController<List<ApiResponse>> _apiResponsesSubject =
      StreamController<List<ApiResponse>>.broadcast();
  static bool _supportsIsolates = false;
  bool _isInitializing = false;
  Completer<Database>? _dbCompleter;

  /// Factory constructor
  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  /// Private constructor
  DatabaseService._internal();

  /// Initialize the database service if not already initialized
  Future<void> init() async {
    if (_database != null) return;
    if (_isInitializing) {
      // If already initializing, wait for completion
      if (_dbCompleter != null) await _dbCompleter!.future;
      return;
    }

    _isInitializing = true;
    _dbCompleter = Completer<Database>();

    try {
      final database = await _initDatabase();
      _database = database;
      _dbCompleter?.complete(database);

      // Check if isolates are supported for database operations
      _supportsIsolates = !kIsWeb && !(Platform.isAndroid || Platform.isIOS);
    } catch (e) {
      _dbCompleter?.completeError(e);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// Initialize database. Each app launch starts a new session: the previous
  /// session's file is dropped outright (cheaper than DELETE + VACUUM and
  /// never reads the old rows), so only the current session is ever stored.
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    await deleteDatabase(path);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnJson TEXT NOT NULL,
        $columnTimestamp TEXT NOT NULL,
        $columnPath TEXT NOT NULL,
        $columnMethod TEXT NOT NULL,
        $columnStatusCode INTEGER NOT NULL,
        $columnApiName TEXT,
        $columnSearchKeywords TEXT
      )
    ''');
  }

  /// Stream of API responses
  Stream<List<ApiResponse>> get apiResponses => _apiResponsesSubject.stream;

  /// Get all API responses of the current session, newest first
  Future<List<ApiResponse>> getAllApiResponses() async {
    await init();
    return List.unmodifiable(_responses);
  }

  void _emit() => _apiResponsesSubject.add(List.unmodifiable(_responses));

  /// Parse API responses in isolate
  static List<ApiResponse> _parseApiResponses(List<Map<String, dynamic>> maps) {
    return maps.map((map) {
      try {
        final jsonData = jsonDecode(map[columnJson] as String);
        return ApiResponse.fromJson(jsonData as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Error parsing API response: $e');
        return ApiResponse.mock();
      }
    }).toList();
  }

  /// Add an API response to the database
  Future<void> addApiResponse(ApiResponse response) async {
    await init();

    if (_supportsIsolates) {
      // Use isolate for platforms that support it (desktop, web)
      await _addApiResponseWithIsolate(response);
    } else {
      // Direct database access for mobile platforms
      await _addApiResponseDirect(response);
    }

    _responses.insert(0, response);
    await trimToMax();
    _emit();
  }

  /// Drops everything beyond [maxStoredRequests], in memory and in the table.
  Future<void> trimToMax() async {
    await init();
    if (_responses.length > maxStoredRequests) {
      _responses.removeRange(maxStoredRequests, _responses.length);
    }
    await _database!.rawDelete(
      'DELETE FROM $table WHERE $columnId NOT IN '
      '(SELECT $columnId FROM $table ORDER BY $columnId DESC LIMIT ?)',
      [maxStoredRequests],
    );
  }

  /// Add API response directly without using isolates (for mobile platforms)
  Future<void> _addApiResponseDirect(ApiResponse response) async {
    try {
      await _database!.insert(
        table,
        {
          columnJson: jsonEncode(response.toJson()),
          columnTimestamp: response.requestTime.toIso8601String(),
          columnPath: response.path,
          columnMethod: response.method,
          columnStatusCode: response.statusCode,
          columnApiName: response.apiName,
          columnSearchKeywords: jsonEncode(response.searchKeywords),
        },
      );
    } catch (e) {
      debugPrint('Error in direct database insert: $e');
      throw Exception('Failed to insert API response');
    }
  }

  /// Add API response using isolate (for desktop platforms)
  Future<void> _addApiResponseWithIsolate(ApiResponse response) async {
    // Create a SendPort for receiving the result
    final receivePort = ReceivePort();

    // Spawn the isolate
    await Isolate.spawn(
      _insertApiResponseIsolate,
      _ApiResponseInsertParams(
        response: response,
        sendPort: receivePort.sendPort,
        dbPath: _database!.path,
      ),
    );

    // Wait for the isolate to complete
    final result = await receivePort.first;

    if (result is String && result == 'success') {
      // Success
    } else {
      throw Exception('Failed to insert API response');
    }
  }

  /// Isolate for inserting API response
  static Future<void> _insertApiResponseIsolate(
      _ApiResponseInsertParams params) async {
    final sendPort = params.sendPort;
    final response = params.response;
    final dbPath = params.dbPath;

    try {
      final db = await openDatabase(dbPath);

      await db.insert(
        table,
        {
          columnJson: jsonEncode(response.toJson()),
          columnTimestamp: response.requestTime.toIso8601String(),
          columnPath: response.path,
          columnMethod: response.method,
          columnStatusCode: response.statusCode,
          columnApiName: response.apiName,
          columnSearchKeywords: jsonEncode(response.searchKeywords),
        },
      );

      await db.close();
      sendPort.send('success');
    } catch (e) {
      debugPrint('Error in insert isolate: $e');
      sendPort.send('error');
    }

    Isolate.exit();
  }

  /// Search API responses
  Future<List<ApiResponse>> searchApiResponses({
    String? searchTerm,
    String? apiName,
    String? method,
    int? statusCode,
    String? path,
  }) async {
    await init();

    if (_supportsIsolates) {
      return await _searchApiResponsesWithIsolate(
        searchTerm: searchTerm,
        apiName: apiName,
        method: method,
        statusCode: statusCode,
        path: path,
      );
    } else {
      return await _searchApiResponsesDirect(
        searchTerm: searchTerm,
        apiName: apiName,
        method: method,
        statusCode: statusCode,
        path: path,
      );
    }
  }

  /// Search API responses directly without using isolates (for mobile platforms)
  Future<List<ApiResponse>> _searchApiResponsesDirect({
    String? searchTerm,
    String? apiName,
    String? method,
    int? statusCode,
    String? path,
  }) async {
    try {
      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];

      if (searchTerm != null && searchTerm.isNotEmpty) {
        whereConditions
            .add('($columnJson LIKE ? OR $columnSearchKeywords LIKE ?)');
        whereArgs.add('%$searchTerm%');
        whereArgs.add('%$searchTerm%');
      }

      if (apiName != null && apiName.isNotEmpty) {
        whereConditions.add('$columnApiName = ?');
        whereArgs.add(apiName);
      }

      if (method != null && method.isNotEmpty) {
        whereConditions.add('$columnMethod = ?');
        whereArgs.add(method);
      }

      if (statusCode != null) {
        whereConditions.add('$columnStatusCode = ?');
        whereArgs.add(statusCode);
      }

      if (path != null && path.isNotEmpty) {
        whereConditions.add('$columnPath LIKE ?');
        whereArgs.add('%$path%');
      }

      final whereClause =
          whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

      final maps = await _database!.query(
        table,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: '$columnTimestamp DESC',
        limit: maxStoredRequests,
      );

      return await compute(_parseApiResponses, maps);
    } catch (e) {
      debugPrint('Error in direct search: $e');
      return [];
    }
  }

  /// Search API responses using isolate (for desktop platforms)
  Future<List<ApiResponse>> _searchApiResponsesWithIsolate({
    String? searchTerm,
    String? apiName,
    String? method,
    int? statusCode,
    String? path,
  }) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _searchApiResponsesIsolate,
      _ApiResponseSearchParams(
        sendPort: receivePort.sendPort,
        dbPath: _database!.path,
        limit: maxStoredRequests,
        searchTerm: searchTerm,
        apiName: apiName,
        method: method,
        statusCode: statusCode,
        path: path,
      ),
    );

    final result = await receivePort.first;

    if (result is List<Map<String, dynamic>>) {
      final responses = await compute(_parseApiResponses, result);
      return responses;
    } else {
      return [];
    }
  }

  /// Isolate for searching API responses
  static Future<void> _searchApiResponsesIsolate(
      _ApiResponseSearchParams params) async {
    final sendPort = params.sendPort;
    final dbPath = params.dbPath;

    try {
      final db = await openDatabase(dbPath);

      final whereConditions = <String>[];
      final whereArgs = <dynamic>[];

      if (params.searchTerm != null && params.searchTerm!.isNotEmpty) {
        whereConditions
            .add('($columnJson LIKE ? OR $columnSearchKeywords LIKE ?)');
        whereArgs.add('%${params.searchTerm}%');
        whereArgs.add('%${params.searchTerm}%');
      }

      if (params.apiName != null && params.apiName!.isNotEmpty) {
        whereConditions.add('$columnApiName = ?');
        whereArgs.add(params.apiName);
      }

      if (params.method != null && params.method!.isNotEmpty) {
        whereConditions.add('$columnMethod = ?');
        whereArgs.add(params.method);
      }

      if (params.statusCode != null) {
        whereConditions.add('$columnStatusCode = ?');
        whereArgs.add(params.statusCode);
      }

      if (params.path != null && params.path!.isNotEmpty) {
        whereConditions.add('$columnPath LIKE ?');
        whereArgs.add('%${params.path}%');
      }

      final whereClause =
          whereConditions.isNotEmpty ? whereConditions.join(' AND ') : null;

      final maps = await db.query(
        table,
        where: whereClause,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: '$columnTimestamp DESC',
        limit: params.limit,
      );

      await db.close();
      sendPort.send(maps);
    } catch (e) {
      debugPrint('Error in search isolate: $e');
      sendPort.send([]);
    }

    Isolate.exit();
  }

  /// Delete all API responses
  Future<void> deleteAllApiResponses() async {
    await init();
    await _database!.delete(table);
    _responses.clear();
    _emit();
  }

  /// Delete specific API response
  Future<void> deleteApiResponse(ApiResponse response) async {
    await init();

    // Use the requestTime as a unique identifier for the response
    final timestamp = response.requestTime.toIso8601String();

    await _database!.delete(
      table,
      where: '$columnTimestamp = ?',
      whereArgs: [timestamp],
    );

    _responses.removeWhere((r) => r.requestTime == response.requestTime);
    _emit();
  }

  /// Close the database
  Future<void> close() async {
    await _database?.close();
    _database = null;
    await _apiResponsesSubject.close();
  }
}

/// Parameters for insert API response isolate
class _ApiResponseInsertParams {
  final ApiResponse response;
  final SendPort sendPort;
  final String dbPath;

  _ApiResponseInsertParams({
    required this.response,
    required this.sendPort,
    required this.dbPath,
  });
}

/// Parameters for search API responses isolate
class _ApiResponseSearchParams {
  final SendPort sendPort;
  final String dbPath;
  final int limit;
  final String? searchTerm;
  final String? apiName;
  final String? method;
  final int? statusCode;
  final String? path;

  _ApiResponseSearchParams({
    required this.sendPort,
    required this.dbPath,
    required this.limit,
    this.searchTerm,
    this.apiName,
    this.method,
    this.statusCode,
    this.path,
  });
}
