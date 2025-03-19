import 'dart:convert';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:chopper/chopper.dart';
import 'package:provider/provider.dart';
import 'package:smooth_chucker/smooth_chucker.dart';

void main() {
  // Enable Smooth Chucker in release mode (optional)
  SmoothChucker.showOnRelease = true;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiDemoProvider()),
        ChangeNotifierProvider(create: (_) => SmoothChuckerProvider()),
      ],
      child: MaterialApp(
        title: 'Smooth Chucker Demo',
        theme: SmoothChucker.getLightTheme(Colors.indigo, Colors.teal),
        darkTheme: SmoothChucker.getDarkTheme(Colors.indigo, Colors.teal),
        themeMode: ThemeMode.system,
        navigatorObservers: [SmoothChucker.navigatorObserver],
        home: const MyHomePage(),
      ),
    );
  }
}

/// A widget that demonstrates UI smoothness with continuous animation
class SmoothnessDemonstrator extends StatefulWidget {
  const SmoothnessDemonstrator({super.key});

  @override
  State<SmoothnessDemonstrator> createState() => _SmoothnessDemonstratorState();
}

class _SmoothnessDemonstratorState extends State<SmoothnessDemonstrator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Create an animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Rotation animation
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Scale animation
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    ));

    // Color animation
    _colorAnimation = ColorTween(
      begin: Colors.blue,
      end: Colors.purple,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'UI Smoothness Indicator',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _colorAnimation.value,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _colorAnimation.value!.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform.rotate(
                          angle: -_rotationAnimation.value, // Counter-rotate
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'If this animation remains smooth\nduring API calls, isolates are working!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    // Initialize Smooth Chucker notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        SmoothChucker.initialize(Overlay.of(context));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smooth Chucker Demo'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dio'),
            Tab(text: 'HTTP'),
            Tab(text: 'Chopper'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Launch Smooth Chucker',
            onPressed: () => SmoothChucker.launch(context),
          ),
        ],
      ),
      bottomNavigationBar: const SmoothnessDemonstrator(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DioTab(),
          HttpTab(),
          ChopperTab(),
        ],
      ),
    );
  }
}

/// Dio Tab
class DioTab extends StatelessWidget {
  const DioTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiDemoProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Dio HTTP Client',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Example request cards
          _buildRequestCard(
            context: context,
            title: 'GET Request with API Name in loop',
            subtitle: 'Makes a GET request to fetch posts with API name',
            isLoading: provider.isLoadingDioGetInLoop,
            onPressed: () => provider.makeDioGetRequestInLoop(context),
          ),

          // Example request cards
          _buildRequestCard(
            context: context,
            title: 'GET Request with API Name',
            subtitle: 'Makes a GET request to fetch posts with API name',
            isLoading: provider.isLoadingDioGet,
            onPressed: () => provider.makeDioGetRequest(context),
          ),

          _buildRequestCard(
            context: context,
            title: 'POST Request',
            subtitle: 'Makes a POST request to create a post',
            isLoading: provider.isLoadingDioPost,
            onPressed: () => provider.makeDioPostRequest(context),
          ),

          _buildRequestCard(
            context: context,
            title: 'PUT Request',
            subtitle: 'Makes a PUT request to update a post',
            isLoading: provider.isLoadingDioPut,
            onPressed: () => provider.makeDioPutRequest(context),
          ),

