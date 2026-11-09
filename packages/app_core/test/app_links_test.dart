import 'package:app_core/app_core.dart';
import 'package:test/test.dart';

void main() {
  const links = AppLinks(slug: 'was-there-something');

  group('AppLinks web pages', () {
    test('website is the app landing page with a trailing slash', () {
      expect(
        links.website.toString(),
        'https://lumbrecode.de/apps/was-there-something/',
      );
    });

    test('every page URL follows <base>/<slug>/<page>/', () {
      expect(links.all, {
        'website': Uri.parse('https://lumbrecode.de/apps/was-there-something/'),
        'support': Uri.parse(
          'https://lumbrecode.de/apps/was-there-something/support/',
        ),
        'faq': Uri.parse('https://lumbrecode.de/apps/was-there-something/faq/'),
        'privacy': Uri.parse(
          'https://lumbrecode.de/apps/was-there-something/privacy/',
        ),
        'data-deletion': Uri.parse(
          'https://lumbrecode.de/apps/was-there-something/data-deletion/',
        ),
        'changelog': Uri.parse(
          'https://lumbrecode.de/apps/was-there-something/changelog/',
        ),
        'licenses': Uri.parse(
          'https://lumbrecode.de/apps/was-there-something/licenses/',
        ),
      });
    });

    test('all links are https', () {
      for (final uri in links.all.values) {
        expect(uri.scheme, 'https', reason: '$uri must be https');
      }
    });

    test('a different slug changes every link', () {
      const other = AppLinks(slug: 'todo-app');
      expect(
        other.privacyPolicy.toString(),
        'https://lumbrecode.de/apps/todo-app/privacy/',
      );
    });
  });

  group('AppLinks mail', () {
    test('subject carries the app tag so mail can be sorted per app', () {
      expect(
        links.mailSubject('Bug report'),
        '[app:was-there-something] Bug report',
      );
    });

    test('mailto targets the mailbox address', () {
      final uri = links.mailto(SupportMailbox.bugs, subject: 'Bug report');

      expect(uri.scheme, 'mailto');
      expect(uri.path, 'bugs@lumbrecode.de');
    });

    test('subject and body are percent-encoded, spaces are not "+"', () {
      final uri = links.mailto(
        SupportMailbox.support,
        subject: 'Need help',
        body: 'line one\nline two',
      );

      expect(
        uri.query,
        contains('subject=%5Bapp%3Awas-there-something%5D%20Need%20help'),
      );
      expect(uri.query, contains('body=line%20one%0Aline%20two'));
      expect(uri.query, isNot(contains('+')));
    });

    test('body is omitted when not given', () {
      final uri = links.mailto(SupportMailbox.feedback, subject: 'Idea');

      expect(uri.query, isNot(contains('body=')));
    });

    test('every mailbox is a lumbrecode.de address', () {
      for (final mailbox in SupportMailbox.values) {
        expect(mailbox.address, endsWith('@lumbrecode.de'));
      }
    });
  });

  test('value equality is based on the slug', () {
    expect(const AppLinks(slug: 'todo-app'), const AppLinks(slug: 'todo-app'));
    expect(
      const AppLinks(slug: 'todo-app'),
      isNot(const AppLinks(slug: 'other-app')),
    );
  });
}
