import 'package:flutter/material.dart';

import '../../domain/todo.dart';

class TodoStatusChip extends StatelessWidget {
  const TodoStatusChip({super.key, required this.status});

  final TodoStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TodoStatus.pending => ('Offen', Colors.orange),
      TodoStatus.inProgress => ('In Arbeit', Colors.blue),
      TodoStatus.completed => ('Erledigt', Colors.green),
    };

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withAlpha(38),
      side: BorderSide(color: color.withAlpha(102)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
