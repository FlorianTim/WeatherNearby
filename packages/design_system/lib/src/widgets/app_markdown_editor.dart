import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'markdown_formatting.dart';

/// Localized labels for [AppMarkdownEditor].
///
/// Strings arrive from the caller because `design_system` must not depend on
/// any one app's `AppLocalizations` — the moment it does, it stops being
/// reusable by the next app, which is the whole reason the package exists.
/// Every field is also the control's semantic label, so none may be empty.
class AppMarkdownEditorLabels {
  const AppMarkdownEditorLabels({
    required this.heading,
    required this.bold,
    required this.italic,
    required this.strikethrough,
    required this.bulletList,
    required this.clearFormatting,
    required this.undo,
    required this.redo,
    required this.reset,
    required this.save,
    required this.copy,
    required this.share,
    required this.close,
    required this.tooLong,
  });

  final String heading;
  final String bold;
  final String italic;
  final String strikethrough;
  final String bulletList;
  final String clearFormatting;
  final String undo;
  final String redo;
  final String reset;
  final String save;
  final String copy;
  final String share;
  final String close;

  /// Shown when the body exceeds `maxLength`. Never truncate silently.
  final String tooLong;
}

/// The shared Markdown editor: formatting toolbar above, actions below.
///
/// **One editor in every LumbreCode app.** A second one means two places
/// where "how does bold work here" is answered, and they drift.
///
/// Reference behaviour: WasThereSomething spec 0025 (MDE-001..010).
///
/// Deliberately built on a plain [TextField] and a [TextEditingController] —
/// no editor package. The interesting part is string manipulation, and it
/// lives in [MarkdownFormatting] as pure functions so it can be tested
/// without pumping a widget.
///
/// Undo history is per editor session and in memory. Nothing is persisted.
class AppMarkdownEditor extends StatefulWidget {
  const AppMarkdownEditor({
    super.key,
    required this.initialText,
    required this.labels,
    this.onChanged,
    this.onSave,
    this.onCopy,
    this.onShare,
    this.onClose,
    this.maxLength,
    this.minLines = 6,
    this.historyLimit = 100,
  });

  final String initialText;
  final AppMarkdownEditorLabels labels;

  final ValueChanged<String>? onChanged;

  /// `null` hides the button. Each of these is optional on purpose: the same
  /// editor serves a saved note and a throwaway draft.
  final Future<void> Function(String text)? onSave;

  /// Receives **plain text**, with the Markdown markers stripped.
  final Future<void> Function(String plainText)? onCopy;

  /// Receives **plain text**, with the Markdown markers stripped.
  final Future<void> Function(String plainText)? onShare;

  final VoidCallback? onClose;

  /// Enforced by refusing the change with a message — never by truncating.
  final int? maxLength;

  final int minLines;

  /// Bounds the in-memory undo stack so a long session cannot grow forever.
  final int historyLimit;

  @override
  State<AppMarkdownEditor> createState() => _AppMarkdownEditorState();
}

class _AppMarkdownEditorState extends State<AppMarkdownEditor> {
  late final TextEditingController _controller;
  final List<TextEditingValue> _undoStack = [];
  final List<TextEditingValue> _redoStack = [];

  /// Set while the code (not the user) writes to the controller, so the
  /// listener does not record a history entry for our own edit.
  bool _applyingProgrammatically = false;

