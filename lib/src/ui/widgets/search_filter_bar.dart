import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/chucker_provider.dart';

/// Widget to display active search filters
class SearchFilterBar extends StatelessWidget {
  /// Constructor
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SmoothChuckerProvider>(
      builder: (context, provider, child) {
        final hasFilters = provider.apiNameFilter.isNotEmpty ||
            provider.methodFilter != null ||
            provider.statusCodeFilter != null;

        if (!hasFilters) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.5),
          child: Row(
            children: [
              const Icon(
                Icons.filter_list,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (provider.apiNameFilter.isNotEmpty)
                        _buildFilterChip(
                          context,
                          'API: ${provider.apiNameFilter}',
                          () => provider.setApiNameFilter(''),
                        ),
                      if (provider.methodFilter != null)
                        _buildFilterChip(
                          context,
                          'Method: ${provider.methodFilter}',
                          () => provider.setMethodFilter(null),
                        ),
                      if (provider.statusCodeFilter != null)
                        _buildFilterChip(
                          context,
                          'Status: ${provider.statusCodeFilter}',
                          () => provider.setStatusCodeFilter(null),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: () => provider.clearFilters(),
                iconSize: 16,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build a filter chip widget
  Widget _buildFilterChip(
    BuildContext context,
    String label,
    VoidCallback onRemove,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        deleteIcon: const Icon(
          Icons.clear,
          size: 14,
        ),
        onDeleted: onRemove,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }
}
