import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/api_response.dart';
import '../services/database_service.dart';
import '../ui/notification/notification_service.dart';
import '../utils/chucker_utils.dart';

/// Custom HTTP client with SmoothChucker support
class SmoothChuckerHttpClient extends http.BaseClient {
  /// The underlying HTTP client
  final http.Client _client;

  /// Database service for storing API responses
  final DatabaseService _databaseService;

  /// Notification service for showing notifications
  final NotificationService _notificationService;

  /// Whether to show notification on HTTP requests
  final bool showNotification;

  /// Maximum body size for displaying in notification (in bytes)
  final int maxNotificationBodySize;

  /// Whether isolates are supported on this platform
  final bool _supportsIsolates =
      !kIsWeb && !(Platform.isAndroid || Platform.isIOS);

  /// Constructor
  SmoothChuckerHttpClient(
    this._client, {
    DatabaseService? databaseService,
    NotificationService? notificationService,
    this.showNotification = true,
    this.maxNotificationBodySize = 1024, // Default 1KB
  })  : _databaseService = databaseService ?? DatabaseService(),
        _notificationService = notificationService ?? NotificationService();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!SmoothChuckerUtils.shouldInterceptRequest()) {
      return _client.send(request);
    }

    // Store the original request
    final requestTime = DateTime.now();
    late final http.StreamedResponse originalResponse;

    try {
      // Send the request and measure the time
      originalResponse = await _client.send(request);

      // Get the response bytes
      final responseBytes = await originalResponse.stream.toBytes();

      // Recreate the stream for the original response
      final streamedResponse = http.StreamedResponse(
        Stream.value(responseBytes),
        originalResponse.statusCode,
        contentLength: responseBytes.length,
        request: originalResponse.request,
        headers: originalResponse.headers,
        isRedirect: originalResponse.isRedirect,
        persistentConnection: originalResponse.persistentConnection,
        reasonPhrase: originalResponse.reasonPhrase,
      );

      // Process the response
      if (_supportsIsolates) {
        // Use isolate for desktop platforms
        _processResponseInIsolate(
          request: request,
          response: originalResponse,
          responseBytes: responseBytes,
          requestTime: requestTime,
        );
      } else {
        // Direct processing for mobile platforms
        _processResponseDirect(
          request: request,
          response: originalResponse,
          responseBytes: responseBytes,
          requestTime: requestTime,
        );
      }

      return streamedResponse;
    } catch (error) {
      // Process the error
      if (_supportsIsolates) {
        // Use isolate for desktop platforms
        _processErrorInIsolate(
          request: request,
          error: error,
          requestTime: requestTime,
        );
      } else {
        // Direct processing for mobile platforms
        _processErrorDirect(
          request: request,
          error: error,
          requestTime: requestTime,
        );
      }

      rethrow;
    }
  }

  /// Process response in isolate to prevent UI freezes
  Future<void> _processResponseInIsolate({
    required http.BaseRequest request,
    required http.StreamedResponse response,
    required Uint8List responseBytes,
    required DateTime requestTime,
  }) async {
    final receivePort = ReceivePort();

    final requestData = await _extractRequestData(request);

    final responseData = _HttpResponseData(
      request: request,
      responseBytes: responseBytes,
      response: response,
      requestTime: requestTime,
      requestBody: requestData.$1,
      requestHeaders: requestData.$2,
      sendPort: receivePort.sendPort,
    );

    await Isolate.spawn(_processHttpResponseIsolate, responseData);

    final apiResponse = await receivePort.first as ApiResponse;

    // Store API response in database
    unawaitedForHttp(_databaseService.addApiResponse(apiResponse));

    // Show notification if enabled
    if (showNotification) {
      _notificationService.showNotification(apiResponse,
          maxBodySize: maxNotificationBodySize);
    }
  }

  /// Process error in isolate to prevent UI freezes
  Future<void> _processErrorInIsolate({
    required http.BaseRequest request,
    required Object error,
    required DateTime requestTime,
  }) async {
    final receivePort = ReceivePort();

    final requestData = await _extractRequestData(request);

    final errorData = _HttpErrorData(
      request: request,
      error: error,
      requestTime: requestTime,
      requestBody: requestData.$1,
      requestHeaders: requestData.$2,
      sendPort: receivePort.sendPort,
    );

    await Isolate.spawn(_processHttpErrorIsolate, errorData);

    final apiResponse = await receivePort.first as ApiResponse;

    // Store API response in database
    unawaitedForHttp(_databaseService.addApiResponse(apiResponse));

    // Show notification if enabled
    if (showNotification) {
      _notificationService.showNotification(apiResponse,
          maxBodySize: maxNotificationBodySize);
    }
  }

  /// Extract request data
  Future<(dynamic, Map<String, String>)> _extractRequestData(
      http.BaseRequest request) async {
    // Extract request body
    dynamic requestBody;
    if (request is http.Request) {
      try {
        // Attempt to parse as JSON
        requestBody = jsonDecode(request.body);
      } catch (e) {
        // If not JSON, use raw body
        requestBody = request.body;
      }
    } else if (request is http.MultipartRequest) {
      requestBody = {
        'fields': request.fields,
        'files': request.files.map((f) => f.filename).toList(),
      };
    }

    return (requestBody, request.headers);
  }

  /// Process response directly (for mobile platforms)
  void _processResponseDirect({
    required http.BaseRequest request,
    required http.StreamedResponse response,
    required Uint8List responseBytes,
    required DateTime requestTime,
  }) async {
    try {
      // Extract request data
      final requestData = await _extractRequestData(request);

      // Extract response body
      dynamic responseBody;
      final responseString = utf8.decode(responseBytes, allowMalformed: true);
      try {
        // Attempt to parse as JSON
        responseBody = jsonDecode(responseString);
      } catch (e) {
        // If not JSON, use raw string
        responseBody = responseString;
      }

      // Calculate sizes
      final requestSize = _calculateRequestSize(request, requestData.$1);
      final responseSize = responseBytes.length.toDouble();

      // Parse URL
      final uri = request.url;
      final baseUrl =
          '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      final path = uri.path;

      // Create API response
      final apiResponse = ApiResponse(
        requestTime: requestTime,
        responseTime: DateTime.now(),
        baseUrl: baseUrl,
        path: path,
        method: request.method,
        statusCode: response.statusCode,
        requestSize: requestSize,
        responseSize: responseSize,
        request: requestData.$1,
        body: responseBody,
        contentType:
            request.headers['content-type'] ?? request.headers['Content-Type'],
        headers: requestData.$2,
        sendTimeout: 0, // HTTP package doesn't expose timeouts
        responseType: response.headers['content-type'] ?? 'N/A',
        receiveTimeout: 0,
        queryParameters: Uri.splitQueryString(uri.query),
        connectionTimeout: 0,
        checked: false,
        clientLibrary: 'http',
        apiName: '', // HTTP package doesn't have a built-in way to set this
        searchKeywords: [], // HTTP package doesn't have a built-in way to set this
      );

      // Store API response in database
      unawaitedForHttp(_databaseService.addApiResponse(apiResponse));

      // Show notification if enabled
      if (showNotification) {
        _notificationService.showNotification(apiResponse,
            maxBodySize: maxNotificationBodySize);
      }
    } catch (e) {
      debugPrint('Error processing HTTP response: $e');
    }
  }

  /// Process error directly (for mobile platforms)
  void _processErrorDirect({
    required http.BaseRequest request,
    required Object error,
    required DateTime requestTime,
  }) async {
    try {
      // Extract request data
      final requestData = await _extractRequestData(request);

      // Calculate request size
      final requestSize = _calculateRequestSize(request, requestData.$1);

      // Parse URL
      final uri = request.url;
      final baseUrl =
          '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      final path = uri.path;

      // Create API response
      final apiResponse = ApiResponse(
        requestTime: requestTime,
        responseTime: DateTime.now(),
        baseUrl: baseUrl,
        path: path,
        method: request.method,
        statusCode: 0, // No status code for errors
        requestSize: requestSize,
        responseSize: 0.0,
        request: requestData.$1,
        body: {'error': error.toString()},
        contentType:
            request.headers['content-type'] ?? request.headers['Content-Type'],
        headers: requestData.$2,
        sendTimeout: 0,
        responseType: 'json',
        receiveTimeout: 0,
        queryParameters: Uri.splitQueryString(uri.query),
        connectionTimeout: 0,
        checked: false,
        clientLibrary: 'http',
        apiName: '',
        searchKeywords: [],
      );

      // Store API response in database
      unawaitedForHttp(_databaseService.addApiResponse(apiResponse));

      // Show notification if enabled
      if (showNotification) {
        _notificationService.showNotification(apiResponse,
            maxBodySize: maxNotificationBodySize);
      }
    } catch (e) {
      debugPrint('Error processing HTTP error: $e');
    }
  }

  /// Static method to process HTTP response in isolate
  static void _processHttpResponseIsolate(_HttpResponseData data) {
    final sendPort = data.sendPort;

    try {
      // Extract response body
      dynamic responseBody;
      final responseString =
          utf8.decode(data.responseBytes, allowMalformed: true);
      try {
        // Attempt to parse as JSON
        responseBody = jsonDecode(responseString);
      } catch (e) {
        // If not JSON, use raw string
        responseBody = responseString;
      }

      // Calculate sizes
      final requestSize = _calculateRequestSize(data.request, data.requestBody);
      final responseSize = data.responseBytes.length.toDouble();

      // Parse URL
      final uri = data.request.url;
      final baseUrl =
          '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      final path = uri.path;

      // Create API response
      final apiResponse = ApiResponse(
        requestTime: data.requestTime,
        responseTime: DateTime.now(),
        baseUrl: baseUrl,
        path: path,
        method: data.request.method,
        statusCode: data.response.statusCode,
        requestSize: requestSize,
        responseSize: responseSize,
        request: data.requestBody,
        body: responseBody,
        contentType: data.request.headers['content-type'] ??
            data.request.headers['Content-Type'],
        headers: data.requestHeaders,
        sendTimeout: 0, // HTTP package doesn't expose timeouts
        responseType: 'json',
        receiveTimeout: 0,
        queryParameters: Uri.splitQueryString(uri.query),
        connectionTimeout: 0,
        checked: false,
        clientLibrary: 'http',
        apiName: '', // HTTP package doesn't have a built-in way to set this
        searchKeywords: [], // HTTP package doesn't have a built-in way to set this
      );

      sendPort.send(apiResponse);
    } catch (e) {
      debugPrint('Error processing HTTP response: $e');
      sendPort.send(ApiResponse.mock());
    }

    Isolate.exit();
  }

  /// Static method to process HTTP error in isolate
  static void _processHttpErrorIsolate(_HttpErrorData data) {
    final sendPort = data.sendPort;

    try {
      // Calculate request size
      final requestSize = _calculateRequestSize(data.request, data.requestBody);

      // Parse URL
      final uri = data.request.url;
      final baseUrl =
          '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
      final path = uri.path;

      // Create API response
      final apiResponse = ApiResponse(
        requestTime: data.requestTime,
        responseTime: DateTime.now(),
        baseUrl: baseUrl,
        path: path,
        method: data.request.method,
        statusCode: 0, // No status code for errors
        requestSize: requestSize,
        responseSize: 0.0,
        request: data.requestBody,
        body: {'error': data.error.toString()},
        contentType: data.request.headers['content-type'] ??
            data.request.headers['Content-Type'],
        headers: data.requestHeaders,
        sendTimeout: 0,
        responseType: 'json',
        receiveTimeout: 0,
        queryParameters: Uri.splitQueryString(uri.query),
        connectionTimeout: 0,
        checked: false,
        clientLibrary: 'http',
        apiName: '',
        searchKeywords: [],
      );

      sendPort.send(apiResponse);
    } catch (e) {
      debugPrint('Error processing HTTP error: $e');
      sendPort.send(ApiResponse.mock());
    }

    Isolate.exit();
  }

  /// Calculate the size of a request
  static double _calculateRequestSize(
      http.BaseRequest request, dynamic requestBody) {
    double size = 0;

    // Add headers size
    request.headers.forEach((key, value) {
      size += key.length + value.length;
    });

    // Add URL size
    size += request.url.toString().length;

    // Add request body size
    if (requestBody != null) {
      if (requestBody is String) {
        size += requestBody.length;
      } else if (requestBody is Map || requestBody is List) {
        size += jsonEncode(requestBody).length;
      }
    }

    return size;
  }
}

/// Data class for passing HTTP response to isolate
class _HttpResponseData {
  final http.BaseRequest request;
  final http.StreamedResponse response;
  final Uint8List responseBytes;
  final DateTime requestTime;
  final dynamic requestBody;
  final Map<String, String> requestHeaders;
  final SendPort sendPort;

  _HttpResponseData({
    required this.request,
    required this.response,
    required this.responseBytes,
    required this.requestTime,
    required this.requestBody,
    required this.requestHeaders,
    required this.sendPort,
  });
}

/// Data class for passing HTTP error to isolate
class _HttpErrorData {
  final http.BaseRequest request;
  final Object error;
  final DateTime requestTime;
  final dynamic requestBody;
  final Map<String, String> requestHeaders;
  final SendPort sendPort;

  _HttpErrorData({
    required this.request,
    required this.error,
    required this.requestTime,
    required this.requestBody,
    required this.requestHeaders,
    required this.sendPort,
  });
}

/// Extension to mark unawaited futures
void unawaitedForHttp(Future<void> future) {
  // Purposefully not awaited
}
