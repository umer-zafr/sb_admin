import 'package:flutter/material.dart';
import '../core/theme/admin_theme.dart';

class FilterDropdownItem<T> {
  const FilterDropdownItem({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

class SearchFilterBar<T> extends StatelessWidget {
  const SearchFilterBar({
    super.key,
    required this.searchController,
    required this.onSearchChanged,
    this.searchHint = 'Search records...',
    this.filterValue,
    this.filterItems,
    this.onFilterChanged,
    this.filterLabel = 'Filter',
    this.actionLabel,
    this.actionIcon = Icons.add,
    this.onAction,
    this.onRefresh,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final String searchHint;
  final T? filterValue;
  final List<FilterDropdownItem<T>>? filterItems;
  final ValueChanged<T?>? onFilterChanged;
  final String filterLabel;
  final String? actionLabel;
  final IconData actionIcon;
  final VoidCallback? onAction;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Search Input Field
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: InputDecoration(
                  hintText: searchHint,
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AdminColors.textMuted,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            searchController.clear();
                            onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),

            // Filters & Actions Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (filterItems != null && onFilterChanged != null)
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<T>(
                        value: (filterItems != null && filterItems!.any((item) => item.value == filterValue))
                            ? filterValue
                            : null,
                        hint: Text(filterLabel),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AdminColors.textPrimary,
                        ),
                        items: filterItems!.map((item) {
                          return DropdownMenuItem<T>(
                            value: item.value,
                            child: Text(item.label),
                          );
                        }).toList(),
                        onChanged: onFilterChanged,
                      ),
                    ),
                  ),

                if (onRefresh != null)
                  IconButton(
                    icon: const Icon(
                      Icons.refresh_rounded,
                      color: AdminColors.textSecondary,
                    ),
                    tooltip: 'Refresh data',
                    onPressed: onRefresh,
                  ),

                if (actionLabel != null && onAction != null)
                  ElevatedButton.icon(
                    onPressed: onAction,
                    icon: Icon(actionIcon, size: 18),
                    label: Text(actionLabel!),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
