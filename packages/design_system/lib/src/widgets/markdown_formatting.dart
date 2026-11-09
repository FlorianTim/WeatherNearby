import 'package:flutter/services.dart' show TextEditingValue, TextSelection;

/// The Markdown edits the shared toolbar performs, as **pure functions**.
///
/// They are separated from the widget on purpose: every interesting case —
/// wrapping a selection, toggling a marker off, placing the cursor between a
/// freshly inserted pair — is a string problem, and a string problem is
/// cheaper to test than a pumped widget. The editor widget stays a thin shell
/// over these.
abstract final class MarkdownFormatting {
  /// Wraps the selection in [marker], or inserts an empty pair at the cursor.
  ///
  /// With a selection, the selection is preserved so a second call toggles it
  /// back off. Without one, the cursor lands **between** the markers, so the
  /// next keystroke is already inside the emphasis.
  static TextEditingValue toggleWrap(TextEditingValue value, String marker) {
    final selection = value.selection;
    if (!selection.isValid) return value;

    final text = value.text;
    final start = selection.start;
    final end = selection.end;
    final selected = text.substring(start, end);

    // Already wrapped, inside the selection: unwrap.
    if (selected.length >= marker.length * 2 &&
        selected.startsWith(marker) &&
        selected.endsWith(marker)) {
      final inner = selected.substring(
        marker.length,
        selected.length - marker.length,
      );
      return TextEditingValue(
        text: text.replaceRange(start, end, inner),
        selection: TextSelection(
          baseOffset: start,
          extentOffset: start + inner.length,
        ),
      );
    }

    // Already wrapped, just outside the selection: unwrap there instead.
    final hasOuter =
        start >= marker.length &&
        end + marker.length <= text.length &&
        text.substring(start - marker.length, start) == marker &&
        text.substring(end, end + marker.length) == marker;
    if (hasOuter) {
      final without = text
          .replaceRange(end, end + marker.length, '')
          .replaceRange(start - marker.length, start, '');
      return TextEditingValue(
        text: without,
        selection: TextSelection(
          baseOffset: start - marker.length,
          extentOffset: end - marker.length,
        ),
      );
    }

    final wrapped = '$marker$selected$marker';
    return TextEditingValue(
      text: text.replaceRange(start, end, wrapped),
      selection: selection.isCollapsed
          // Cursor between the markers.
          ? TextSelection.collapsed(offset: start + marker.length)
          // Keep the selection, now shifted past the opening marker.
          : TextSelection(
              baseOffset: start + marker.length,
              extentOffset: end + marker.length,
            ),
    );
  }

  /// Toggles a line prefix such as `# ` or `- ` on the current line.
  ///
  /// Applied to every line the selection touches, so selecting three lines
  /// and pressing "list" produces a three-item list. If **all** touched lines
  /// already carry the prefix, it is removed instead.
  static TextEditingValue toggleLinePrefix(
    TextEditingValue value,
    String prefix,
  ) {
    final selection = value.selection;
    if (!selection.isValid) return value;

    final text = value.text;
    final lineStart = _lineStartAt(text, selection.start);
    final lineEnd = _lineEndAt(text, selection.end);
    final block = text.substring(lineStart, lineEnd);
    final lines = block.split('\n');

    final allPrefixed = lines.every((line) => line.startsWith(prefix));
    final updated = lines
        .map(
          (line) =>
              allPrefixed ? line.substring(prefix.length) : '$prefix$line',
        )
        .join('\n');

    final delta = updated.length - block.length;
    return TextEditingValue(
      text: text.replaceRange(lineStart, lineEnd, updated),
      selection: TextSelection.collapsed(
        offset: (selection.end + delta).clamp(0, text.length + delta),
      ),
    );
  }

  /// Strips Markdown markers from every line the selection touches.
  ///
  /// Handles the markers this toolbar can produce: heading hashes, bullet
  /// prefixes, bold, italic and strikethrough.
  static TextEditingValue clearLineFormatting(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid) return value;

    final text = value.text;
    final lineStart = _lineStartAt(text, selection.start);
    final lineEnd = _lineEndAt(text, selection.end);
    final block = text.substring(lineStart, lineEnd);

    final cleaned = block
        .split('\n')
        .map((line) => stripInline(line.replaceFirst(_linePrefix, '')))
        .join('\n');

    final delta = cleaned.length - block.length;
    return TextEditingValue(
      text: text.replaceRange(lineStart, lineEnd, cleaned),
      selection: TextSelection.collapsed(
        offset: (selection.end + delta).clamp(0, text.length + delta),
      ),
    );
  }

  /// Markdown source as readable plain text, with the markers removed.
  ///
  /// Used by copy and share, so pasted text carries no `**`, `#` or `~~`.
  ///
  /// This is **not** a Markdown-to-HTML conversion and not a renderer. It is
  /// deliberately the small inverse of what this toolbar can insert: anything
  /// else in the body is left exactly as the user wrote it.
  static String toPlainText(String source) {
    return source
        .split('\n')
        .map((line) => stripInline(line.replaceFirst(_linePrefix, '')))
        .join('\n');
  }

  /// Removes bold, italic and strikethrough markers from a single line.
  static String stripInline(String line) {
    var result = line;
    // Longest first: `**` must go before `*`, or `**x**` leaves stray stars.
    for (final marker in const ['~~', '**', '*']) {
      result = result.replaceAll(marker, '');
    }
    return result;
  }

  /// Heading hashes or a bullet at the start of a line.
  static final RegExp _linePrefix = RegExp(r'^(?:#{1,6}\s+|[-*+]\s+)');

  static int _lineStartAt(String text, int offset) {
    final index = text.lastIndexOf('\n', offset > 0 ? offset - 1 : 0);
    return index == -1 ? 0 : index + 1;
  }

  static int _lineEndAt(String text, int offset) {
    final index = text.indexOf('\n', offset);
    return index == -1 ? text.length : index;
  }
}
