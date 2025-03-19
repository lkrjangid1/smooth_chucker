import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/api_response.dart';
import '../../providers/chucker_provider.dart';
import '../../utils/chucker_utils.dart';
import '../widgets/json_viewer_panel.dart';
import '../widgets/key_value_widget.dart';

/// Screen showing details of an API request
class ApiDetailScreen extends StatefulWidget {
  /// The API response to display
  final ApiResponse apiResponse;

  /// Constructor
  const ApiDetailScreen({
    super.key,
    required this.apiResponse,
  });

  @override
  State<ApiDetailScreen> createState() => _ApiDetailScreenState();
}

class _ApiDetailScreenState extends State<ApiDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusCodeColor = Color(
        SmoothChuckerUtils.getStatusCodeColor(widget.apiResponse.statusCode));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.apiResponse.method} ${widget.apiResponse.path}'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Request'),
            Tab(text: 'Response'),
            Tab(text: 'Headers'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareApiResponse,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyAsCurl,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmationDialog();
              }
            },
            itemBuilder: (context) {
              return [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: statusCodeColor,
            child: Row(
              children: [
                Text(
                  widget.apiResponse.statusCode.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.apiResponse.apiName.isNotEmpty
                      ? widget.apiResponse.apiName
                      : widget.apiResponse.path,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  SmoothChuckerUtils.getReadableDuration(
                      widget.apiResponse.duration),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRequestTab(),
                _buildResponseTab(),
                _buildHeadersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build the overview tab
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyValueWidget(
                    keyText: 'URL',
                    valueText:
                        '${widget.apiResponse.baseUrl}${widget.apiResponse.path}',
                    canCopy: true,
                  ),
                  const SizedBox(height: 8),
                  KeyValueWidget(
                    keyText: 'Method',
                    valueText: widget.apiResponse.method,
                    canCopy: true,
                  ),
                  const SizedBox(height: 8),
                  KeyValueWidget(
                    keyText: 'Client',
                    valueText: widget.apiResponse.clientLibrary,
                  ),
                  if (widget.apiResponse.apiName.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    KeyValueWidget(
                      keyText: 'API Name',
                      valueText: widget.apiResponse.apiName,
                    ),
                  ],
                  const SizedBox(height: 8),
                  KeyValueWidget(
                    keyText: 'Request Time',
                    valueText: SmoothChuckerUtils.formatDate(
                        widget.apiResponse.requestTime),
                  ),
                  const SizedBox(height: 8),
                  KeyValueWidget(
                    keyText: 'Response Time',
                    valueText: SmoothChuckerUtils.formatDate(
                        widget.apiResponse.responseTime),
                  ),
                  const SizedBox(height: 8),
                  KeyValueWidget(
                    keyText: 'Duration',
                    valueText: SmoothChuckerUtils.getReadableDuration(
                        widget.apiResponse.duration),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('Copy as cURL'),
                        onPressed: _copyAsCurl,
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Response Info',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KeyValueWidget(
                    keyText: 'Status Code',
                    valueText:
                        '${widget.apiResponse.statusCode} (${widget.apiResponse.statusType})',
                    valueColor: Color(SmoothChuckerUtils.getStatusCodeColor(
                        widget.apiResponse.statusCode)),
                  ),
                  const SizedBox(height: 8),
                  KeyValueWidget(
                    keyText: 'Response Type',
                    valueText: widget.apiResponse.responseType,
                  ),
                  const SizedBox(height: 8),
                  KeyValueWidget(
                    keyText: 'Request Size',
                    valueText: SmoothChuckerUtils.formatBytes(
                        widget.apiResponse.requestSize),
                  ),
                  const SizedBox(height: 8),
                  KeyValueWidget(
                    keyText: 'Response Size',
                    valueText: SmoothChuckerUtils.formatBytes(
                        widget.apiResponse.responseSize),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the request tab
  Widget _buildRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.apiResponse.queryParameters.isNotEmpty) ...[
            const Text(
              'Query Parameters',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      widget.apiResponse.queryParameters.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: KeyValueWidget(
                        keyText: entry.key,
                        valueText: entry.value.toString(),
                        canCopy: true,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Request Body',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildRequestBodyWidget(),
        ],
      ),
    );
  }

  /// Build the response tab
  Widget _buildResponseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response Body',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildResponseBodyWidget(),
        ],
      ),
    );
  }

  /// Build the headers tab
  Widget _buildHeadersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Request Headers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.apiResponse.headers.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: KeyValueWidget(
                      keyText: entry.key,
                      valueText: entry.value.toString(),
                      canCopy: true,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the request body widget
  Widget _buildRequestBodyWidget() {
    if (widget.apiResponse.request == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No request body'),
        ),
      );
    }

    if (widget.apiResponse.request is Map ||
        widget.apiResponse.request is List) {
      return JsonViewerPanel(
        jsonData: widget.apiResponse.request,
        title: 'Request Body',
      );
    } else if (widget.apiResponse.request is String) {
      final requestString = widget.apiResponse.request as String;
      if (SmoothChuckerUtils.isValidJson(requestString)) {
        try {
          final jsonData = jsonDecode(requestString);
          return JsonViewerPanel(
            jsonData: jsonData,
            title: 'Request Body',
          );
        } catch (e) {
          // Fall back to showing as string
        }
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: requestString));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request body copied to clipboard'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SelectableText(requestString),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(widget.apiResponse.request.toString()),
      ),
    );
  }

  /// Build the response body widget
  Widget _buildResponseBodyWidget() {
    if (widget.apiResponse.body == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No response body'),
        ),
      );
    }

    // Check for image response
    final contentType = widget.apiResponse.headers['content-type'] ??
        widget.apiResponse.headers['Content-Type'] ??
        '';
    if (contentType.toString().startsWith('image/')) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Image Response'),
              const SizedBox(height: 8),
              Image.network(
                '${widget.apiResponse.baseUrl}${widget.apiResponse.path}',
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Failed to load image');
                },
              ),
            ],
          ),
        ),
      );
    }

    // JSON response
    if (widget.apiResponse.body is Map || widget.apiResponse.body is List) {
      return JsonViewerPanel(
        jsonData: widget.apiResponse.body,
        title: 'Response Body',
      );
    } else if (widget.apiResponse.body is String) {
      final responseString = widget.apiResponse.body as String;
      if (SmoothChuckerUtils.isValidJson(responseString)) {
        try {
          final jsonData = jsonDecode(responseString);
          return JsonViewerPanel(
            jsonData: jsonData,
            title: 'Response Body',
          );
        } catch (e) {
          // Fall back to showing as string
        }
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: responseString));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Response body copied to clipboard'),
                        ),
                      );
                    },
                  ),
                ],
              ),
              SelectableText(responseString),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(widget.apiResponse.body.toString()),
      ),
    );
  }

  /// Share API response
  void _shareApiResponse() async {
    final text = widget.apiResponse.toString();
    await Share.share(text, subject: 'API Response Details');
  }

  /// Copy as cURL command
  void _copyAsCurl() async {
    final curlCommand = widget.apiResponse.toCurl();
    await Clipboard.setData(ClipboardData(text: curlCommand));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('cURL command copied to clipboard'),
        ),
      );
    }
  }

  /// Show confirmation dialog for deleting request
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Request'),
          content:
              const Text('Are you sure you want to delete this API request?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context
                    .read<SmoothChuckerProvider>()
                    .deleteApiResponse(widget.apiResponse);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
