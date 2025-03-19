import 'dart:convert';
import 'dart:isolate';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/api_response.dart';
import '../services/database_service.dart';
import '../ui/notification/notification_service.dart';
import '../utils/chucker_utils.dart';

/// Intercepts Dio requests and responses and stores them in the database
class SmoothChuckerDioInterceptor extends Interceptor {
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
  SmoothChuckerDioInterceptor({
    DatabaseService? databaseService,
    NotificationService? notificationService,
    this.showNotification = true,
    this.maxNotificationBodySize = 1024, // Default 1KB
  })  : _databaseService = databaseService ?? DatabaseService(),
        _notificationService = notificationService ?? NotificationService();

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    if (!SmoothChuckerUtils.shouldInterceptRequest()) {
      return handler.next(options);
    }

    // Add request time to options
    options.extra['smooth_chucker_request_time'] = DateTime.now();
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    if (!SmoothChuckerUtils.shouldInterceptRequest()) {
      return handler.next(response);
    }

    if (_supportsIsolates) {
      _processResponseInIsolate(response);
    } else {
      _processResponseDirect(response);
    }

    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (!SmoothChuckerUtils.shouldInterceptRequest()) {
      return handler.next(err);
    }

    if (_supportsIsolates) {
      _processErrorInIsolate(err);
    } else {
      _processErrorDirect(err);
    }