  bool _tooLong = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText)
      ..addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_applyingProgrammatically) return;
    widget.onChanged?.call(_controller.text);
    _refreshTooLong();
  }

  void _refreshTooLong() {
    final max = widget.maxLength;
    final tooLong = max != null && _controller.text.length > max;
    if (tooLong != _tooLong) setState(() => _tooLong = tooLong);
  }

  /// The controller's value, guaranteed to carry a usable selection.
  ///
  /// A controller that has never been focused reports an **invalid**
  /// selection (offset −1). The formatting functions correctly refuse to
  /// guess where to act, so without this a toolbar press before the first tap
  /// into the field would silently do nothing — which reads as a broken
  /// button. Treat that case as "cursor at the end", which is where a user
  /// who has not clicked anywhere would expect to be typing.
  TextEditingValue get _valueWithSelection {
    final value = _controller.value;
    if (value.selection.isValid) return value;
    return value.copyWith(
      selection: TextSelection.collapsed(offset: value.text.length),
    );
  }

  /// Applies [transform] to the current value, recording undo history.
  void _apply(TextEditingValue Function(TextEditingValue) transform) {
    final current = _valueWithSelection;
    _pushHistory(current);
    _redoStack.clear();
    _setValue(transform(current));
  }

  void _pushHistory(TextEditingValue value) {
    _undoStack.add(value);
    if (_undoStack.length > widget.historyLimit) _undoStack.removeAt(0);
  }

  void _setValue(TextEditingValue value) {
    _applyingProgrammatically = true;
    _controller.value = value;
    _applyingProgrammatically = false;
    widget.onChanged?.call(_controller.text);
    _refreshTooLong();
    setState(() {});
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_controller.value);
    _setValue(_undoStack.removeLast());
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    _pushHistory(_controller.value);
    _setValue(_redoStack.removeLast());
  }

  void _reset() {
    if (_controller.text == widget.initialText) return;
    _pushHistory(_controller.value);
    _redoStack.clear();
    _setValue(
      TextEditingValue(
        text: widget.initialText,
        selection: TextSelection.collapsed(offset: widget.initialText.length),
      ),
    );
  }

  bool get _canReset => _controller.text != widget.initialText;

  String get _plainText => MarkdownFormatting.toPlainText(_controller.text);

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Toolbar. Wraps rather than shrinking its targets, so every button
        // keeps its 48 dp at large text scales.
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            _ToolbarButton(
              icon: Icons.title,
              label: labels.heading,
              onPressed: () =>
                  _apply((v) => MarkdownFormatting.toggleLinePrefix(v, '# ')),
            ),
            _ToolbarButton(
              icon: Icons.format_bold,
              label: labels.bold,
              onPressed: () =>
                  _apply((v) => MarkdownFormatting.toggleWrap(v, '**')),
            ),
            _ToolbarButton(
              icon: Icons.format_italic,
              label: labels.italic,
              onPressed: () =>
                  _apply((v) => MarkdownFormatting.toggleWrap(v, '*')),
            ),
            _ToolbarButton(
              icon: Icons.format_strikethrough,
              label: labels.strikethrough,
              onPressed: () =>
                  _apply((v) => MarkdownFormatting.toggleWrap(v, '~~')),
            ),
            _ToolbarButton(
              icon: Icons.format_list_bulleted,
              label: labels.bulletList,
              onPressed: () =>
                  _apply((v) => MarkdownFormatting.toggleLinePrefix(v, '- ')),
            ),
            _ToolbarButton(
              icon: Icons.format_clear,
              label: labels.clearFormatting,
              onPressed: () => _apply(MarkdownFormatting.clearLineFormatting),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _controller,
          minLines: widget.minLines,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            // The cap is reported, never enforced by truncation: silently
            // dropping the end of somebody's note is worse than refusing it.
            errorText: _tooLong ? labels.tooLong : null,
            counterText: widget.maxLength == null
                ? null
                : '${_controller.text.length}/${widget.maxLength}',
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            _ToolbarButton(
              icon: Icons.undo,
              label: labels.undo,
              onPressed: _undoStack.isEmpty ? null : _undo,
            ),
            _ToolbarButton(
              icon: Icons.redo,
              label: labels.redo,
              onPressed: _redoStack.isEmpty ? null : _redo,
            ),
            _ToolbarButton(
              icon: Icons.restart_alt,
              label: labels.reset,
              onPressed: _canReset ? _reset : null,
            ),
            if (widget.onCopy != null)
              _ToolbarButton(
                icon: Icons.copy,
                label: labels.copy,
                onPressed: () => widget.onCopy!(_plainText),
              ),
            if (widget.onShare != null)
              _ToolbarButton(
                icon: Icons.share,
                label: labels.share,
                onPressed: () => widget.onShare!(_plainText),
              ),
            if (widget.onSave != null)
              _ToolbarButton(
                icon: Icons.save,
                label: labels.save,
                // Refusing here is what makes the cap non-silent.
                onPressed: _tooLong
                    ? null
                    : () => widget.onSave!(_controller.text),
              ),
            if (widget.onClose != null)
              _ToolbarButton(
                icon: Icons.close,
                label: labels.close,
                onPressed: widget.onClose,
              ),
          ],
        ),
      ],
    );
  }
}

/// An icon button that always carries a label, for accessibility rules 2
/// and 4, and always meets the 48 dp minimum of rule 1.
class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      tooltip: label,
      onPressed: onPressed,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
    );
  }
}
