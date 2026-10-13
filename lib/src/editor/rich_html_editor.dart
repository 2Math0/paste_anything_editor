import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';

import '../codec/rich_html_codec.dart';
import '../math/math_formula_embed.dart';
import '../math/math_input_panel.dart';
import 'image_embed.dart';
import 'rich_html_editor_controller.dart';
import 'table_embed.dart';

/// Shows a copy/paste result to the user (toast, snackbar, ...).
typedef RichEditorNotifier = void Function(String message, {bool isError});

/// Quill-based rich text editor that loads and saves HTML, with copy/paste
/// that keeps formatting from Word, Excel, Google Docs, Markdown, web pages,
/// math formulas and (optionally) images.
class RichHtmlEditor extends StatefulWidget {
  const RichHtmlEditor({
    super.key,
    required this.controller,
    this.initialText,
    this.hint = 'Type your content here...',
    this.height = 300,
    this.onChanged,
    this.onEditorInitialized,
    this.showContentLabel = true,
    this.contentLabel = 'Content',
    this.showMathButton = true,
    this.onNotify,
    this.embedBuilders = const [],
  });

  final RichHtmlEditorController controller;
  final String? initialText;
  final String hint;
  final double height;

  /// Called with the document as HTML after every change.
  final void Function(String?)? onChanged;
  final VoidCallback? onEditorInitialized;

  /// When false, hides the left label (copy/paste row remains).
  final bool showContentLabel;
  final String contentLabel;

  /// Adds the math symbols & formulas button to the toolbar.
  final bool showMathButton;

  /// Copy/paste feedback. Defaults to a [SnackBar].
  final RichEditorNotifier? onNotify;

  /// Extra embed builders, checked after the built-in ones.
  final List<EmbedBuilder> embedBuilders;

  @override
  State<RichHtmlEditor> createState() => _RichHtmlEditorState();
}

class _RichHtmlEditorState extends State<RichHtmlEditor> {
  bool _scheduledInit = false;

  @override
  void initState() {
    super.initState();
    widget.controller.quillController.addListener(_emitChange);
  }

