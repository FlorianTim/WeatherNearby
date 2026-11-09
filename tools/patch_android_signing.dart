// Injects the key.properties release-signing block into the generated
// android/app/build.gradle.kts. Idempotent — safe to run after every
// bootstrap. Falls back to the debug signing config when key.properties is
// absent, so local `flutter build --release` works without secrets.
//
// Usage (repo root):  dart tools/patch_android_signing.dart
//
// The CI release workflow runs: bootstrap_android.sh -> this tool ->
// writes android/key.properties from secrets -> flutter build.

import 'dart:io';

const gradlePath = 'apps/mobile_app/android/app/build.gradle.kts';

// Imports must stay at the very top; the plugins {} block must not be
// preceded by any other statement — so the loader goes after it.
const imports = '''
import java.io.FileInputStream
import java.util.Properties

''';

const propertiesLoader = '''
// Release signing: values come from android/key.properties (never commit
// it). See docs/operations/android-release-secrets.md.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) load(FileInputStream(keystorePropertiesFile))
}

''';

const signingConfigs = '''
    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

''';

void main() {
  final file = File(gradlePath);
  if (!file.existsSync()) {
    stderr.writeln(
      '$gradlePath not found — run scripts/bootstrap_android.* first.',
    );
    exit(1);
  }

  var content = file.readAsStringSync();
  if (content.contains('keystorePropertiesFile')) {
    stdout.writeln('Signing block already present — nothing to do.');
    return;
  }

  // 1a. Imports at the very top; 1b. properties loader after the plugins
  // block (the plugins {} block must be the first statement).
  final pluginsIndex = content.indexOf('plugins {');
  if (pluginsIndex < 0) {
    stderr.writeln('Unexpected build.gradle.kts layout: no plugins block.');
    exit(1);
  }
  content = imports + content;

  final androidIndex = content.indexOf('android {');
  if (androidIndex < 0) {
    stderr.writeln('Unexpected build.gradle.kts layout: no android block.');
    exit(1);
  }
  content = content.replaceRange(androidIndex, androidIndex, propertiesLoader);

  // 2. signingConfigs before the buildTypes block.
  final buildTypesIndex = content.indexOf('    buildTypes {');
  if (buildTypesIndex < 0) {
    stderr.writeln('Unexpected build.gradle.kts layout: no buildTypes block.');
    exit(1);
  }
  content = content.replaceRange(
    buildTypesIndex,
    buildTypesIndex,
    signingConfigs,
  );

  // 3. Conditional signing config in the release build type.
  const debugSigning = 'signingConfig = signingConfigs.getByName("debug")';
  const conditionalSigning =
      'signingConfig = if (keystorePropertiesFile.exists())\n'
      '                signingConfigs.getByName("release")\n'
      '            else signingConfigs.getByName("debug") '
      '// local --release without secrets';
  if (!content.contains(debugSigning)) {
    stderr.writeln(
      'Unexpected build.gradle.kts layout: no debug signingConfig line.',
    );
    exit(1);
  }
  content = content.replaceFirst(debugSigning, conditionalSigning);

  file.writeAsStringSync(content);
  stdout.writeln('Injected key.properties signing block into $gradlePath.');
}
