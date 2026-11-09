import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-function tests for the toolbar's edits.
///
/// These are the cases that matter and they are all string problems, so none
/// of them needs a pumped widget. The editor widget test covers wiring only.
TextEditingValue at(String text, int offset) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: offset),
);

TextEditingValue selecting(String text, int start, int end) => TextEditingValue(
  text: text,
  selection: TextSelection(baseOffset: start, extentOffset: end),
);

void main() {
  group('toggleWrap — with a selection', () {
    test('wraps the selection and keeps it selected', () {
      final result = MarkdownFormatting.toggleWrap(
        selecting('Milch kaufen', 0, 5),
        '**',
      );

      expect(result.text, '**Milch** kaufen');
      expect(result.selection.start, 2);
      expect(result.selection.end, 7);
      expect(
        result.text.substring(result.selection.start, result.selection.end),
        'Milch',
        reason: 'a second press must be able to toggle it back off',
      );
    });

    test('unwraps when the markers are inside the selection', () {
      final result = MarkdownFormatting.toggleWrap(
        selecting('**Milch** kaufen', 0, 9),
        '**',
      );

      expect(result.text, 'Milch kaufen');
      expect(result.selection.start, 0);
      expect(result.selection.end, 5);
    });

    test('unwraps when the markers sit just outside the selection', () {
      // This is what happens after wrapping once: the selection covers the
      // word, not the markers. Pressing bold again must undo it.
      final result = MarkdownFormatting.toggleWrap(
        selecting('**Milch** kaufen', 2, 7),
        '**',
      );

      expect(result.text, 'Milch kaufen');
      expect(result.selection.start, 0);
      expect(result.selection.end, 5);
    });

    test('handles each marker the toolbar offers', () {
      expect(
        MarkdownFormatting.toggleWrap(selecting('abc', 0, 3), '*').text,
        '*abc*',
      );
      expect(
        MarkdownFormatting.toggleWrap(selecting('abc', 0, 3), '~~').text,
        '~~abc~~',
      );
    });
  });

  group('toggleWrap — without a selection', () {
    test('inserts an empty pair and puts the cursor inside', () {
      final result = MarkdownFormatting.toggleWrap(at('Milch ', 6), '**');

      expect(result.text, 'Milch ****');
      expect(result.selection.isCollapsed, isTrue);
      expect(
        result.selection.baseOffset,
        8,
        reason: 'the next keystroke should land between the markers',
      );
    });
  });

  group('toggleLinePrefix', () {
    test('adds a heading marker to the current line', () {
      final result = MarkdownFormatting.toggleLinePrefix(
        at('Einkauf', 3),
        '# ',
      );
      expect(result.text, '# Einkauf');
    });

    test('removes it again on a second press', () {
      final result = MarkdownFormatting.toggleLinePrefix(
        at('# Einkauf', 4),
        '# ',
      );
      expect(result.text, 'Einkauf');
    });

    test('applies to every line the selection touches', () {
      final result = MarkdownFormatting.toggleLinePrefix(
        selecting('Milch\nEier\nMehl', 0, 15),
        '- ',
      );
      expect(result.text, '- Milch\n- Eier\n- Mehl');
    });

    test('removes only when every touched line already has it', () {
      final result = MarkdownFormatting.toggleLinePrefix(
        selecting('- Milch\nEier', 0, 12),
        '- ',
      );
      expect(
        result.text,
        '- - Milch\n- Eier',
        reason: 'a mixed block is normalized to prefixed, not stripped',
      );
    });

    test('leaves other lines alone', () {
      final result = MarkdownFormatting.toggleLinePrefix(
        at('Milch\nEier', 7),
        '- ',
      );
      expect(result.text, 'Milch\n- Eier');
    });
  });

  group('clearLineFormatting', () {
    test('strips a heading marker', () {
      expect(
        MarkdownFormatting.clearLineFormatting(at('## Einkauf', 5)).text,
        'Einkauf',
      );
    });

    test('strips a bullet prefix', () {
      expect(
        MarkdownFormatting.clearLineFormatting(at('- Milch', 4)).text,
        'Milch',
      );
    });

    test('strips inline emphasis', () {
      expect(
        MarkdownFormatting.clearLineFormatting(
          at('**Milch** und *Eier* und ~~Mehl~~', 3),
        ).text,
        'Milch und Eier und Mehl',
      );
    });

    test('strips prefix and inline markers together', () {
      expect(
        MarkdownFormatting.clearLineFormatting(at('# **Einkauf**', 5)).text,
        'Einkauf',
      );
    });
  });

  group('toPlainText — what copy and share hand over', () {
    test('removes every marker this toolbar can insert', () {
      const source =
          '# Einkauf\n\n'
          'Bitte **dunkle Schokolade** und *Sahne*.\n\n'
          '~~Kein Zucker~~\n\n'
          '- 12 Kerzen\n'
          '- Streichhölzer';

      const expected =
          'Einkauf\n\n'
          'Bitte dunkle Schokolade und Sahne.\n\n'
          'Kein Zucker\n\n'
          '12 Kerzen\n'
          'Streichhölzer';

      expect(MarkdownFormatting.toPlainText(source), expected);
    });

    test('leaves text without markers untouched', () {
      const source = 'Milch kaufen\nEier kaufen';
      expect(MarkdownFormatting.toPlainText(source), source);
    });

    test('handles an empty body', () {
      expect(MarkdownFormatting.toPlainText(''), '');
    });
  });

  group('stripInline', () {
    test('removes the longest marker first', () {
      // Naively removing `*` before `**` leaves stray stars behind.
      expect(MarkdownFormatting.stripInline('**bold**'), 'bold');
      expect(MarkdownFormatting.stripInline('~~gone~~'), 'gone');
      expect(MarkdownFormatting.stripInline('*it*'), 'it');
      expect(MarkdownFormatting.stripInline('***both***'), 'both');
    });
  });
}
