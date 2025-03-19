import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import '../services/database_service.dart';
import '../ui/notification/notification_service.dart';
import '../utils/chucker_utils.dart';
import 'package:http/http.dart' as http;


/// Chopper interceptor for SmoothChucker
class SmoothChuckerChopperInterceptor implements RequestInterceptor, ResponseInterceptor {
  /// Database service for storing API responses
  final DatabaseService _databaseService;

  /// Notification service for showing notifications
  final NotificationService _notificationService;

  /// Whether to show notification on HTTP requests
  final bool showNotification;

  /// Maximum body size for displaying in notification (in bytes)
  final int maxNotificationBodySize;

  /// Request time map to associate requests with their start times
  final Map<String, DateTime> _requestTimeMap = {};

  /// API name map to associate requests with their API names
  final Map<String, String> _apiNameMap = {};

  /// Search keywords map to associate requests with their search keywords
  final Map<String, List<String>> _keywordsMap = {};

  /// Whether isolates are supported on this platform
  final bool _supportsIsolates = !kIsWeb && !(Platform.isAndroid || Platform.isIOS);

  /// Constructor
  SmoothChuckerChopperInterceptor({
    DatabaseService? databaseService,
    NotificationService? notificationService,
    this.showNotification = true,
    this.maxNotificationBodySize = 1024, // Default 1KB
  })  : _databaseService = databaseService ?? DatabaseService(),
        _notificationService = notificationService ?? NotificationService();

  @override
  Future<Request> onRequest(Request request) async {
    if (!SmoothChuckerUtils.shouldInterceptRequest()) {
      return request;
    }

    // Store request time
    final requestId = _generateRequestId(request);
    _requestTimeMap[requestId] = DateTime.now();

    // Add API name and search keywords via custom extension method
    final apiName = SmoothChuckerUtils.getApiNameFromRequest(request);
    final searchKeywords = SmoothChuckerUtils.getSearchKeywordsFromRequest(request);

    if (apiName != null && apiName.isNotEmpty) {
      _apiNameMap[requestId] = apiName;
    }

    if (searchKeywords != null && searchKeywords.isNotEmpty) {
      _keywordsMap[requestId] = searchKeywords;
    }

    return request;
  }

  @override
  Future<Response<dynamic>> onResponse(Response<dynamic> response) async {
    if (!SmoothChuckerUtils.shouldInterceptRequest()) {
      return response;
    }

    final requestId = _generateRequestId(response.base.request);
    final requestTime = _requestTimeMap[requestId] ?? DateTime.now().subtract(const Duration(milliseconds: 100));

    // Get API name and search keywords if available
    final apiName = _apiNameMap[requestId] ?? '';
    final searchKeywords = _keywordsMap[requestId] ?? <String>[];

    // Remove request time, API name, and search keywords from maps
    _requestTimeMap.remove(requestId);
    _apiNameMap.remove(requestId);
    _keywordsMap.remove(requestId);

    // Process response in isolate or directly
    if (_supportsIsolates) {
      _processResponseInIsolate(response, requestTime, apiName, searchKeywords);
    } else {
      _processResponseDirectly(response, requestTime, apiName, searchKeywords);
    }

    return response;
  }