    return handler.next(err);
  }

  /// Process response in isolate to prevent UI freezes
  Future<void> _processResponseInIsolate(Response response) async {
    final receivePort = ReceivePort();

    final responseData = _ResponseData(
      response: response,
      sendPort: receivePort.sendPort,
    );

    await Isolate.spawn(_processResponseIsolate, responseData);

    final apiResponse = await receivePort.first as ApiResponse;

    // Store API response in database
    unawaitedForDio(_databaseService.addApiResponse(apiResponse));

    // Show notification if enabled
    if (showNotification) {
      _notificationService.showNotification(apiResponse,
          maxBodySize: maxNotificationBodySize);
    }
  }

  /// Process error in isolate to prevent UI freezes
  Future<void> _processErrorInIsolate(DioException error) async {
    final receivePort = ReceivePort();

    final errorData = _ErrorData(
      error: error,
      sendPort: receivePort.sendPort,
    );

    await Isolate.spawn(_processErrorIsolate, errorData);

    final apiResponse = await receivePort.first as ApiResponse;

    // Store API response in database
    unawaitedForDio(_databaseService.addApiResponse(apiResponse));

    // Show notification if enabled
    if (showNotification) {
      _notificationService.showNotification(apiResponse,
          maxBodySize: maxNotificationBodySize);
    }
  }

  /// Static method to process response in isolate
  static void _processResponseIsolate(_ResponseData data) {
    final response = data.response;
    final sendPort = data.sendPort;

    try {
      final requestTime = response.requestOptions
              .extra['smooth_chucker_request_time'] as DateTime? ??
          DateTime.now().subtract(const Duration(milliseconds: 100));

      // Extract request body
      dynamic requestBody;
      if (response.requestOptions.data != null) {
        try {
          requestBody = _extractRequestBody(response.requestOptions);
        } catch (e) {
          requestBody = {'error': 'Could not extract request body'};
        }
      }

      // Extract headers
      final headers = <String, dynamic>{};
      response.headers.forEach((name, values) {
        headers[name] = values.join(', ');
      });

      // Extract request headers
      final requestHeaders = <String, dynamic>{};
      response.requestOptions.headers.forEach((key, value) {
        requestHeaders[key] = value.toString();
      });

      // Calculate sizes
      final requestSize = _calculateRequestSize(response.requestOptions);
      final responseSize = _calculateResponseSize(response);

      // Extract API name and search keywords from request options
      final apiName =
          response.requestOptions.extra['api_name']?.toString() ?? '';
      final keywords =
          response.requestOptions.extra['search_keywords'] as List<String>? ??
              <String>[];

      // Create API response
      final apiResponse = ApiResponse(
        requestTime: requestTime,
        responseTime: DateTime.now(),
        baseUrl: response.requestOptions.baseUrl,
        path: response.requestOptions.path,
        method: response.requestOptions.method,
        statusCode: response.statusCode ?? 0,
        requestSize: requestSize,
        responseSize: responseSize,
        request: requestBody,
        body: response.data,
        contentType: response.requestOptions.contentType,
        headers: requestHeaders,
        sendTimeout: response.requestOptions.sendTimeout?.inMilliseconds ?? 0,
        responseType: response.requestOptions.responseType.name,
        receiveTimeout:
            response.requestOptions.receiveTimeout?.inMilliseconds ?? 0,
        queryParameters: response.requestOptions.queryParameters,
        connectionTimeout:
            response.requestOptions.connectTimeout?.inMilliseconds ?? 0,
        checked: false,
        clientLibrary: 'dio',
        apiName: apiName,
        searchKeywords: keywords,
      );

      sendPort.send(apiResponse);
    } catch (e) {
      debugPrint('Error processing response: $e');
      sendPort.send(ApiResponse.mock());
    }

    Isolate.exit();
  }

  /// Static method to process error in isolate
  static void _processErrorIsolate(_ErrorData data) {
    final error = data.error;
    final sendPort = data.sendPort;

    try {
      final response = error.response;
      final requestTime = error.requestOptions
              .extra['smooth_chucker_request_time'] as DateTime? ??
          DateTime.now().subtract(const Duration(milliseconds: 100));

      // Extract request body
      dynamic requestBody;
      if (error.requestOptions.data != null) {
        try {
          requestBody = _extractRequestBody(error.requestOptions);
        } catch (e) {
          requestBody = {'error': 'Could not extract request body'};
        }
      }

      // Extract headers
      final requestHeaders = <String, dynamic>{};
      error.requestOptions.headers.forEach((key, value) {
        requestHeaders[key] = value.toString();
      });

      // Calculate sizes
      final requestSize = _calculateRequestSize(error.requestOptions);
      final responseSize =
          response != null ? _calculateResponseSize(response) : 0.0;

      // Extract API name and search keywords from request options
      final apiName = error.requestOptions.extra['api_name']?.toString() ?? '';
      final keywords =
          error.requestOptions.extra['search_keywords'] as List<String>? ??
              <String>[];

      // Extract error message
      final errorMsg = error.message ?? 'Unknown error';
      final errorCode = error.response?.statusCode ?? 0;

      // Prepare error response body
      dynamic errorBody;
      if (response?.data != null) {
        errorBody = response!.data;
      } else {
        errorBody = {
          'error': errorMsg,
          'errorCode': errorCode,
          'type': error.type.toString(),
        };
      }

      // Create API response
      final apiResponse = ApiResponse(
        requestTime: requestTime,
        responseTime: DateTime.now(),
        baseUrl: error.requestOptions.baseUrl,
        path: error.requestOptions.path,
        method: error.requestOptions.method,
        statusCode: response?.statusCode ?? error.response?.statusCode ?? 0,
        requestSize: requestSize,
        responseSize: responseSize,
        request: requestBody,
        body: errorBody,
        contentType: error.requestOptions.contentType,
        headers: requestHeaders,
        sendTimeout: error.requestOptions.sendTimeout?.inMilliseconds ?? 0,
        responseType: error.requestOptions.responseType.name,
        receiveTimeout:
            error.requestOptions.receiveTimeout?.inMilliseconds ?? 0,
        queryParameters: error.requestOptions.queryParameters,
        connectionTimeout:
            error.requestOptions.connectTimeout?.inMilliseconds ?? 0,
        checked: false,
        clientLibrary: 'dio',
        apiName: apiName,
        searchKeywords: keywords,
      );

      sendPort.send(apiResponse);
    } catch (e) {
      debugPrint('Error processing error: $e');
      sendPort.send(ApiResponse.mock());
    }

    Isolate.exit();
  }

  /// Process response directly without using isolates (for mobile platforms)
  void _processResponseDirect(Response response) async {
    try {
      final requestTime = response.requestOptions
              .extra['smooth_chucker_request_time'] as DateTime? ??
          DateTime.now().subtract(const Duration(milliseconds: 100));

      // Extract request body
      dynamic requestBody;
      if (response.requestOptions.data != null) {
        try {
          requestBody = _extractRequestBody(response.requestOptions);
        } catch (e) {
          requestBody = {'error': 'Could not extract request body'};
        }
      }

      // Extract headers
      final headers = <String, dynamic>{};
      response.headers.forEach((name, values) {
        headers[name] = values.join(', ');
      });

      // Extract request headers
      final requestHeaders = <String, dynamic>{};
      response.requestOptions.headers.forEach((key, value) {
        requestHeaders[key] = value.toString();
      });

      // Calculate sizes
      final requestSize = _calculateRequestSize(response.requestOptions);
      final responseSize = _calculateResponseSize(response);

      // Extract API name and search keywords from request options
      final apiName =
          response.requestOptions.extra['api_name']?.toString() ?? '';
      final keywords =
          response.requestOptions.extra['search_keywords'] as List<String>? ??
              <String>[];

      // Create API response
      final apiResponse = ApiResponse(
        requestTime: requestTime,
        responseTime: DateTime.now(),
        baseUrl: response.requestOptions.baseUrl,
        path: response.requestOptions.path,
        method: response.requestOptions.method,
        statusCode: response.statusCode ?? 0,
        requestSize: requestSize,
        responseSize: responseSize,
        request: requestBody,
        body: response.data,
        contentType: response.requestOptions.contentType,
        headers: requestHeaders,
        sendTimeout: response.requestOptions.sendTimeout?.inMilliseconds ?? 0,
        responseType: response.requestOptions.responseType.name,
        receiveTimeout:
            response.requestOptions.receiveTimeout?.inMilliseconds ?? 0,
        queryParameters: response.requestOptions.queryParameters,
        connectionTimeout:
            response.requestOptions.connectTimeout?.inMilliseconds ?? 0,
        checked: false,
        clientLibrary: 'dio',
        apiName: apiName,
        searchKeywords: keywords,
      );

      // Store API response in database
      unawaitedForDio(_databaseService.addApiResponse(apiResponse));

      // Show notification if enabled
      if (showNotification) {
        _notificationService.showNotification(apiResponse,
            maxBodySize: maxNotificationBodySize);
      }
    } catch (e) {
      debugPrint('Error processing response directly: $e');
    }
  }

  /// Process error directly without using isolates (for mobile platforms)
  void _processErrorDirect(DioException error) async {
    try {
      final response = error.response;
      final requestTime = error.requestOptions
              .extra['smooth_chucker_request_time'] as DateTime? ??
          DateTime.now().subtract(const Duration(milliseconds: 100));

      // Extract request body
      dynamic requestBody;
      if (error.requestOptions.data != null) {
        try {
          requestBody = _extractRequestBody(error.requestOptions);
        } catch (e) {
          requestBody = {'error': 'Could not extract request body'};
        }
      }

      // Extract headers
      final requestHeaders = <String, dynamic>{};
      error.requestOptions.headers.forEach((key, value) {
        requestHeaders[key] = value.toString();
      });

      // Calculate sizes
      final requestSize = _calculateRequestSize(error.requestOptions);
      final responseSize =
          response != null ? _calculateResponseSize(response) : 0.0;

      // Extract API name and search keywords from request options
      final apiName = error.requestOptions.extra['api_name']?.toString() ?? '';
      final keywords =
          error.requestOptions.extra['search_keywords'] as List<String>? ??
              <String>[];

      // Extract error message
      final errorMsg = error.message ?? 'Unknown error';
      final errorCode = error.response?.statusCode ?? 0;

      // Prepare error response body
      dynamic errorBody;
      if (response?.data != null) {
        errorBody = response!.data;
      } else {
        errorBody = {
          'error': errorMsg,
          'errorCode': errorCode,
          'type': error.type.toString(),
        };
      }

      // Create API response
      final apiResponse = ApiResponse(
        requestTime: requestTime,
        responseTime: DateTime.now(),
        baseUrl: error.requestOptions.baseUrl,
        path: error.requestOptions.path,
        method: error.requestOptions.method,
        statusCode: response?.statusCode ?? error.response?.statusCode ?? 0,
        requestSize: requestSize,
        responseSize: responseSize,
        request: requestBody,
        body: errorBody,
        contentType: error.requestOptions.contentType,
        headers: requestHeaders,
        sendTimeout: error.requestOptions.sendTimeout?.inMilliseconds ?? 0,
        responseType: error.requestOptions.responseType.name,
        receiveTimeout:
            error.requestOptions.receiveTimeout?.inMilliseconds ?? 0,
        queryParameters: error.requestOptions.queryParameters,
        connectionTimeout:
            error.requestOptions.connectTimeout?.inMilliseconds ?? 0,
        checked: false,
        clientLibrary: 'dio',
        apiName: apiName,
        searchKeywords: keywords,
      );

      // Store API response in database
      unawaitedForDio(_databaseService.addApiResponse(apiResponse));

      // Show notification if enabled
      if (showNotification) {
        _notificationService.showNotification(apiResponse,
            maxBodySize: maxNotificationBodySize);
      }
    } catch (e) {
      debugPrint('Error processing error directly: $e');
    }
  }

  /// Helper method to calculate request size
  static double _calculateRequestSize(RequestOptions options) {
    double size = 0;

    // Add headers size
    options.headers.forEach((key, value) {
      size += key.length + (value?.toString().length ?? 0);
    });

    // Add query parameters size
    options.queryParameters.forEach((key, value) {
      size += key.length + (value?.toString().length ?? 0);
    });

    // Add request body size
    if (options.data != null) {
      final requestBody = _extractRequestBody(options);
      if (requestBody is String) {
        size += requestBody.length;
      } else if (requestBody is Map) {
        size += jsonEncode(requestBody).length;
      } else if (requestBody is List) {
        size += jsonEncode(requestBody).length;
      }
    }

    return size;
  }

  /// Helper method to calculate response size
  static double _calculateResponseSize(Response response) {
    double size = 0;

    // Add headers size
    response.headers.forEach((name, values) {
      size += name.length;
      for (final value in values) {
        size += value.length;
      }
    });

    // Add response body size
    if (response.data != null) {
      if (response.data is String) {
        size += (response.data as String).length;
      } else if (response.data is Map) {
        try {
          size += jsonEncode(response.data).length;
        } catch (e) {
          // If can't encode, estimate size
          size += response.data.toString().length;
        }
      } else if (response.data is List) {
        try {
          size += jsonEncode(response.data).length;
        } catch (e) {
          // If can't encode, estimate size
          size += response.data.toString().length;
        }
      } else {
        // For other types
        size += response.data.toString().length;
      }
    }

    return size;
  }

  /// Helper method to extract request body
  static dynamic _extractRequestBody(RequestOptions options) {
    if (options.data == null) return null;

    try {
      if (options.data is FormData) {
        final formData = options.data as FormData;
        final fields = formData.fields
            .map((e) => {'key': e.key, 'value': e.value})
            .toList();
        final files = formData.files
            .map((e) => {'key': e.key, 'value': e.value.filename})
            .toList();
        return {'fields': fields, 'files': files};
      }

      return options.data;
    } catch (e) {
      return {'error': 'Could not extract request body: ${e.toString()}'};
    }
  }
}

/// Data class for passing response to isolate
class _ResponseData {
  final Response response;
  final SendPort sendPort;

  _ResponseData({
    required this.response,
    required this.sendPort,
  });
}

/// Data class for passing error to isolate
class _ErrorData {
  final DioException error;
  final SendPort sendPort;

  _ErrorData({
    required this.error,
    required this.sendPort,
  });
}

/// Extension to mark unawaited futures
void unawaitedForDio(Future<void> future) {
  // Purposefully not awaited
}
