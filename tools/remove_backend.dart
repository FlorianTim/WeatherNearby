// Removes every backend component from the template in one operation.
//
// Run from the repo root (wrappers: scripts/remove_backend.sh|ps1):
//   dart tools/remove_backend.dart [--dry-run]
//
// What it does:
//   1. Deletes backend/ (Node) and services/api/ (Dart/Shelf)
//   2. Deletes the backend CI workflows (ci-backend.yml, ci-backend-node.yml)
//   3. Deletes docker/compose.api.yml and the include block in docker-compose.yml
//   4. Removes services/api from the root pubspec.yaml workspace list
//   5. Removes the "Dart: api" launch config and "API: *" tasks from the
//      VS Code workspace file (name from project.env WORKSPACE_FILE)
//   6. Removes the services/api pub get from .devcontainer/devcontainer.json
//   7. Removes backend tasks from .codex/config.toml
//
// With --with-packages it additionally removes the packages that only exist
// to serve a backend: packages/api_client (HTTP scaffold) and
// packages/shared_models (DTOs shared with services/api).
//
// packages/feature_flags is deliberately NOT in that list: paid-feature gates
// and entitlements are a store concern, not a backend one, and a backend-less
// app needs them just as much. It stays.
//
// Prose docs (README.md, .github/copilot-instructions.md, arc42) keep their
// backend mentions; the tool prints a reminder to clean them up.

import 'dart:convert';
import 'dart:io';

bool dryRun = false;

void main(List<String> args) {
  dryRun = args.contains('--dry-run');

  if (!File('project.env').existsSync() || !File('pubspec.yaml').existsSync()) {
    stderr.writeln('Run this tool from the repository root.');
    exit(1);
  }

  deleteDir('backend');
  deleteDir('services/api');
  pruneEmptyDir('services');
  deleteFile('.github/workflows/ci-backend.yml');
  deleteFile('.github/workflows/ci-backend-node.yml');
  deleteFile('docker/compose.api.yml');

  removeLines(
    'docker-compose.yml',
    (line) =>
        line.contains('docker/compose.api.yml') ||
        line.trim() == 'include:' ||
        line.contains('# All backend API services live in one included file') ||
        line.contains('# backend is a single operation') ||
        line.contains(
          '# Backend (services defined in docker/compose.api.yml):',
        ) ||
        line.contains('#   docker compose up api-server') ||
        line.contains('#   docker compose run --rm api-analyze') ||
        line.contains('#   docker compose run --rm api-test') ||
        line.contains('# Backend API services: see docker/compose.api.yml'),
  );

  removeLines('pubspec.yaml', (line) => line.trim() == '- services/api');

  if (args.contains('--with-packages')) {
    deleteDir('packages/api_client');
    deleteDir('packages/shared_models');
    removeLines(
      'pubspec.yaml',
      (line) =>
          line.trim() == '- packages/api_client' ||
          line.trim() == '- packages/shared_models',
    );
  }

  cleanWorkspaceFile();
  cleanDevcontainer();

  removeLines(
    '.codex/config.toml',
    (line) =>
        line.startsWith('backend =') ||
        line.startsWith('backend_node =') ||
        (line.startsWith('format =') && line.contains('services/api')),
  );

  stdout.writeln('');
  stdout.writeln(
    dryRun ? 'Dry run complete — nothing was changed.' : 'Backend removed.',
  );
  stdout.writeln('Manual follow-ups (prose only):');
  stdout.writeln('  - README.md: drop backend sections/rows');
  stdout.writeln('  - .github/copilot-instructions.md: drop backend guidance');
  stdout.writeln('  - docs/architecture/: drop backend building blocks');
  stdout.writeln('  - run: melos bootstrap (workspace changed)');
}

void deleteDir(String path) {
  final dir = Directory(path);
  if (!dir.existsSync()) {
    stdout.writeln('skip   $path/ (not present)');
    return;
  }
  stdout.writeln('delete $path/');
  if (!dryRun) dir.deleteSync(recursive: true);
}

void pruneEmptyDir(String path) {
  final dir = Directory(path);
  if (dir.existsSync() && dir.listSync().isEmpty) {
    stdout.writeln('delete $path/ (empty)');
    if (!dryRun) dir.deleteSync();
  }
}

void deleteFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('skip   $path (not present)');
    return;
  }
  stdout.writeln('delete $path');
  if (!dryRun) file.deleteSync();
}

void removeLines(String path, bool Function(String line) match) {
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('skip   $path (not present)');
    return;
  }
  final lines = file.readAsLinesSync();
  final kept = lines.where((l) => !match(l)).toList();
  if (kept.length == lines.length) {
    stdout.writeln('ok     $path (no backend lines)');
    return;
  }
  stdout.writeln('edit   $path (-${lines.length - kept.length} lines)');
  if (!dryRun) file.writeAsStringSync('${kept.join('\n')}\n');
}

String workspaceFileName() {
  final env = File('project.env').readAsLinesSync();
  for (final line in env) {
    final m = RegExp(r'^\s*WORKSPACE_FILE\s*=\s*"?([^"#]+)"?').firstMatch(line);
    if (m != null) return m.group(1)!.trim();
  }
  return 'flutter_app_template.code-workspace';
}

void cleanWorkspaceFile() {
  final path = workspaceFileName();
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('skip   $path (not present)');
    return;
  }
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

  final launch = json['launch'] as Map<String, dynamic>?;
  final configs = (launch?['configurations'] as List?) ?? [];
  configs.removeWhere(
    (c) =>
        c is Map &&
        (c['program']?.toString().contains('services/api') ?? false),
  );

  final tasks = (json['tasks'] as Map<String, dynamic>?)?['tasks'] as List?;
  tasks?.removeWhere(
    (t) =>
        t is Map &&
        ((t['label']?.toString().startsWith('API:') ?? false) ||
            (t['options']?['cwd']?.toString().contains('services/api') ??
                false)),
  );

  stdout.writeln('edit   $path (launch configs + tasks)');
  if (!dryRun) {
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
  }
}

void cleanDevcontainer() {
  const path = '.devcontainer/devcontainer.json';
  final file = File(path);
  if (!file.existsSync()) {
    stdout.writeln('skip   $path (not present)');
    return;
  }
  // devcontainer.json may contain comments (JSONC) — edit as text.
  var content = file.readAsStringSync();
  final updated = content.replaceAll(
    ' && cd ../../services/api && dart pub get',
    '',
  );
  if (updated == content) {
    stdout.writeln('ok     $path (no backend command)');
    return;
  }
  stdout.writeln('edit   $path (postCreateCommand)');
  if (!dryRun) file.writeAsStringSync(updated);
}
