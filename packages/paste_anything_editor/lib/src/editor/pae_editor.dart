import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:paste_anything/paste_anything.dart';

import '../codec/pae_quill_codec.dart';
import '../math/pae_math_embed.dart';
import '../math/pae_math_dialog.dart';
import '../math/pae_math_keyboard.dart';
import '../math/pae_math_theme.dart';
import 'pae_image_embed.dart';
import 'pae_quill_localizations_scope.dart';
import 'pae_editor_controller.dart';
import 'pae_editor_theme.dart';
import 'pae_quill_controller.dart';
import 'pae_table_embed.dart';

/// Shows a copy/paste result to the user (toast, snackbar, ...).
typedef PaeNotifier = void Function(String message, {bool isError});

/// Quill-based rich text editor that loads and saves HTML, with copy/paste
/// that keeps formatting from Word, Excel, Google Docs, Markdown, web pages,
/// math formulas and (optionally) images.
class PaeEditor extends StatefulWidget {
  const PaeEditor({
    super.key,
    required this.controller,
    this.initialText,
    this.hint = 'Type your content here...',
    this.height = 300,
    this.onChanged,
    this.onEditorInitialized,
    this.showContentLabel = true,
    this.contentLabel,
    this.showMathButton = true,
    this.mathInputMode = PaeMathInputMode.keyboard,
    this.onNotify,
    this.embedBuilders = const [],
    this.editorTheme,
    this.editorLabels = const PaeEditorLabels(),
    this.mathTheme,
    this.mathLabels = const PaeMathLabels(),
  });

  final PaeEditorController controller;
  final String? initialText;
  final String hint;
  final double height;

  /// Called with the document as HTML after every change.
  final void Function(String?)? onChanged;
  final VoidCallback? onEditorInitialized;

  /// When false, hides the left label (copy/paste row remains).
  final bool showContentLabel;

  /// Overrides [PaeEditorLabels.contentLabel] when non-null.
  final String? contentLabel;

  /// Adds the math symbols & formulas button to the toolbar.
  final bool showMathButton;

  /// What the math button opens: a docked [PaeMathKeyboard] that keeps the
  /// editor focused (default), or a modal [PaeMathDialog].
  final PaeMathInputMode mathInputMode;

  /// Full control over toasts. When set, replaces the default [SnackBar].
  ///
  /// ```dart
  /// onNotify: (msg, {isError = false}) => myToast(msg, error: isError),
  /// ```
  final PaeNotifier? onNotify;

  /// Extra embed builders, checked after the built-in ones.
  final List<EmbedBuilder> embedBuilders;

  /// Editor chrome (border, copy/paste row, snackbar). Falls back to the
  /// app-wide [PaeEditorTheme] extension, then the Material color scheme.
  final PaeEditorTheme? editorTheme;

  /// Toasts, tooltips and the content label.
  final PaeEditorLabels editorLabels;

  /// Colors / shape of the math keyboard and dialog. Falls back to the
  /// app-wide [PaeMathTheme] extension, then the Material color scheme.
  final PaeMathTheme? mathTheme;
  final PaeMathLabels mathLabels;

  @override
  State<PaeEditor> createState() => _PaeEditorState();
}