          _buildRequestCard(
            context: context,
            title: 'Error Request',
            subtitle: 'Makes a request that will fail (404)',
            isLoading: provider.isLoadingDioError,
            onPressed: () => provider.makeDioErrorRequest(context),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

/// HTTP Tab
class HttpTab extends StatelessWidget {
  const HttpTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiDemoProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Standard HTTP Client',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Example request cards
          _buildRequestCard(
            context: context,
            title: 'GET Request',
            subtitle: 'Makes a GET request to fetch users',
            isLoading: provider.isLoadingHttpGet,
            onPressed: () => provider.makeHttpGetRequest(context),
          ),

          _buildRequestCard(
            context: context,
            title: 'POST Request',
            subtitle: 'Makes a POST request to create a user',
            isLoading: provider.isLoadingHttpPost,
            onPressed: () => provider.makeHttpPostRequest(context),
          ),

          _buildRequestCard(
            context: context,
            title: 'Error Request',
            subtitle: 'Makes a request that will fail (404)',
            isLoading: provider.isLoadingHttpError,
            onPressed: () => provider.makeHttpErrorRequest(context),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

/// Chopper Tab
class ChopperTab extends StatelessWidget {
  const ChopperTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiDemoProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Chopper HTTP Client',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Example request cards
          _buildRequestCard(
            context: context,
            title: 'GET Request with Headers',
            subtitle: 'Makes a GET request with API name in headers',
            isLoading: provider.isLoadingChopperGet,
            onPressed: () => provider.makeChopperGetRequest(context),
          ),

          _buildRequestCard(
            context: context,
            title: 'GET Request with Query Params',
            subtitle: 'Makes a GET request with API name in query params',
            isLoading: provider.isLoadingChopperGetQuery,
            onPressed: () => provider.makeChopperGetWithQueryRequest(context),
          ),

          _buildRequestCard(
            context: context,
            title: 'POST Request',
            subtitle: 'Makes a POST request to create a comment',
            isLoading: provider.isLoadingChopperPost,
            onPressed: () => provider.makeChopperPostRequest(context),
          ),

          _buildRequestCard(
            context: context,
            title: 'Error Request',
            subtitle: 'Makes a request that will fail (404)',
            isLoading: provider.isLoadingChopperError,
            onPressed: () => provider.makeChopperErrorRequest(context),
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

/// Build a request card widget
Widget _buildRequestCard({
  required BuildContext context,
  required String title,
  required String subtitle,
  required bool isLoading,
  required VoidCallback onPressed,
  Color? color,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: color != null
                  ? ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                    )
                  : null,
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Request'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Provider for the API demo app
class ApiDemoProvider extends ChangeNotifier {
  // HTTP clients
  final Dio _dio = Dio();
  final SmoothChuckerHttpClient _httpClient =
      SmoothChuckerHttpClient(http.Client());
  late final ChopperClient _chopperClient;

  // Base URL for the API
  final Uri _baseUrl = Uri.parse('https://jsonplaceholder.typicode.com');

  // Loading states
  bool _isLoadingDioGetInLoop = false;
  bool _isLoadingDioGet = false;
  bool _isLoadingDioPost = false;
  bool _isLoadingDioPut = false;
  bool _isLoadingDioError = false;

  bool _isLoadingHttpGet = false;
  bool _isLoadingHttpPost = false;
  bool _isLoadingHttpError = false;

  bool _isLoadingChopperGet = false;
  bool _isLoadingChopperGetQuery = false;
  bool _isLoadingChopperPost = false;
  bool _isLoadingChopperError = false;

  // Getters for loading states
  bool get isLoadingDioGet => _isLoadingDioGet;
  bool get isLoadingDioGetInLoop => _isLoadingDioGetInLoop;
  bool get isLoadingDioPost => _isLoadingDioPost;
  bool get isLoadingDioPut => _isLoadingDioPut;
  bool get isLoadingDioError => _isLoadingDioError;

  bool get isLoadingHttpGet => _isLoadingHttpGet;
  bool get isLoadingHttpPost => _isLoadingHttpPost;
  bool get isLoadingHttpError => _isLoadingHttpError;

  bool get isLoadingChopperGet => _isLoadingChopperGet;
  bool get isLoadingChopperGetQuery => _isLoadingChopperGetQuery;
  bool get isLoadingChopperPost => _isLoadingChopperPost;
  bool get isLoadingChopperError => _isLoadingChopperError;

  /// Constructor
  ApiDemoProvider() {
    // Initialize Dio
    _dio.interceptors.add(SmoothChuckerDioInterceptor());

    // Initialize Chopper
    _chopperClient = ChopperClient(
      baseUrl: _baseUrl,
      interceptors: [
        HttpLoggingInterceptor(),
        SmoothChuckerChopperInterceptor(),
      ],
      converter: const JsonConverter(),
    );
  }

  @override
  void dispose() {
    _httpClient.close();
    _chopperClient.dispose();
    super.dispose();
  }

  //
  // Dio methods
  //

  /// Make a GET request using Dio
  Future<void> makeDioGetRequest(BuildContext context) async {
    if (_isLoadingDioGet) return;

    _isLoadingDioGet = true;
    notifyListeners();

    try {
      // Add API name and search keywords
      _dio.options.extra['api_name'] = 'Get Posts (Dio)';
      _dio.options.extra['search_keywords'] = ['posts', 'dio', 'get'];

      final response = await _dio.get('$_baseUrl/posts');

      _showSuccessSnackBar(context, 'GET Request (Dio)',
          'Successfully fetched ${(response.data as List).length} posts');
    } catch (e) {
      _showErrorSnackBar(context, 'GET Request (Dio)', e.toString());
    } finally {
      _isLoadingDioGet = false;
      notifyListeners();
    }
  }

  /// Make a GET request using Dio
  Future<void> makeDioGetRequestInLoop(BuildContext context) async {
    if (_isLoadingDioGetInLoop) return;

    _isLoadingDioGetInLoop = true;
    notifyListeners();

    try {
      for (int i = 0; i <= 10; i++) {
        // Add API name and search keywords
        _dio.options.extra['api_name'] = 'Get Posts (Dio)';
        _dio.options.extra['search_keywords'] = ['posts', 'dio', 'get'];

        final response = await _dio.get('$_baseUrl/posts');

        _showSuccessSnackBar(context, 'GET Request (Dio)',
            'Successfully fetched ${(response.data as List).length} posts');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'GET Request (Dio)', e.toString());
    } finally {
      _isLoadingDioGetInLoop = false;
      notifyListeners();
    }
  }

  /// Make a POST request using Dio
  Future<void> makeDioPostRequest(BuildContext context) async {
    if (_isLoadingDioPost) return;

    _isLoadingDioPost = true;
    notifyListeners();

    try {
      // Add API name and search keywords
      _dio.options.extra['api_name'] = 'Create Post (Dio)';
      _dio.options.extra['search_keywords'] = [
        'posts',
        'dio',
        'post',
        'create'
      ];

      final data = {
        'title': 'New Post Title',
        'body': 'This is the content of the new post.',
        'userId': 1,
      };

      final response = await _dio.post('$_baseUrl/posts', data: data);

      _showSuccessSnackBar(context, 'POST Request (Dio)',
          'Successfully created post with ID: ${response.data['id']}');
    } catch (e) {
      _showErrorSnackBar(context, 'POST Request (Dio)', e.toString());
    } finally {
      _isLoadingDioPost = false;
      notifyListeners();
    }
  }

  /// Make a PUT request using Dio
  Future<void> makeDioPutRequest(BuildContext context) async {
    if (_isLoadingDioPut) return;

    _isLoadingDioPut = true;
    notifyListeners();

    try {
      // Add API name and search keywords
      _dio.options.extra['api_name'] = 'Update Post (Dio)';
      _dio.options.extra['search_keywords'] = ['posts', 'dio', 'put', 'update'];

      final data = {
        'id': 1,
        'title': 'Updated Post Title',
        'body': 'This post has been updated.',
        'userId': 1,
      };

      final response = await _dio.put('$_baseUrl/posts/1', data: data);

      _showSuccessSnackBar(context, 'PUT Request (Dio)',
          'Successfully updated post with ID: ${response.data['id']}');
    } catch (e) {
      _showErrorSnackBar(context, 'PUT Request (Dio)', e.toString());
    } finally {
      _isLoadingDioPut = false;
      notifyListeners();
    }
  }

  /// Make an error request using Dio
  Future<void> makeDioErrorRequest(BuildContext context) async {
    if (_isLoadingDioError) return;

    _isLoadingDioError = true;
    notifyListeners();

    try {
      // Add API name and search keywords
      _dio.options.extra['api_name'] = 'Error Request (Dio)';
      _dio.options.extra['search_keywords'] = ['error', 'dio', '404'];

      await _dio.get('$_baseUrl/nonexistent-endpoint');

      // This should not be reached
      _showSuccessSnackBar(
          context, 'Error Request (Dio)', 'Request succeeded unexpectedly');
    } catch (e) {
      // This is expected, but we'll show a success message since
      // we're demonstrating the error handling capabilities
      _showSuccessSnackBar(context, 'Error Request (Dio)',
          'Error captured successfully: ${e.runtimeType}');
    } finally {
      _isLoadingDioError = false;
      notifyListeners();
    }
  }

  //
  // HTTP methods
  //

  /// Make a GET request using HTTP
  Future<void> makeHttpGetRequest(BuildContext context) async {
    if (_isLoadingHttpGet) return;

    _isLoadingHttpGet = true;
    notifyListeners();

    try {
      final response = await _httpClient.get(Uri.parse('$_baseUrl/users'));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final users = jsonDecode(response.body) as List;
        _showSuccessSnackBar(context, 'GET Request (HTTP)',
            'Successfully fetched ${users.length} users');
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'GET Request (HTTP)', e.toString());
    } finally {
      _isLoadingHttpGet = false;
      notifyListeners();
    }
  }

  /// Make a POST request using HTTP
  Future<void> makeHttpPostRequest(BuildContext context) async {
    if (_isLoadingHttpPost) return;

    _isLoadingHttpPost = true;
    notifyListeners();

    try {
      final data = {
        'name': 'John Doe',
        'username': 'johndoe',
        'email': 'john@example.com',
      };

      final response = await _httpClient.post(
        Uri.parse('$_baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        _showSuccessSnackBar(context, 'POST Request (HTTP)',
            'Successfully created user with ID: ${responseData['id']}');
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'POST Request (HTTP)', e.toString());
    } finally {
      _isLoadingHttpPost = false;
      notifyListeners();
    }
  }

  /// Make an error request using HTTP
  Future<void> makeHttpErrorRequest(BuildContext context) async {
    if (_isLoadingHttpError) return;

    _isLoadingHttpError = true;
    notifyListeners();

    try {
      final response =
          await _httpClient.get(Uri.parse('$_baseUrl/nonexistent-endpoint'));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSuccessSnackBar(
            context, 'Error Request (HTTP)', 'Request succeeded unexpectedly');
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      // This is expected, but we'll show a success message since
      // we're demonstrating the error handling capabilities
      _showSuccessSnackBar(context, 'Error Request (HTTP)',
          'Error captured successfully: ${e.runtimeType}');
    } finally {
      _isLoadingHttpError = false;
      notifyListeners();
    }
  }

  //
  // Chopper methods
  //

  /// Make a GET request using Chopper with API name in headers
  Future<void> makeChopperGetRequest(BuildContext context) async {
    if (_isLoadingChopperGet) return;

    _isLoadingChopperGet = true;
    notifyListeners();

    try {
      // Create a request with API name in headers
      final request = Request(
        'GET',
        Uri.parse('comments'),
        _baseUrl,
        headers: {
          'X-API-Name': 'Get Comments (Chopper)',
          'X-Search-Keywords': 'comments,chopper,get,headers',
        },
      );

      final response = await _chopperClient.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final comments = response.body as List;
        _showSuccessSnackBar(context, 'GET Request (Chopper)',
            'Successfully fetched ${comments.length} comments');
      } else {
        throw Exception('Chopper Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'GET Request (Chopper)', e.toString());
    } finally {
      _isLoadingChopperGet = false;
      notifyListeners();
    }
  }

  /// Make a GET request using Chopper with API name in query parameters
  Future<void> makeChopperGetWithQueryRequest(BuildContext context) async {
    if (_isLoadingChopperGetQuery) return;

    _isLoadingChopperGetQuery = true;
    notifyListeners();

    try {
      // Create a request with API name in query parameters
      final queryParams = {
        'apiName': 'Get Albums (Chopper)',
        'searchKeywords': 'albums,chopper,get,query',
        '_limit': '10', // Add actual query parameter for the API
      };

      final queryString = Uri(queryParameters: queryParams).query;

      final request = Request(
        'GET',
        Uri.parse('albums?$queryString'),
        _baseUrl,
      );

      final response = await _chopperClient.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final albums = response.body as List;
        _showSuccessSnackBar(context, 'GET Request with Query (Chopper)',
            'Successfully fetched ${albums.length} albums');
      } else {
        throw Exception('Chopper Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar(
          context, 'GET Request with Query (Chopper)', e.toString());
    } finally {
      _isLoadingChopperGetQuery = false;
      notifyListeners();
    }
  }

  /// Make a POST request using Chopper
  Future<void> makeChopperPostRequest(BuildContext context) async {
    if (_isLoadingChopperPost) return;

    _isLoadingChopperPost = true;
    notifyListeners();

    try {
      final data = {
        'postId': 1,
        'name': 'John Doe',
        'email': 'john@example.com',
        'body': 'This is a comment created with Chopper.',
      };

      // Create a request with API name in headers
      final request = Request(
        'POST',
        Uri.parse('comments'),
        _baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'X-API-Name': 'Create Comment (Chopper)',
          'X-Search-Keywords': 'comments,chopper,post,create',
        },
        body: data,
      );

      final response = await _chopperClient.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSuccessSnackBar(context, 'POST Request (Chopper)',
            'Successfully created comment with ID: ${response.body['id']}');
      } else {
        throw Exception('Chopper Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorSnackBar(context, 'POST Request (Chopper)', e.toString());
    } finally {
      _isLoadingChopperPost = false;
      notifyListeners();
    }
  }

  /// Make an error request using Chopper
  Future<void> makeChopperErrorRequest(BuildContext context) async {
    if (_isLoadingChopperError) return;

    _isLoadingChopperError = true;
    notifyListeners();

    try {
      // Create a request with API name in headers
      final request = Request(
        'GET',
        Uri.parse('nonexistent-endpoint'),
        _baseUrl,
        headers: {
          'X-API-Name': 'Error Request (Chopper)',
          'X-Search-Keywords': 'error,chopper,404',
        },
      );

      final response = await _chopperClient.send(request);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _showSuccessSnackBar(context, 'Error Request (Chopper)',
            'Request succeeded unexpectedly');
      } else {
        throw Exception('Chopper Error: ${response.statusCode}');
      }
    } catch (e) {
      // This is expected, but we'll show a success message since
      // we're demonstrating the error handling capabilities
      _showSuccessSnackBar(context, 'Error Request (Chopper)',
          'Error captured successfully: ${e.runtimeType}');
    } finally {
      _isLoadingChopperError = false;
      notifyListeners();
    }
  }

  //
  // Helper methods
  //

  /// Show a success snackbar
  void _showSuccessSnackBar(
      BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            SmoothChucker.launch(context);
          },
        ),
      ),
    );
  }

  /// Show an error snackbar
  void _showErrorSnackBar(BuildContext context, String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Error: $title',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            SmoothChucker.launch(context);
          },
        ),
      ),
    );
  }
}
