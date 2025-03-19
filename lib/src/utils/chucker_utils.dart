import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class for SmoothChucker
class SmoothChuckerUtils {
  /// Whether to show SmoothChucker on release builds
  static bool showOnRelease = false;

  /// Navigator observer for SmoothChucker
  static final _navigatorObserver = _SmoothChuckerNavigatorObserver();

  /// Get the navigator observer
  static NavigatorObserver get navigatorObserver =>
      _navigatorObserver;

  /// Check if the current environment should intercept requests
  static bool shouldInterceptRequest() {
    if (kReleaseMode) {
      return showOnRelease;
    }
    return true;
  }

  /// Format bytes to human-readable format
  static String formatBytes(double bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// Format duration to human-readable format
  static String formatDuration(Duration duration) {
    final milliseconds = duration.inMilliseconds;
    if (milliseconds < 1000) {
      return '$milliseconds ms';
    } else {
      final seconds = (milliseconds / 1000).toStringAsFixed(2);
      return '$seconds s';
    }
  }

  /// Get the color for a status code
  static int getStatusCodeColor(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return 0xFF4CAF50; // Green
    } else if (statusCode >= 300 && statusCode < 400) {
      return 0xFFFFA000; // Amber
    } else if (statusCode >= 400 && statusCode < 500) {
      return 0xFFFF9800; // Orange
    } else if (statusCode >= 500) {
      return 0xFFF44336; // Red
    } else {
      return 0xFF9E9E9E; // Grey
    }
  }

  /// Get readable duration
  static String getReadableDuration(Duration duration) {
    if (duration.inMilliseconds < 1) {
      return '0 ms';
    } else if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds} ms';
    } else if (duration.inSeconds < 60) {
      return '${(duration.inMilliseconds / 1000).toStringAsFixed(2)} s';
    } else {
      return '${duration.inMinutes} min ${duration.inSeconds % 60} s';
    }
  }

  /// Format date to readable format
  static String formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  /// Check if a string is valid JSON
  static bool isValidJson(String text) {
    try {
      jsonDecode(text);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Format JSON string with indentation
  static String formatJsonString(String jsonString) {
    try {
      const encoder = JsonEncoder.withIndent('  ');
      final object = jsonDecode(jsonString);
      return encoder.convert(object);
    } catch (e) {
      return jsonString;
    }
  }

  /// Extract file extension from URL
  static String? getFileExtensionFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final lastDotIndex = path.lastIndexOf('.');
      if (lastDotIndex != -1) {
        return path.substring(lastDotIndex + 1).toLowerCase();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get API name from Chopper request
  static String? getApiNameFromRequest(dynamic request) {
    // We use dynamic type since Chopper doesn't have a standard way to attach metadata
    // Developers can add custom headers or query parameters for this
    try {
      if (request == null) return null;

      // Check custom header first
      if (request.headers.containsKey('X-API-Name')) {
        return request.headers['X-API-Name'];
      }

      // Check query parameters
      if (request.url.queryParameters.containsKey('apiName')) {
        return request.url.queryParameters['apiName'];
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get search keywords from Chopper request
  static List<String>? getSearchKeywordsFromRequest(dynamic request) {
    try {
      if (request == null) return null;

      // Check custom header first
      if (request.headers.containsKey('X-Search-Keywords')) {
        final keywordsStr = request.headers['X-Search-Keywords'];
        if (keywordsStr != null && keywordsStr.isNotEmpty) {
          return keywordsStr.split(',').map((s) => s.trim()).toList();
        }
      }

      // Check query parameters
      if (request.url.queryParameters.containsKey('searchKeywords')) {
        final keywordsStr = request.url.queryParameters['searchKeywords'];
        if (keywordsStr != null && keywordsStr.isNotEmpty) {
          return keywordsStr.split(',').map((s) => s.trim()).toList();
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if URL points to an image
  static bool isImageUrl(String url) {
    final imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp', 'svg'];
    final extension = getFileExtensionFromUrl(url);
    return extension != null && imageExtensions.contains(extension);
  }
}

/// Navigator observer for SmoothChucker
class _SmoothChuckerNavigatorObserver extends NavigatorObserver {}
