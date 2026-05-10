import 'package:flutter/material.dart';

enum TaskFilter { all, today, upcoming, completed }

extension TaskFilterLabel on TaskFilter {
  String get label => switch (this) {
        TaskFilter.all => 'All',
        TaskFilter.today => 'Today',
        TaskFilter.upcoming => 'Upcoming',
        TaskFilter.completed => 'Completed',
      };
}

class FilterChipBar extends StatelessWidget {
  const FilterChipBar({super.key, required this.selected, required this.onChanged});

  final TaskFilter selected;
  final ValueChanged<TaskFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final filter = TaskFilter.values[index];
          return ChoiceChip(
            label: Text(filter.label),
            selected: selected == filter,
            onSelected: (_) => onChanged(filter),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemCount: TaskFilter.values.length,
      ),
    );
  }
}