class _PaeEditorState extends State<PaeEditor> {
  bool _scheduledInit = false;
  final _mathKeyboard = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    widget.controller.quillController.addListener(_emitChange);
    _attachMathFormatGuard(widget.controller);
  }

  @override
  void didUpdateWidget(covariant PaeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.quillController.removeListener(_emitChange);
      _detachMathFormatGuard(oldWidget.controller);
      widget.controller.quillController.addListener(_emitChange);
      _attachMathFormatGuard(widget.controller);
    }
  }

  @override
  void dispose() {
    widget.controller.quillController.removeListener(_emitChange);
    _detachMathFormatGuard(widget.controller);
    super.dispose();
  }

  void _attachMathFormatGuard(PaeEditorController controller) {
    final quill = controller.quillController;
    if (quill is PaeQuillController) {
      quill.onMathFormatBlocked = _onMathFormatBlocked;
    }
  }

  void _detachMathFormatGuard(PaeEditorController controller) {
    final quill = controller.quillController;
    if (quill is PaeQuillController) {
      quill.onMathFormatBlocked = null;
    }
  }

  void _onMathFormatBlocked() {
    _notify(widget.editorLabels.cannotFormatFormula);
  }

  void _emitChange() {
    if (!mounted) return;
    final html = PaeQuillCodec.deltaToHtml(
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
    final t = PaeEditorTheme.resolve(context, widget.editorTheme);
    final bg = isError
        ? t.snackBarErrorBackgroundColor
        : t.snackBarBackgroundColor;
    final fg = isError
        ? t.snackBarErrorForegroundColor
        : t.snackBarForegroundColor;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: fg)),
        backgroundColor: bg,
        duration: t.snackBarDuration ?? const Duration(seconds: 3),
        behavior: t.snackBarBehavior,
        margin: t.snackBarMargin,
        padding: t.snackBarPadding,
        shape: t.snackBarShape,
        elevation: t.snackBarElevation,
        width: t.snackBarWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => OverlayPortal(
        controller: _mathKeyboard,
        overlayChildBuilder: _buildMathKeyboard,
        child: PaeQuillLocalizationsScope(child: Builder(builder: _buildEditor)),
      );

  Widget _buildMathKeyboard(BuildContext context) => Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (_, dy, child) => FractionalTranslation(
            translation: Offset(0, dy),
            child: child,
          ),
          child: PaeMathKeyboard(
            theme: widget.mathTheme,
            labels: widget.mathLabels,
            onSymbol: (char) => _insertMath(PaeMathSymbolInsertion(char)),
            onFormula: (latex) => _insertMath(PaeMathFormulaInsertion(latex)),
            onOpenLatexEditor: () => _openMath(formulaOnly: true),
            onClose: _mathKeyboard.hide,
          ),
        ),
      );

  Widget _buildEditor(BuildContext context) {
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

    final et = PaeEditorTheme.resolve(context, widget.editorTheme);
    final labels = widget.editorLabels;
    final contentLabel = widget.contentLabel ?? labels.contentLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.showContentLabel)
              Text(contentLabel, style: et.contentLabelStyle)
            else
              const SizedBox.shrink(),
            _CopyPasteToolbar(
              theme: et,
              labels: labels,
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
            border: Border.all(
              color: et.borderColor!,
              width: et.borderWidth!,
            ),
            borderRadius: BorderRadius.circular(et.borderRadius!),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: et.toolbarBackgroundColor,
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
                          tooltip: widget.mathLabels.toolbarTooltip,
                          onPressed: _onMathButton,
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
                      const PaeTableEmbedBuilder(),
                      PaeMathEmbedBuilder(
                        dialogTheme: widget.mathTheme,
                        dialogLabels: widget.mathLabels,
                      ),
                      const PaeImageEmbedBuilder(),
                      ...widget.embedBuilders,
                    ],
                    unknownEmbedBuilder: const PaeUnknownEmbedBuilder(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onMathButton() {
    if (widget.mathInputMode == PaeMathInputMode.dialog) {
      _openMath();
      return;
    }
    _mathKeyboard.toggle();
    if (_mathKeyboard.isShowing) _keepEditorFocused();
  }

  Future<void> _openMath({bool formulaOnly = false}) async {
    final result = await PaeMathDialog.show(
      context,
      theme: widget.mathTheme,
      labels: widget.mathLabels,
      showSymbolsTab: !formulaOnly,
    );
    if (result == null || !mounted) return;
    _insertMath(result);
  }

  void _insertMath(PaeMathInsertion insertion) {
    switch (insertion) {
      case PaeMathSymbolInsertion(:final char):
        widget.controller.insertText(char);
      case PaeMathFormulaInsertion(:final latex):
        widget.controller.insertFormula(latex);
    }
    _keepEditorFocused();
  }

  void _keepEditorFocused() {
    final focus = widget.controller.editorFocusNode;
    if (!focus.hasFocus) focus.requestFocus();
  }

  Future<void> _copyWithFormatting() async {
    try {
      final content = await _getEditorContent();
      if (content.isNotEmpty) {
        await PaeEditorController.copyHtml(content);
        _notify(widget.editorLabels.copiedWithFormatting);
      } else {
        _notify(widget.editorLabels.noContentToCopy, isError: true);
      }
    } catch (e) {
      _notify(widget.editorLabels.failedToCopy, isError: true);
    }
  }

  Future<void> _copyAsPlainText() async {
    try {
      final content = await _getEditorContent();
      if (content.isNotEmpty) {
        await Clipboard.setData(
          ClipboardData(text: PaeHtml.toPlainText(content)),
        );
        _notify(widget.editorLabels.copiedAsPlainText);
      } else {
        _notify(widget.editorLabels.noContentToCopy, isError: true);
      }
    } catch (e) {
      _notify(widget.editorLabels.failedToCopy, isError: true);
    }
  }

  Future<void> _pasteWithFormatting() async {
    try {
      if (await widget.controller.pasteFromClipboard()) {
        _notify(widget.editorLabels.pastedWithFormatting);
      } else {
        _notify(widget.editorLabels.nothingToPaste, isError: true);
      }
    } catch (e) {
      _notify(widget.editorLabels.failedToPaste, isError: true);
    }
  }

  Future<void> _pasteAsPlainText() async {
    try {
      final text = await PaeClipboard.readText();
      if (text != null && text.isNotEmpty) {
        widget.controller.insertText(text);
        _notify(widget.editorLabels.pastedAsPlainText);
      } else {
        _notify(widget.editorLabels.nothingToPaste, isError: true);
      }
    } catch (e) {
      _notify(widget.editorLabels.failedToPaste, isError: true);
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
}

class _CopyPasteToolbar extends StatelessWidget {
  const _CopyPasteToolbar({
    required this.theme,
    required this.labels,
    required this.onCopyFormatted,
    required this.onCopyPlain,
    required this.onPasteFormatted,
    required this.onPastePlain,
  });

  final PaeEditorTheme theme;
  final PaeEditorLabels labels;
  final VoidCallback onCopyFormatted;
  final VoidCallback onCopyPlain;
  final VoidCallback onPasteFormatted;
  final VoidCallback onPastePlain;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: t.copyPasteBackgroundColor,
        borderRadius: BorderRadius.circular(t.copyPasteBorderRadius!),
        border: Border.all(color: t.copyPasteBorderColor!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _EditorIconButton(
            icon: Icons.content_copy,
            color: t.copyFormattedColor!,
            tooltip: labels.copyFormattedTooltip,
            onPressed: onCopyFormatted,
          ),
          _EditorIconButton(
            icon: Icons.content_paste,
            color: t.pasteFormattedColor!,
            tooltip: labels.pasteFormattedTooltip,
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
            color: t.copyPlainColor!,
            tooltip: labels.copyPlainTooltip,
            onPressed: onCopyPlain,
          ),
          _EditorIconButton(
            icon: Icons.text_snippet,
            color: t.pastePlainColor!,
            tooltip: labels.pastePlainTooltip,
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
