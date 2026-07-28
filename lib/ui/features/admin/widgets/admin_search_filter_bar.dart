import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class AdminSearchFilterBar<T> extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final String searchHint;
  final List<T> filterOptions;
  final T? selectedFilter;
  final ValueChanged<T?> onFilterSelected;
  final String Function(T) getLabel;

  const AdminSearchFilterBar({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClearSearch,
    this.searchHint = 'Buscar...',
    required this.filterOptions,
    required this.selectedFilter,
    required this.onFilterSelected,
    required this.getLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Buscador por Texto
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.secondaryColor.withValues(alpha: 0.15),
              ),
            ),
            child: TextField(
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: onClearSearch,
                      )
                    : null,
              ),
            ),
          ),
        ),

        // Filtros por Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              FilterChip(
                label: const Text('Todos'),
                selected: selectedFilter == null,
                onSelected: (_) => onFilterSelected(null),
                selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                checkmarkColor: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              ...filterOptions.map((item) {
                final isSelected = selectedFilter == item;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(getLabel(item)),
                    selected: isSelected,
                    onSelected: (_) {
                      onFilterSelected(isSelected ? null : item);
                    },
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
