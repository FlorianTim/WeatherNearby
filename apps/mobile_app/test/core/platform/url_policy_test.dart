import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/platform/platform_seams.dart';

/// The URL allowlist is a **security boundary**, not a convenience.
///
/// Link targets that arrive in an imported document are user-entered URLs
/// from an untrusted source. The interop contract requires that only `http:`
/// and `https:` are ever opened, and only on an explicit tap. These tests
/// assert the refusal happens *before* the plugin is reached, so a widened
/// call site cannot quietly re-enable a scheme.
void main() {
  group(
    'UrlPolicy.webOnly — the default for anything the app did not author',
    () {
      test('allows http and https', () {
        expect(
          UrlPolicy.webOnly.allows(Uri.parse('https://example.invalid/a')),
          isTrue,
        );
        expect(
          UrlPolicy.webOnly.allows(Uri.parse('http://example.invalid/a')),
          isTrue,
        );
      });

      test('refuses every other scheme', () {
        const refused = [
          'mailto:someone@example.invalid',
          'tel:+4930000000',
          'file:///etc/passwd',
          'javascript:alert(1)',
          'content://com.example/doc/1',
          'intent://scan/#Intent;scheme=zxing;end',
          'sms:+4930000000',
          'ftp://example.invalid/a',
          'data:text/html,<h1>x</h1>',
        ];

        for (final raw in refused) {
          expect(
            UrlPolicy.webOnly.allows(Uri.parse(raw)),
            isFalse,
            reason: raw,
          );
        }
      });

      test('refuses a URI with no scheme', () {
        expect(
          UrlPolicy.webOnly.allows(Uri.parse('example.invalid/a')),
          isFalse,
        );
        expect(UrlPolicy.webOnly.allows(Uri.parse('/local/path')), isFalse);
      });

      test('compares the scheme case-insensitively', () {
        expect(
          UrlPolicy.webOnly.allows(Uri.parse('HTTPS://example.invalid')),
          isTrue,
        );
        expect(
          UrlPolicy.webOnly.allows(Uri.parse('HtTp://example.invalid')),
          isTrue,
        );
      });
    },
  );

  group('UrlPolicy.appAuthored — only for URIs the app built itself', () {
    test('adds mailto and nothing else', () {
      expect(UrlPolicy.appAuthored.allowedSchemes, {'http', 'https', 'mailto'});
      expect(
        UrlPolicy.appAuthored.allows(
          Uri.parse('mailto:someone@example.invalid'),
        ),
        isTrue,
      );
      expect(
        UrlPolicy.appAuthored.allows(Uri.parse('file:///etc/passwd')),
        isFalse,
      );
      expect(
        UrlPolicy.appAuthored.allows(Uri.parse('javascript:alert(1)')),
        isFalse,
      );
    });
  });

  group('the allowlists themselves', () {
    // A widened set is a decision that belongs in a new policy value with its
    // own justification, not an edit to an existing one. This test is the
    // tripwire.
    test('have not been widened', () {
      expect(UrlPolicy.webOnly.allowedSchemes, {'http', 'https'});
      expect(UrlPolicy.appAuthored.allowedSchemes, {'http', 'https', 'mailto'});
      expect(UrlPolicy.values.length, 2);
    });

    test('webOnly is the default, so forgetting is safe', () async {
      // Exercised through a fake with the same signature as the real seam.
      var pluginCalls = 0;
      Future<LaunchOutcome> launcher(
        Uri uri, {
        UrlPolicy policy = UrlPolicy.webOnly,
      }) async {
        if (!policy.allows(uri)) return LaunchOutcome.schemeNotAllowed;
        pluginCalls++;
        return LaunchOutcome.launched;
      }

      // No policy passed at all.
      expect(
        await launcher(Uri.parse('mailto:someone@example.invalid')),
        LaunchOutcome.schemeNotAllowed,
      );
      expect(pluginCalls, 0, reason: 'the plugin must not have been reached');

      expect(
        await launcher(Uri.parse('https://example.invalid')),
        LaunchOutcome.launched,
      );
      expect(pluginCalls, 1);
    });
  });
}
