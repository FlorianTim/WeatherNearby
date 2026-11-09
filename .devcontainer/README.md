# Dev Container

This dev container provides a reproducible development environment for Flutter/Dart work.

## What works inside the container

- Flutter & Dart SDK
- `flutter analyze`, `flutter test`
- Dart backend (`services/api`)
- Documentation workflows (Markdown, scripts)
- Git operations

## What requires host-side tooling

- **Android emulator**: Requires Android SDK/emulator on the host or a physical device via USB passthrough.
- **iOS builds**: Require macOS with Xcode (not available in Linux containers).
- **Hot reload on device**: Requires device connectivity from the container.

## Usage

1. Open the repository in VS Code.
2. When prompted, click **Reopen in Container**.
3. Wait for container build and `postCreateCommand` to finish.
4. Use VS Code tasks and launch configurations as normal.
