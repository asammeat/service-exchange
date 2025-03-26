import 'package:flutter/material.dart';

class FilterBar extends StatelessWidget {
  final List<String> filterOptions;
  final int selectedIndex;
  final Function(int) onFilterSelected;

  const FilterBar({
    Key? key,
    required this.filterOptions,
    required this.selectedIndex,
    required this.onFilterSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filterOptions.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              label: Text(filterOptions[index]),
              selected: isSelected,
              onSelected: (_) => onFilterSelected(index),
              backgroundColor: isSelected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Theme.of(context).colorScheme.surface,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