  /// Generate a unique ID for a request
  String _generateRequestId(http.BaseRequest? request) {
    if (request == null) return DateTime.now().millisecondsSinceEpoch.toString();
    return '${request.url.toString()}_${request.method}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Process response in isolate to prevent UI freezes
  Future<void> _processResponseInIsolate(
      Response<dynamic> response,
      DateTime requestTime,
      String apiName,
      List<String> searchKeywords,
      ) async {
    final receivePort = ReceivePort();

    final responseData = _ChopperResponseData(
      response: response,
      requestTime: requestTime,
      apiName: apiName,
      searchKeywords: searchKeywords,
      sendPort: receivePort.sendPort,
    );

    try {
      await Isolate.spawn(_processChopperResponseIsolate, responseData);

      final apiResponse = await receivePort.first as ApiResponse;

      // Store API response in database
      unawaited(_databaseService.addApiResponse(apiResponse));

      // Show notification if enabled
      if (showNotification) {
        _notificationService.showNotification(apiResponse, maxBodySize: maxNotificationBodySize);
      }
    } catch (e) {
      debugPrint('Error spawning isolate: $e');
      // Fallback to processing in main thread if isolate fails
      final apiResponse = _processChopperResponseMainThread(response, requestTime, apiName, searchKeywords);
      unawaited(_databaseService.addApiResponse(apiResponse));
      if (showNotification) {
        _notificationService.showNotification(apiResponse, maxBodySize: maxNotificationBodySize);
      }
    } finally {
      receivePort.close();
    }
  }

  /// Process Chopper response in the main thread as fallback
  ApiResponse _processChopperResponseMainThread(
      Response<dynamic> response,
      DateTime requestTime,
      String apiName,
      List<String> searchKeywords,
      ) {
    try {
      // Extract request body
      dynamic responseBody = '';

      try {
        final body = utf8.decode(response.bodyBytes);
        responseBody = jsonDecode(body);
        // ignore: empty_catches
      } catch (e) {}

      // Parse URL
      final uri = response.base.request?.url ?? Uri.parse('unknown');
      final baseUrl = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      final path = uri.path;

      // Extract headers
      Map<String, String> headers = {};
      (Map<String, dynamic>.from(response.base.headers)).forEach((key, value) {
        headers[key] = value;
      });

      // Create API response
      return ApiResponse(
        requestTime: requestTime,
        responseTime: DateTime.now(),
        baseUrl: baseUrl,
        path: path,
        method: response.base.request?.method ?? 'UNKNOWN',
        statusCode: response.statusCode,
        requestSize: 2,
        responseSize: 2,
        request: _requestBody(response),
        body: responseBody,
        contentType: _requestType(response),
        headers: headers,
        sendTimeout: 0,
        responseType: response.base.headers['content-type'] ?? 'N/A',
        receiveTimeout: 0,
        queryParameters: uri.queryParameters,
        connectionTimeout: 0,
        checked: false,
        clientLibrary: 'chopper',
        apiName: apiName,
        searchKeywords: searchKeywords,
      );

    } catch (e) {
      debugPrint('Error processing Chopper response: $e');
      return ApiResponse.mock();
    }
  }

  String _requestType(Response<dynamic> response) {
    final contentTypes = response.base.request?.headers.entries
        .where((element) => element.key == 'content-type');

    return contentTypes?.isEmpty ?? false
        ? 'N/A'
        : contentTypes?.first.value ?? '';
  }

  dynamic _requestBody(Response<dynamic> response) {
    if (response.base.request is http.MultipartRequest) {
      return _separateFileObjects(
        response.base.request as http.MultipartRequest?,
      );
    }

    if (response.base.request is http.Request) {
      final request = response.base.request! as http.Request;
      return request.body.isNotEmpty ? _getRequestBody(request) : '';
    }
    return '';
  }

  dynamic _getRequestBody(http.Request request) {
    try {
      return jsonDecode(request.body);
      // ignore: empty_catches
    } catch (e) {}
  }

  dynamic _separateFileObjects(http.MultipartRequest? request) {
    if (request == null) return '';
    final formFields =
    request.fields.entries.map((e) => {e.key: e.value}).toList()
      ..addAll(
        request.files.map(
              (e) => {e.field: e.filename ?? ''},
        ),
      );
    return formFields;
  }

  /// Static method to process Chopper response in isolate
  void _processChopperResponseIsolate(_ChopperResponseData data) {
    final response = data.response;
    final sendPort = data.sendPort;

    try {

      // Extract request body
      dynamic responseBody = '';

      try {
        final body = utf8.decode(response.bodyBytes);
        responseBody = jsonDecode(body);
        // ignore: empty_catches
      } catch (e) {}

      // Parse URL
      final uri = response.base.request?.url ?? Uri.parse('unknown');
      final baseUrl = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      final path = uri.path;

      // Extract headers
      Map<String, String> headers = {};
      (Map<String, dynamic>.from(response.base.headers)).forEach((key, value) {
        headers[key] = value;
      });

      // Create API response
      final apiResponse = ApiResponse(
        requestTime: data.requestTime,
        responseTime: DateTime.now(),
        baseUrl: baseUrl,
        path: path,
        method: response.base.request?.method ?? 'UNKNOWN',
        statusCode: response.statusCode,
        requestSize: 2,
        responseSize: 2,
        request: _requestBody(response),
        body: responseBody,
        contentType: _requestType(response),
        headers: headers,
        sendTimeout: 0, // Chopper doesn't expose timeouts
        responseType: response.base.headers['content-type'] ?? 'N/A',
        receiveTimeout: 0,
        queryParameters: uri.queryParameters,
        connectionTimeout: 0,
        checked: false,
        clientLibrary: 'chopper',
        apiName: data.apiName,
        searchKeywords: data.searchKeywords,
      );

      sendPort.send(apiResponse);

    } catch (e) {
      debugPrint('Error processing Chopper response: $e');
      sendPort.send(ApiResponse.mock());
    }

    Isolate.exit();
  }

  /// Process response directly without using isolates (for mobile platforms)
  void _processResponseDirectly(
      Response<dynamic> response,
      DateTime requestTime,
      String apiName,
      List<String> searchKeywords,
      ) {
    try {
      final apiResponse = _processChopperResponseMainThread(
          response,
          requestTime,
          apiName,
          searchKeywords
      );

      // Store API response in database
      unawaited(_databaseService.addApiResponse(apiResponse));

      // Show notification if enabled
      if (showNotification) {
        _notificationService.showNotification(apiResponse, maxBodySize: maxNotificationBodySize);
      }
    } catch (e) {
      debugPrint('Error processing Chopper response directly: $e');
    }
  }
}

/// Data class for passing Chopper response to isolate
class _ChopperResponseData {
  final Response<dynamic> response;
  final DateTime requestTime;
  final String apiName;
  final List<String> searchKeywords;
  final SendPort sendPort;

