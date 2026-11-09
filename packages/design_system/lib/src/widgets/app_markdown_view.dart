import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

/// The media type of a Markdown body, per RFC 7763.
const kMarkdownContentType = 'text/markdown; charset=utf-8';

/// Renders a long-form body with the shared LumbreCode defaults.
///
/// **One renderer, one set of defaults, one file to change on a swap.** This
/// is the only place in any app that may import a Markdown package
/// (library-evaluation contract: a UI package with API drift is wrapped
/// behind an adapter, enforced by an encapsulation test).
///
/// ## The body is rendered as it declares itself
///
/// [contentType] is not decoration. A body that arrived from another app
/// carries the content type it was sent with, and the renderer honours it:
///
///  - `text/markdown` (any parameters) — rendered as Markdown.
///  - `text/plain`, or anything else — rendered **literally**. The app never
///    guesses that plain text is Markdown, so `**not bold**` keeps its
///    asterisks.
///
/// Guessing would corrupt a body on the way to the screen and, worse, make a
/// re-export declare something the content is not.
///
/// ## Nothing is fetched
///
/// A body may have arrived in an imported document, so it is untrusted input.
/// No image, favicon, preview or link target is ever resolved automatically.
/// Links are inert unless [onLinkTap] is supplied, and a caller must route
/// that through the scheme-allowlisted launcher seam — never straight to
/// `url_launcher`.
class AppMarkdownView extends StatelessWidget {
  const AppMarkdownView({
    super.key,
    required this.source,
    this.contentType = kMarkdownContentType,
    this.onLinkTap,
    this.selectable = false,
  });

  /// The body, as stored. Never normalized or converted before display.
  final String source;

  /// Media type of [source]. Defaults to Markdown.
  final String contentType;

  /// Called with the link target on an explicit tap.
  ///
  /// **Must** go through the app's allowlisted URL seam. `null` renders links
  /// as text that cannot be tapped, which is the safe default.
  final void Function(Uri uri)? onLinkTap;

  final bool selectable;

  /// Whether [contentType] asks for Markdown rendering.
  ///
  /// Compares the type only, case-insensitively, ignoring parameters such as
  /// `charset` — `text/markdown`, `text/markdown; charset=utf-8` and
  /// `TEXT/MARKDOWN` are the same thing.
  static bool rendersAsMarkdown(String contentType) =>
      contentType.split(';').first.trim().toLowerCase() == 'text/markdown';

  @override
  Widget build(BuildContext context) {
    if (!rendersAsMarkdown(contentType)) {
      // Deliberately literal: this is what the sender declared it to be.
      return selectable ? SelectableText(source) : Text(source);
    }

    return MarkdownBody(
      data: source,
      selectable: selectable,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
      // No imageBuilder is supplied, and no image directory: a remote image
      // in an untrusted document must never be fetched.
      onTapLink: onLinkTap == null
          ? null
          : (text, href, title) {
              if (href == null) return;
              final uri = Uri.tryParse(href);
              // An unparseable href is dropped rather than guessed at.
              if (uri != null) onLinkTap!(uri);
            },
    );
  }
}
