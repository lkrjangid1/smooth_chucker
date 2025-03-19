import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chucker_provider.dart';
import '../../utils/chucker_utils.dart';
import '../notification/notification_service.dart';
import '../widgets/color_picker_dialog.dart';

/// Settings screen for SmoothChucker
class SettingsScreen extends StatelessWidget {
  /// Constructor
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<SmoothChuckerProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildThemeSection(context, provider),
              const Divider(height: 32),
              _buildNotificationSection(context, provider),
              const Divider(height: 32),
              _buildStorageSection(context, provider),
              const Divider(height: 32),
              _buildInfoSection(context),
            ],
          );
        },
      ),
    );
  }

  /// Build theme settings section
  Widget _buildThemeSection(
      BuildContext context, SmoothChuckerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Theme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Theme Mode'),
          subtitle: Text(_getThemeModeText(provider.themeMode)),
          trailing: DropdownButton<ThemeMode>(
            value: provider.themeMode,
            onChanged: (value) {
              if (value != null) {
                provider.setThemeMode(value);
              }
            },
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark'),
              ),
            ],
            underline: const SizedBox(), // Remove underline
          ),
        ),
        ListTile(
          title: const Text('Primary Color'),
          subtitle: const Text('The main color used in the app'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: provider.primaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
          ),
          onTap: () {
            _showColorPickerDialog(
              context,
              'Primary Color',
              provider.primaryColor,
              (color) => provider.setPrimaryColor(color),
            );
          },
        ),
        ListTile(
          title: const Text('Secondary Color'),
          subtitle: const Text('The accent color used in the app'),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: provider.secondaryColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey),
            ),
          ),
          onTap: () {
            _showColorPickerDialog(
              context,
              'Secondary Color',
              provider.secondaryColor,
              (color) => provider.setSecondaryColor(color),
            );
          },
        ),
      ],
    );
  }

  /// Build notification settings section
  Widget _buildNotificationSection(
      BuildContext context, SmoothChuckerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Show Notifications'),
          subtitle: const Text('Show in-app notifications for API requests'),
          value: provider.notificationsEnabled,
          onChanged: (value) {
            provider.setNotificationsEnabled(value);
            // Update notification service
            NotificationService.setNotificationsEnabled(value);
          },
        ),
        ListTile(
          title: const Text('Max Notification Body Size'),
          subtitle: Text(SmoothChuckerUtils.formatBytes(
              provider.maxNotificationBodySize.toDouble())),
          trailing: DropdownButton<int>(
            value: provider.maxNotificationBodySize,
            onChanged: provider.notificationsEnabled
                ? (value) {
                    if (value != null) {
                      provider.setMaxNotificationBodySize(value);
                    }
                  }
                : null,
            items: const [
              DropdownMenuItem(
                value: 512,
                child: Text('512 B'),
              ),
              DropdownMenuItem(
                value: 1024,
                child: Text('1 KB'),
              ),
              DropdownMenuItem(
                value: 2048,
                child: Text('2 KB'),
              ),
              DropdownMenuItem(
                value: 4096,
                child: Text('4 KB'),
              ),
            ],
            underline: const SizedBox(), // Remove underline
          ),
        ),
        ListTile(
          title: const Text('Notification Duration'),
          subtitle: const Text('How long notifications stay on screen'),
          trailing: DropdownButton<int>(
            value: provider.notificationDuration,
            onChanged: provider.notificationsEnabled
                ? (value) {
                    if (value != null) {
                      provider.setNotificationDuration(value);
                    }
                  }
                : null,
            items: const [
              DropdownMenuItem(
                value: 3,
                child: Text('3 seconds'),
              ),
              DropdownMenuItem(
                value: 5,
                child: Text('5 seconds'),
              ),
              DropdownMenuItem(
                value: 8,
                child: Text('8 seconds'),
              ),
              DropdownMenuItem(
                value: 10,
                child: Text('10 seconds'),
              ),
            ],
            underline: const SizedBox(), // Remove underline
          ),
        ),
      ],
    );
  }

  /// Build storage settings section
  Widget _buildStorageSection(
      BuildContext context, SmoothChuckerProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Storage',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Maximum Stored Requests'),
          subtitle: const Text('Older requests will be deleted automatically'),
          trailing: DropdownButton<int>(
            value: provider.maxStoredRequests,
            onChanged: (value) {
              if (value != null) {
                provider.setMaxStoredRequests(value);
              }
            },
            items: const [
              DropdownMenuItem(
                value: 50,
                child: Text('50'),
              ),
              DropdownMenuItem(
                value: 100,
                child: Text('100'),
              ),
              DropdownMenuItem(
                value: 200,
                child: Text('200'),
              ),
              DropdownMenuItem(
                value: 500,
                child: Text('500'),
              ),
            ],
            underline: const SizedBox(), // Remove underline
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          title: const Text('Clear All Data'),
          subtitle: const Text('Delete all stored API requests'),
          trailing: ElevatedButton(
            onPressed: () => _showClearDataDialog(context, provider),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear'),
          ),
        ),
      ],
    );
  }

  /// Build info section
  Widget _buildInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const ListTile(
          title: Text('Smooth Chucker'),
          subtitle: Text('An HTTP requests inspector for Flutter'),
        ),
        const ListTile(
          title: Text('Version'),
          subtitle: Text('1.0.0'),
        ),
        const ListTile(
          title: Text('Features'),
          subtitle: Text('• Material 3 Design\n'
              '• Isolate support for background processing\n'
              '• Advanced search by API name\n'
              '• Support for Dio, Http, and Chopper'),
        ),
      ],
    );
  }

  /// Show color picker dialog
  void _showColorPickerDialog(
    BuildContext context,
    String title,
    Color initialColor,
    Function(Color) onColorSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return ColorPickerDialog(
          title: title,
          initialColor: initialColor,
          onColorSelected: onColorSelected,
        );
      },
    );
  }

  /// Show clear data confirmation dialog
  void _showClearDataDialog(
      BuildContext context, SmoothChuckerProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data'),
          content: const Text(
            'Are you sure you want to delete all stored API requests? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                provider.deleteAllApiResponses();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All data has been cleared'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  /// Get text representation of theme mode
  String _getThemeModeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return 'Follow system settings';
      case ThemeMode.light:
        return 'Light theme';
      case ThemeMode.dark:
        return 'Dark theme';
    }
  }
}