  _ChopperResponseData({
    required this.response,
    required this.requestTime,
    required this.sendPort,
    this.apiName = '',
    this.searchKeywords = const [],
  });
}

/// Extension to mark unawaited futures
void unawaited(Future<void> future) {
  // Purposefully not awaited
}

/// Chopper HTTP logging interceptor for better readability
class SmoothChuckerHttpLoggingInterceptor implements RequestInterceptor, ResponseInterceptor {
  @override
  Future<Request> onRequest(Request request) async {
    if (!SmoothChuckerUtils.shouldInterceptRequest()) {
      return request;
    }

    debugPrint('-> ${request.method} ${request.url}');
    debugPrint('HEADERS:');
    request.headers.forEach((key, value) {
      debugPrint('  $key: $value');
    });

    if (request.body != null) {
      debugPrint('BODY:');
      if (request.body is String) {
        debugPrint('  ${request.body}');
      } else if (request.body is Map || request.body is List) {
        try {
          const encoder = JsonEncoder.withIndent('  ');
          debugPrint('  ${encoder.convert(request.body)}');
        } catch (e) {
          debugPrint('  ${request.body}');
        }
      } else {
        debugPrint('  ${request.body}');
      }
    }

    return request;
  }

  @override
  Future<Response<dynamic>> onResponse(Response<dynamic> response) async {
    if (!SmoothChuckerUtils.shouldInterceptRequest()) {
      return response;
    }

    debugPrint('<- ${response.statusCode} ${response.base.request?.url}');
    debugPrint('HEADERS:');
    response.base.headers.forEach((key, value) {
      debugPrint('  $key: $value');
    });

    if (response.body != null) {
      debugPrint('BODY:');
      if (response.body is String) {
        debugPrint('  ${response.body}');
      } else if (response.body is Map || response.body is List) {
        try {
          const encoder = JsonEncoder.withIndent('  ');
          debugPrint('  ${encoder.convert(response.body)}');
        } catch (e) {
          debugPrint('  ${response.body}');
        }
      } else {
        debugPrint('  ${response.body}');
      }
    }

    return response;
  }
}
