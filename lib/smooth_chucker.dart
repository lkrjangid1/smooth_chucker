library;

import 'package:flutter/material.dart';

import 'src/ui/notification/notification_service.dart';
import 'src/ui/screens/api_list_screen.dart';
import 'src/utils/chucker_utils.dart';

export 'src/interceptors/chopper_interceptor.dart';
export 'src/interceptors/dio_interceptor.dart';
export 'src/interceptors/http_client.dart';
export 'src/models/api_response.dart';
export 'src/providers/chucker_provider.dart';

/// Main entry point for SmoothChucker package
class SmoothChucker {
  /// Whether to show SmoothChucker on release builds
  static bool get showOnRelease => SmoothChuckerUtils.showOnRelease;

  /// Set whether to show SmoothChucker on release builds
  static set showOnRelease(bool value) {
    SmoothChuckerUtils.showOnRelease = value;
  }

  /// The navigator observer for SmoothChucker
  static NavigatorObserver get navigatorObserver =>
      SmoothChuckerUtils.navigatorObserver;

  /// Launch the SmoothChucker UI
  static void launch(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ApiListScreen(),
      ),
    );
  }

  /// Initialize SmoothChucker with the provided overlay state
  static void initialize(OverlayState overlayState) {
    NotificationService.setOverlayState(overlayState);
  }

  /// Set whether notifications are enabled
  static void setNotificationsEnabled(bool enabled) {
    NotificationService.setNotificationsEnabled(enabled);
  }

  /// Set notification duration in seconds
  static void setNotificationDuration(int seconds) {
    NotificationService.setNotificationDuration(seconds);
  }
}
