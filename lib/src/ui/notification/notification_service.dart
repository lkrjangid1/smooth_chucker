import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/api_response.dart';
import '../../utils/chucker_utils.dart';
import '../screens/api_detail_screen.dart';

/// Service for displaying in-app notifications for API requests
class NotificationService {
  /// Overlay state
  static OverlayState? _overlayState;

  /// Current notification entry
  static OverlayEntry? _currentNotification;

  /// Timer for auto-dismissing notifications
  static Timer? _dismissTimer;

  /// Default notification duration in seconds
  static int _notificationDuration = 5;

  /// Whether notifications are enabled
  static bool _notificationsEnabled = true;

  /// Constructor
  NotificationService();

  /// Set the overlay state
  static void setOverlayState(OverlayState? overlayState) {
    _overlayState = overlayState;
  }

  /// Enable or disable notifications
  static void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
  }

  /// Set notification duration in seconds
  static void setNotificationDuration(int seconds) {
    _notificationDuration = seconds;
  }

  /// Show notification for an API response
  void showNotification(ApiResponse apiResponse, {int maxBodySize = 1024}) {
    if (!_notificationsEnabled || _overlayState == null) return;

    // Remove any existing notification
    _dismissCurrentNotification();

    // Create a new notification
    _currentNotification = _createNotification(apiResponse, maxBodySize);

    // Show the notification
    _overlayState!.insert(_currentNotification!);

    // Set up auto-dismiss timer
    _dismissTimer = Timer(Duration(seconds: _notificationDuration), () {
      _dismissCurrentNotification();
    });
  }

  /// Create an overlay entry for notification
  OverlayEntry _createNotification(ApiResponse apiResponse, int maxBodySize) {
    return OverlayEntry(
      builder: (context) {
        // Get screen size
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;

        // Calculate notification width
        final notificationWidth = screenWidth * 0.9;

        // Get status code color
        final statusCodeColor =
            SmoothChuckerUtils.getStatusCodeColor(apiResponse.statusCode);

        // Format response body snippet
        String bodySnippet = '';
        if (apiResponse.body != null) {
          if (apiResponse.body is Map || apiResponse.body is List) {
            try {
              final jsonString =
                  const JsonEncoder.withIndent('  ').convert(apiResponse.body);
              bodySnippet = jsonString.length > maxBodySize
                  ? '${jsonString.substring(0, maxBodySize)}...'
                  : jsonString;
            } catch (e) {
              bodySnippet = 'Error formatting response body';
            }
          } else if (apiResponse.body is String) {
            final str = apiResponse.body as String;
            bodySnippet = str.length > maxBodySize
                ? '${str.substring(0, maxBodySize)}...'
                : str;
          }
        }

        return Positioned(
          top: screenHeight * 0.05,
          left: (screenWidth - notificationWidth) / 2,
          width: notificationWidth,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    top: BorderSide(
                      color: Color(statusCodeColor),
                      width: 4,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(statusCodeColor),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              apiResponse.statusCode.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            apiResponse.method,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyMedium?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              apiResponse.path,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _dismissCurrentNotification,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),
                    if (bodySnippet.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          constraints: const BoxConstraints(
                            maxHeight: 100,
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              bodySnippet,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            SmoothChuckerUtils.getReadableDuration(
                                apiResponse.duration),
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              _dismissCurrentNotification();
                              _navigateToDetails(context, apiResponse);
                            },
                            child: const Text('View Details'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Navigate to API details screen
  void _navigateToDetails(BuildContext context, ApiResponse apiResponse) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ApiDetailScreen(apiResponse: apiResponse),
      ),
    );
  }

  /// Dismiss the current notification
  static void _dismissCurrentNotification() {
    _dismissTimer?.cancel();
    _dismissTimer = null;

    if (_currentNotification != null) {
      _currentNotification!.remove();
      _currentNotification = null;
    }
  }
}
