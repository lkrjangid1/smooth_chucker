import 'package:flutter/material.dart';

import '../../models/api_response.dart';
import '../../utils/chucker_utils.dart';

/// Widget for displaying an API response in a list
class ApiListItem extends StatelessWidget {
  /// The API response to display
  final ApiResponse apiResponse;

  /// Callback when tapped
  final VoidCallback onTap;

  /// Constructor
  const ApiListItem({
    super.key,
    required this.apiResponse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusCodeColor =
        Color(SmoothChuckerUtils.getStatusCodeColor(apiResponse.statusCode));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: statusCodeColor,
                width: 8,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Method (GET, POST, etc)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusCodeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        apiResponse.method,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status code
                    Text(
                      apiResponse.statusCode.toString(),
                      style: TextStyle(
                        color: statusCodeColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Spacer(),

                    // Time
                    Text(
                      SmoothChuckerUtils.formatDate(apiResponse.requestTime),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // URL path
                Text(
                  apiResponse.path,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Base URL
                Text(
                  apiResponse.baseUrl,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Bottom row with API name and duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // API Name or client library
                    Text(
                      apiResponse.apiName.isNotEmpty
                          ? apiResponse.apiName
                          : apiResponse.clientLibrary,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),

                    // Duration
                    Text(
                      SmoothChuckerUtils.getReadableDuration(
                          apiResponse.duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
