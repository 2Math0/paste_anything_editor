// flutter_quill marks its clipboard hooks experimental; they are the only way
// to intercept paste, and the range is capped at the next major.
// ignore_for_file: experimental_member_use

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';

import '../clipboard/rich_clipboard.dart';
import '../codec/rich_html_codec.dart';
import '../math/math_codec.dart';

/// Turns pasted image bytes into the URL stored in the document, e.g. by
/// uploading them. Return null to drop the image.
typedef ImagePasteHandler = Future<String?> Function(
  Uint8List bytes,
  String mimeType,
);

/// Rich-text editor controller backed by [QuillController] that loads and
/// saves HTML. All HTML / Markdown conversion lives in [RichHtmlCodec].
///
/// Pasted images are dropped unless [allowImagePaste] is true. When allowed,
/// bitmaps go through [onImagePaste] (e.g. upload and return a URL), or are
/// embedded as `data:` URIs when no handler is given.
class RichHtmlEditorController {
  RichHtmlEditorController({
    this.allowImagePaste = false,
    this.onImagePaste,
  }) {
    quillController = QuillController.basic(
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          onClipboardPaste: _handleClipboardPaste,
          enableExternalRichPaste: false,
        ),
      ),
    );
    editorFocusNode = FocusNode();
    scrollController = ScrollController();
  }

  final bool allowImagePaste;
  final ImagePasteHandler? onImagePaste;

  late final QuillController quillController;
  late final FocusNode editorFocusNode;
  late final ScrollController scrollController;

  Future<String> getText() async {
    return RichHtmlCodec.deltaToHtml(quillController.document.toDelta());
  }

  void setText(String html) {
    final t = html.trim();
    if (t.isEmpty) {
      quillController.document = Document();
      return;
    }
    quillController.document =
        Document.fromDelta(RichHtmlCodec.htmlToDelta(t));
  }

  Future<String> getSelectedTextWeb() async {
    final sel = quillController.selection;
    if (!sel.isValid) return getText();
    if (sel.isCollapsed) return getText();
    final slice = quillController.document.toDelta().slice(sel.start, sel.end);
    return RichHtmlCodec.deltaToHtml(slice);
  }

  /// Inserts [html] at the cursor. Images are kept unless [keepImages] is
  /// false.
  void insertHtml(String html, {bool keepImages = true}) {
    final t = html.trim();
    if (t.isEmpty) return;
    _insertDelta(RichHtmlCodec.htmlToDelta(t, keepImages: keepImages));
  }

  void insertMarkdown(String markdown, {bool keepImages = true}) {
    if (markdown.trim().isEmpty) return;
    insertHtml(RichHtmlCodec.markdownToHtml(markdown), keepImages: keepImages);
  }

  /// Inserts an image block embed for [url] (`http(s):` or `data:image/`).
  void insertImage(String url) {
    if (!RichHtmlCodec.isRenderableImageSource(url)) return;
    _insertDelta(
      Delta()
        ..insert({RichHtmlCodec.imageEmbedType: url})
        ..insert('\n'),
    );
  }

  /// Stores [bytes] via [onImagePaste], or as a `data:` URI, and inserts it.
  Future<void> insertImageBytes(Uint8List bytes, String mimeType) async {
    final handler = onImagePaste;
    final url = handler != null
        ? await handler(bytes, mimeType)
        : 'data:$mimeType;base64,${base64Encode(bytes)}';
    if (url == null || url.isEmpty) return;
    insertImage(url);
  }

  void _insertDelta(Delta delta) {
    final sel = quillController.selection;
    final start = sel.isValid ? sel.start : 0;
    final end = sel.isValid ? sel.end : 0;
    final text = quillController.plainTextEditingValue.text;
    final atLineStart =
        start == 0 || start > text.length || text[start - 1] == '\n';
    final first = delta.isEmpty ? null : delta.first.data;
    final toInsert = !atLineStart && first is Map
        ? (Delta()..insert('\n')).concat(delta)
        : delta;
    quillController.replaceText(
      start,
      end - start,
      toInsert,
      TextSelection.collapsed(offset: start + toInsert.length),
    );
  }

  /// Rich paste from the system clipboard: images, HTML (Word, Excel, Google
  /// Docs, web pages), or plain text that is HTML source, LaTeX or Markdown.
  /// Returns false only to let Quill paste its own internal copy (which keeps
  /// the Delta) or report that nothing was pasted.
  Future<bool> _handleClipboardPaste() async {
    final clip = await readClipboard();
    final plain = clip.isAvailable
        ? clip.text
        : (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    final html = (clip.html?.trim().isEmpty ?? true) ? null : clip.html!;
    final image = clip.image;

    if (image != null &&
        (html == null || !RichHtmlCodec.hasVisibleContent(html))) {
      if (allowImagePaste) await insertImageBytes(image.bytes, image.mimeType);
      return true;
    }

    if (html != null) {
      if (!RichHtmlCodec.hasVisibleContent(html, countImages: allowImagePaste)) {
        return true;
      }
      if (plain == null || !RichHtmlCodec.isCodeEditorHtml(html)) {
        insertHtml(html, keepImages: allowImagePaste);
        return true;
      }
      if (_pasteSourceText(plain)) return true;
      insertText(plain);
      return true;
    }

    if (plain == null || plain.isEmpty || plain == quillController.pastePlainText) {
      // Quill re-reads the clipboard with readText(), which the browser
      // rejects until the page has focus back from the permission prompt.
      await waitForDocumentFocus();
      return false;
    }
    if (!_pasteSourceText(plain)) insertText(plain);
    return true;
  }

  bool _pasteSourceText(String text) {
    if (RichHtmlCodec.looksLikeHtml(text)) {
      insertHtml(text, keepImages: allowImagePaste);
      return true;
    }
    if (MathCodec.containsLatex(text) &&
        !RichHtmlCodec.looksLikeMarkdown(text)) {
      insertHtml(MathCodec.plainTextToHtml(text));
      return true;
    }
    if (RichHtmlCodec.looksLikeMarkdown(text)) {
      insertMarkdown(text, keepImages: allowImagePaste);
      return true;
    }
    return false;
  }

  /// Same behaviour as Ctrl/Cmd+V in the editor.
  Future<bool> pasteFromClipboard() => quillController.clipboardPaste();

  /// Copies [html] as rich content plus its source as plain text.
  static Future<void> copyHtml(String html) async {
    if (await writeClipboardHtml(html, plainText: html)) return;
    await Clipboard.setData(ClipboardData(text: html));
  }

  void insertText(String text) {
    final sel = quillController.selection;
    final start = sel.isValid ? sel.start : 0;
    final end = sel.isValid ? sel.end : 0;
    quillController.replaceText(
      start,
      end - start,
      text,
      TextSelection.collapsed(offset: start + text.length),
    );
  }

  /// Inserts [latex] as an inline formula embed at the cursor.
  void insertFormula(String latex) {
    final value = MathCodec.normalizeLatex(latex);
    if (value.isEmpty) return;
    final sel = quillController.selection;
    final start = sel.isValid ? sel.start : 0;
    final end = sel.isValid ? sel.end : 0;
    quillController.replaceText(
      start,
      end - start,
      Embeddable(MathCodec.embedType, value),
      TextSelection.collapsed(offset: start + 1),
    );
  }

  void clear() {
    quillController.clear();
  }

  void dispose() {
    editorFocusNode.dispose();
    scrollController.dispose();
    quillController.dispose();
  }
}
