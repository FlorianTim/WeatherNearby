// Applies the naming defined in project.env to the repo files that carry it:
//   WORKSPACE_FILE    -> renames the VS Code *.code-workspace file
//   DEVCONTAINER_NAME -> sets "name" in .devcontainer/devcontainer.json
//
// Run during template initialization (after editing project.env):
//   dart tools/apply_project_naming.dart [--dry-run]
//
// Idempotent: running it again is a no-op when everything already matches.

import 'dart:io';

bool dryRun = false;

void main(List<String> args) {
  dryRun = args.contains('--dry-run');

  if (!File('project.env').existsSync()) {
    stderr.writeln('Run this tool from the repository root.');
    exit(1);
  }

  final env = _readEnv('project.env');
  final workspaceFile = env['WORKSPACE_FILE'];
  final devcontainerName = env['DEVCONTAINER_NAME'];

  if (workspaceFile == null || devcontainerName == null) {
    stderr.writeln(
      'project.env must define WORKSPACE_FILE and DEVCONTAINER_NAME.',
    );
    exit(1);
  }

  _renameWorkspace(workspaceFile);
  _renameDevcontainer(devcontainerName);

  stdout.writeln(dryRun ? 'Dry run complete.' : 'Project naming applied.');
}

Map<String, String> _readEnv(String path) {
  final result = <String, String>{};
  for (final line in File(path).readAsLinesSync()) {
    final m = RegExp(r'^\s*([A-Z_]+)\s*=\s*"?([^"#]*)"?\s*$').firstMatch(line);
    if (m != null) result[m.group(1)!] = m.group(2)!.trim();
  }
  return result;
}

void _renameWorkspace(String target) {
  final existing = Directory.current
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.code-workspace'))
      .toList();

  if (existing.isEmpty) {
    stdout.writeln('skip   no *.code-workspace file found');
    return;
  }
  final current = existing.first;
  final currentName = current.uri.pathSegments.last;
  if (currentName == target) {
    stdout.writeln('ok     $currentName already matches WORKSPACE_FILE');
    return;
  }
  stdout.writeln('rename $currentName -> $target');
  if (!dryRun) {
    // Preserve git history: use git mv when available.
    final result = Process.runSync('git', [
      'mv',
      currentName,
      target,
    ], runInShell: true);
    if (result.exitCode != 0) {
      current.renameSync(target);
    }
  }
}

void _renameDevcontainer(String target) {
  const path = '.devcontainer/devcontainer.json';
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('skip   $path (not present)');
    return;
  }
  // devcontainer.json may contain comments (JSONC) — edit as text and only
  // touch the first "name" entry.
  final content = file.readAsStringSync();
  final nameRegex = RegExp(r'"name"\s*:\s*"([^"]*)"');
  final match = nameRegex.firstMatch(content);
  if (match == null) {
    stdout.writeln('skip   $path (no "name" entry)');
    return;
  }
  if (match.group(1) == target) {
    stdout.writeln('ok     devcontainer name already matches');
    return;
  }
  stdout.writeln('edit   $path name: "${match.group(1)}" -> "$target"');
  if (!dryRun) {
    file.writeAsStringSync(
      content.replaceRange(match.start, match.end, '"name": "$target"'),
    );
  }
}
