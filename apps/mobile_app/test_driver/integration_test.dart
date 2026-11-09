import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:integration_test/integration_test_driver_extended.dart';

/// Target dimensions per screen profile (must match profiles.json).
const _profileSizes = {
  'tablet': (width: 1024, height: 768),
  'phone-portrait': (width: 390, height: 844),
};

/// Test driver for integration tests with screenshot capture.
///
/// Pass a SCREEN_PROFILE environment variable to select the output
/// subdirectory.  Supported values:
///   tablet           (default) → test_results/screenshots/tablet/
///   phone-portrait             → test_results/screenshots/phone-portrait/
///
/// Screenshots are cropped to the target profile dimensions so the result
/// is independent of the actual browser viewport size.
Future<void> main() {
  // Platform.environment is read at driver runtime, so it correctly picks
  // up the SCREEN_PROFILE env var set in the calling shell / docker command.
  final profile = Platform.environment['SCREEN_PROFILE'] ?? 'tablet';
  final targetSize = _profileSizes[profile];

  return integrationDriver(
    onScreenshot:
        (
          String screenshotName,
          List<int> screenshotBytes, [
          Map<String, Object?>? args,
        ]) async {
          final screenshotDir = Directory('test_results/screenshots/$profile');
          if (!screenshotDir.existsSync()) {
            screenshotDir.createSync(recursive: true);
          }

          // Crop to target profile dimensions when the viewport is larger.
          var finalBytes = screenshotBytes;
          if (targetSize != null) {
            final decoded = img.decodePng(Uint8List.fromList(screenshotBytes));
            if (decoded != null &&
                (decoded.width > targetSize.width ||
                    decoded.height > targetSize.height)) {
              final cropped = img.copyCrop(
                decoded,
                x: 0,
                y: 0,
                width: targetSize.width.clamp(0, decoded.width),
                height: targetSize.height.clamp(0, decoded.height),
              );
              finalBytes = img.encodePng(cropped);
            }
          }

          final file = File('${screenshotDir.path}/$screenshotName.png');
          await file.writeAsBytes(finalBytes);

          // Save metadata sidecar so PDF generation can include descriptions.
          // Keys recognised: description (String), useCase (String, optional).
          if (args != null && args.isNotEmpty) {
            final metaFile = File('${screenshotDir.path}/$screenshotName.json');
            await metaFile.writeAsString(jsonEncode(args));
          }

          print('Screenshot saved: ${file.path}'); // ignore: avoid_print
          return true;
        },
  );
}
