import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/platform/platform_seams.dart';

void main() {
  test(
    'plugin seams are overridable with fakes (no platform channel)',
    () async {
      String? shared;
      SharePayload? sharedDocument;
      Uri? launched;
      String? copied;

      final container = ProviderContainer(
        overrides: [
          shareTextProvider.overrideWithValue((text) async => shared = text),
          shareDocumentProvider.overrideWithValue(
            (payload) async => sharedDocument = payload,
          ),
          urlLauncherProvider.overrideWithValue((
            uri, {
            UrlPolicy policy = UrlPolicy.webOnly,
          }) async {
            launched = uri;
            return LaunchOutcome.launched;
          }),
          copyToClipboardProvider.overrideWithValue(
            (text) async => copied = text,
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(shareTextProvider)('hello');
      await container.read(shareDocumentProvider)(
        const SharePayload(
          fileName: 'list.jscalendar.json',
          mediaType: 'application/jscalendar+json;type=group',
          bytesUtf8: '{"@type":"Group"}',
        ),
      );
      await container.read(urlLauncherProvider)(
        Uri.parse('https://example.org'),
      );
      await container.read(copyToClipboardProvider)('copy me');

      expect(shared, 'hello');
      expect(sharedDocument?.fileName, 'list.jscalendar.json');
      expect(
        sharedDocument?.mediaType,
        'application/jscalendar+json;type=group',
      );
      expect(launched, Uri.parse('https://example.org'));
      expect(copied, 'copy me');
    },
  );

  test('the real launcher refuses a disallowed scheme without calling the '
      'plugin', () async {
    // The REAL provider body runs here, not a fake. That is the whole point:
    // a refused scheme never reaches url_launcher, so no platform channel is
    // touched and these assertions pass without a plugin binding at all.
    //
    // The absence of a binding is therefore the assertion. If someone moves
    // the scheme check to after the plugin call, this test fails with
    // "Binding has not yet been initialized" rather than passing quietly.
    //
    // For the same reason there is no positive case here — an allowed scheme
    // *does* reach the platform. That `appAuthored` permits mailto is
    // asserted at the policy level in url_policy_test.dart.
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final launch = container.read(urlLauncherProvider);

    expect(
      await launch(Uri.parse('file:///etc/passwd')),
      LaunchOutcome.schemeNotAllowed,
    );
    expect(
      await launch(Uri.parse('javascript:alert(1)')),
      LaunchOutcome.schemeNotAllowed,
    );
    expect(
      await launch(Uri.parse('content://com.example/doc/1')),
      LaunchOutcome.schemeNotAllowed,
    );
    expect(
      await launch(Uri.parse('mailto:someone@example.invalid')),
      LaunchOutcome.schemeNotAllowed,
      reason: 'mailto needs UrlPolicy.appAuthored, which is opt-in',
    );
  });
}
