import 'package:app_core/app_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/core/errors/feedback_mail.dart';
import 'package:mobile_app/core/errors/last_error_buffer.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  group('LastErrorBuffer', () {
    test('keeps only the newest `capacity` entries, newest first', () {
      final buffer = LastErrorBuffer(capacity: 2);
      buffer.add(AppError(error: 'one', source: 'zone'));
      buffer.add(AppError(error: 'two', source: 'zone'));
      buffer.add(AppError(error: 'three', source: 'flutter'));

      expect(buffer.entries.map((e) => e.error), ['three', 'two']);
      expect(buffer.last?.error, 'three');
    });
  });

  group('FeedbackMailBuilder', () {
    const builder = FeedbackMailBuilder(
      links: AppLinks(slug: 'my-app'),
      maxStackLines: 3,
    );

    test('builds a mailto uri with metadata block', () {
      final uri = builder.build(
        mailbox: SupportMailbox.bugs,
        subject: 'Bug report',
        packageInfo: PackageInfo(
          appName: 'MyApp',
          packageName: 'de.lumbre.code.myapp',
          version: '1.2.3',
          buildNumber: '42',
        ),
      );

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'bugs@lumbrecode.de');
      final query = Uri.decodeComponent(uri.query);
      expect(query, contains('subject=[app:my-app] Bug report'));
      expect(query, contains('MyApp 1.2.3+42'));
      expect(query, contains('de.lumbre.code.myapp'));
      expect(query, contains('What happened?'));
    });

    test('truncates long stack traces', () {
      final stack = StackTrace.fromString(
        List.generate(10, (i) => '#$i frame$i').join('\n'),
      );
      final uri = builder.build(
        mailbox: SupportMailbox.bugs,
        subject: 's',
        lastError: AppError(
          error: StateError('boom'),
          stackTrace: stack,
          source: 'zone',
        ),
      );

      final body = Uri.decodeComponent(uri.query);
      expect(body, contains('Bad state: boom'));
      expect(body, contains('#2 frame2'));
      expect(body, isNot(contains('#3 frame3')));
      expect(body, contains('(7 more frames)'));
    });
  });
}
