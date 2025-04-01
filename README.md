# Smooth Chucker

An enhanced HTTP requests inspector for Flutter applications inspired by [Chucker Flutter](https://github.com/ChuckerTeam/chucker) but built with improved performance and modern design.

Smooth Chucker inspects HTTP(S) requests and responses in your Flutter app. It works as an interceptor for popular HTTP client libraries and stores network requests and responses in local storage, providing a Material 3 UI for inspecting and sharing content.

<img src="https://github.com/user-attachments/assets/2db9157d-7b79-4711-abbd-d89b199478de" width="180" height="350">
<img src="https://github.com/user-attachments/assets/3e7cc950-ca4a-45b2-ac18-cd846328ac5c" width="180" height="350">
<img src="https://github.com/user-attachments/assets/edb7642f-6c91-48f6-8518-de5aa603e32b" width="180" height="350">


## Features

- 🚀 **Isolate Support**: Background processing to prevent UI freezes while handling network requests
- 🎨 **Material 3 Design**: Modern, beautiful interface that follows latest design guidelines
- 🔍 **Advanced Search**: Search by API name, method, status code, and more
- 💾 **Multiple Client Support**: Works with Dio, Http, and Chopper HTTP clients
- 🖥️ **Cross-Platform**: Works on Android, iOS, Web, Windows, macOS, and Linux
- 🔔 **In-App Notifications**: See request status and details as they happen
- 🔄 **JSON Tree View**: Visualize JSON responses in both tree and raw formats
- 📋 **Sharing & Copying**: Export as cURL commands, share with colleagues
- ⚙️ **Customizable**: Themes, notification settings, and more

## Getting Started

### 1. Add the dependency

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  smooth_chucker: any
```

Or run:

```
flutter pub add smooth_chucker
```

### 2. Add Interceptor to your HTTP client

#### For Dio:

```dart
import 'package:dio/dio.dart';
import 'package:smooth_chucker/smooth_chucker.dart';

final dio = Dio();
dio.interceptors.add(SmoothChuckerDioInterceptor());
```

#### For Http:

```dart
import 'package:http/http.dart' as http;
import 'package:smooth_chucker/smooth_chucker.dart';

final client = SmoothChuckerHttpClient(http.Client());
client.get(Uri.parse('https://api.example.com/data'));
```

#### For Chopper:

```dart
import 'package:chopper/chopper.dart';
import 'package:smooth_chucker/smooth_chucker.dart';

final client = ChopperClient(
  baseUrl: 'https://api.example.com',
  interceptors: [
    SmoothChuckerChopperInterceptor(),
  ],
);
```

### 3. Add the Navigator Observer

In your MaterialApp:

```dart
import 'package:smooth_chucker/smooth_chucker.dart';

@override
Widget build(BuildContext context) {
  return MaterialApp(
    navigatorObservers: [SmoothChucker.navigatorObserver],
    // ...
  );
}
```

### 4. Initialize Notifications (optional but recommended)

In your app's root widget:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    SmoothChucker.initialize(Overlay.of(context)!);
  });
}
```

### 5. Launch the UI

Add a button to launch the Smooth Chucker UI:

```dart
ElevatedButton(
  onPressed: () => SmoothChucker.launch(context),
  child: const Text('Launch Smooth Chucker'),
)
```

## Customization

### Enable in Release Mode

By default, Smooth Chucker only runs in debug mode. You can enable it in release mode:

```dart
void main() {
  SmoothChucker.showOnRelease = true;
  runApp(const MyApp());
}
```

### API Name and Search Keywords

When using Dio, you can add custom API names and search keywords:

```dart
final dio = Dio();
dio.options.extra['api_name'] = 'User Authentication';
dio.options.extra['search_keywords'] = ['login', 'auth', 'user'];
```

## Advanced Usage

### Controlling Notifications

```dart
// Disable notifications
SmoothChucker.setNotificationsEnabled(false);
```

### Manually Adding API Responses

```dart
import 'package:smooth_chucker/smooth_chucker.dart';

final apiResponse = ApiResponse(
  // ... required parameters
  apiName: 'Custom API Call',
  searchKeywords: ['custom', 'test'],
);

// Use DatabaseService to add the response
final dbService = DatabaseService();
await dbService.addApiResponse(apiResponse);
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