  @override
  void didUpdateWidget(covariant RichHtmlEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.quillController.removeListener(_emitChange);
      widget.controller.quillController.addListener(_emitChange);
    }
  }

  @override
  void dispose() {
    widget.controller.quillController.removeListener(_emitChange);
    super.dispose();
  }

  void _emitChange() {
    if (!mounted) return;
    final html = RichHtmlCodec.deltaToHtml(
      widget.controller.quillController.document.toDelta(),
    );
    widget.onChanged?.call(html);
  }

  void _notify(String message, {bool isError = false}) {
    if (!mounted) return;
    final notify = widget.onNotify;
    if (notify != null) {
      notify(message, isError: isError);
      return;
    }
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

    if (!_scheduledInit) {
      _scheduledInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final initial = widget.initialText;
        if (initial != null && initial.trim().isNotEmpty) {
          c.setText(initial);
        }
        widget.onEditorInitialized?.call();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.showContentLabel)
              Text(
                widget.contentLabel,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              )
            else
              const SizedBox.shrink(),
            _CopyPasteToolbar(
              onCopyFormatted: _copyWithFormatting,
              onCopyPlain: _copyAsPlainText,
              onPasteFormatted: _pasteWithFormatting,
              onPastePlain: _pasteAsPlainText,
            ),
          ],
        ),
        const Divider(height: 8),
        const SizedBox(height: 6),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Colors.grey.shade50,
                child: QuillSimpleToolbar(
                  controller: c.quillController,
                  config: QuillSimpleToolbarConfig(
                    multiRowsDisplay: true,
                    showFontFamily: false,
                    showSearchButton: false,
                    showSubscript: false,
                    showSuperscript: false,
                    showSmallButton: false,
                    showAlignmentButtons: true,
                    customButtons: [
                      if (widget.showMathButton)
                        QuillToolbarCustomButtonOptions(
                          icon: const Icon(Icons.functions),
                          tooltip: 'Math symbols & formulas',
                          onPressed: _openMath,
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: QuillEditor(
                  focusNode: c.editorFocusNode,
                  scrollController: c.scrollController,
                  controller: c.quillController,
                  config: QuillEditorConfig(
                    padding: const EdgeInsets.all(12),
                    placeholder: widget.hint,
                    scrollable: true,
                    autoFocus: false,
                    embedBuilders: [
                      const HtmlTableEmbedBuilder(),
                      const MathFormulaEmbedBuilder(),
                      const RichImageEmbedBuilder(),
                      ...widget.embedBuilders,
                    ],
                    unknownEmbedBuilder: const UnknownEmbedBuilder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _openMath() async {
    final result = await MathInputDialog.show(context);
    if (result == null || !mounted) return;
    switch (result) {
      case MathSymbolInsertion(:final char):
        widget.controller.insertText(char);
      case MathFormulaInsertion(:final latex):
        widget.controller.insertFormula(latex);
    }
    widget.controller.editorFocusNode.requestFocus();
  }

  Future<void> _copyWithFormatting() async {
    try {
      final content = await _getEditorContent();
      if (content.isNotEmpty) {
        await RichHtmlEditorController.copyHtml(content);
        _notify('Copied with formatting');
      } else {
        _notify('No content to copy', isError: true);
      }
    } catch (e) {
      _notify('Failed to copy', isError: true);
    }
  }

  Future<void> _copyAsPlainText() async {
    try {
      final content = await _getEditorContent();
      if (content.isNotEmpty) {
        await Clipboard.setData(
          ClipboardData(text: _stripHtmlTags(content)),
        );
        _notify('Copied as plain text');
      } else {
        _notify('No content to copy', isError: true);
      }
    } catch (e) {
      _notify('Failed to copy', isError: true);
    }
  }

  Future<void> _pasteWithFormatting() async {
    try {
      if (await widget.controller.pasteFromClipboard()) {
        _notify('Pasted with formatting');
      } else {
        _notify('Nothing to paste', isError: true);
      }
    } catch (e) {
      _notify('Failed to paste', isError: true);
    }
  }

  Future<void> _pasteAsPlainText() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text?.isNotEmpty ?? false) {
        widget.controller.insertText(data!.text!);
        _notify('Pasted as plain text');
      } else {
        _notify('Nothing to paste', isError: true);
      }
    } catch (e) {
      _notify('Failed to paste', isError: true);
    }
  }

  Future<String> _getEditorContent() async {
    try {
      final selected = await widget.controller.getSelectedTextWeb();
      if (selected.isNotEmpty) return selected;
      return await widget.controller.getText();
    } catch (e) {
      debugPrint('getEditorContent error: $e');
      return '';
    }
  }

  static final Pattern _htmlTag =
      RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false);
  static final Pattern _whitespace = RegExp(r'\s+');

  String _stripHtmlTags(String html) {
    if (html.isEmpty) return '';
    return html
        .replaceAll(_htmlTag, ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(_whitespace, ' ')
        .trim();
  }
}

class _CopyPasteToolbar extends StatelessWidget {
  const _CopyPasteToolbar({
    required this.onCopyFormatted,
    required this.onCopyPlain,
    required this.onPasteFormatted,
    required this.onPastePlain,
  });

  final VoidCallback onCopyFormatted;
  final VoidCallback onCopyPlain;
  final VoidCallback onPasteFormatted;
  final VoidCallback onPastePlain;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EditorIconButton(
            icon: Icons.content_copy,
            color: Colors.blue,
            tooltip: 'Copy with formatting',
            onPressed: onCopyFormatted,
          ),
          _EditorIconButton(
            icon: Icons.content_paste,
            color: Colors.green,
            tooltip: 'Paste with formatting',
            onPressed: onPasteFormatted,
          ),
          const VerticalDivider(
            width: 16,
            thickness: 1,
            indent: 10,
            endIndent: 10,
          ),
          _EditorIconButton(
            icon: Icons.text_fields,
            color: Colors.orange,
            tooltip: 'Copy as plain text',
            onPressed: onCopyPlain,
          ),
          _EditorIconButton(
            icon: Icons.text_snippet,
            color: Colors.purple,
            tooltip: 'Paste as plain text',
            onPressed: onPastePlain,
          ),
        ],
      ),
    );
  }
}

class _EditorIconButton extends StatelessWidget {
  const _EditorIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      preferBelow: false,
      padding: const EdgeInsets.all(8),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
