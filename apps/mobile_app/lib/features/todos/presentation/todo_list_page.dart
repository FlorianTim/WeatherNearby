import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../application/todo_list_notifier.dart';
import 'create_todo_dialog.dart';
import 'widgets/todo_tile.dart';

class TodoListPage extends ConsumerWidget {
  const TodoListPage({
    super.key,
    required this.onOpenSettings,
    required this.onOpenAbout,
  });

  /// Opens the settings hub; the main screen carries it (spec 0005).
  final VoidCallback onOpenSettings;

  /// Opens the about & help page.
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todoListProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aufgaben'),
        actions: [
          IconButton(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsOpen,
          ),
          IconButton(
            onPressed: onOpenAbout,
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.aboutOpen,
          ),
        ],
      ),
      // Unique heroTag: FABs in multiple shell branches otherwise crash
      // with a Hero conflict when a root route is pushed (see AGENTS.md).
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab-todos',
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
      body: todosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorView(
          error: error,
          onRetry: () => ref.invalidate(todoListProvider),
        ),
        data: (todos) => todos.isEmpty
            ? const _EmptyView()
            : ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.md),
                itemCount: todos.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return TodoTile(
                    todo: todo,
                    onToggle: () =>
                        ref.read(todoListProvider.notifier).toggleStatus(todo),
                    onDelete: () =>
                        ref.read(todoListProvider.notifier).deleteTodo(todo.id),
                    onTap: () {},
                  );
                },
              ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateTodoDialog(),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Keine Aufgaben vorhanden', style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Erstelle eine neue Aufgabe mit dem + Button',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.lg),
            Text('Fehler beim Laden', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.toString(),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
            ),
          ],
        ),
      ),
    );
  }
}
