// flutter_quill marks its clipboard hooks experimental; they are the only way
// to intercept paste, and the range is capped at the next major.
// ignore_for_file: experimental_member_use

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:paste_anything/paste_anything.dart';

import '../codec/pae_quill_codec.dart';
import 'pae_quill_controller.dart';

/// Turns pasted image bytes into the URL stored in the document, e.g. by
/// uploading them. Return null to drop the image.
typedef PaeImagePasteHandler = Future<String?> Function(
  Uint8List bytes,
  String mimeType,
);

/// Controller for [PaeEditor], backed by [QuillController], that loads and
/// saves HTML. Paste decisions come from [PaePaster]; HTML <-> Delta from
/// [PaeQuillCodec].
///
/// Pasted images are dropped unless [allowImagePaste] is true. When allowed,
/// bitmaps go through [onImagePaste] (e.g. upload and return a URL), or are
/// embedded as `data:` URIs when no handler is given.
class PaeEditorController implements PaeTarget {
  PaeEditorController({
    this.allowImagePaste = false,
    this.onImagePaste,
  }) {
    quillController = PaeQuillController(
      document: Document(),
      selection: const TextSelection.collapsed(offset: 0),
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
  final PaeImagePasteHandler? onImagePaste;

  late final QuillController quillController;
  late final FocusNode editorFocusNode;
  late final ScrollController scrollController;

  PaePaster get _paster => PaePaster(allowImages: allowImagePaste);

  Future<String> getText() async {
    return PaeQuillCodec.deltaToHtml(quillController.document.toDelta());
  }

  void setText(String html) {
    final t = html.trim();
    if (t.isEmpty) {
      quillController.document = Document();
      return;
    }
    quillController.document =
        Document.fromDelta(PaeQuillCodec.htmlToDelta(t));
  }

  Future<String> getSelectedTextWeb() async {
    final sel = quillController.selection;
    if (!sel.isValid) return getText();
    if (sel.isCollapsed) return getText();
    final slice = quillController.document.toDelta().slice(sel.start, sel.end);
    return PaeQuillCodec.deltaToHtml(slice);
  }

  /// Inserts [html] at the cursor. Images are kept unless [keepImages] is
  /// false.
  @override
  void insertHtml(String html, {bool keepImages = true}) {
    final t = html.trim();
    if (t.isEmpty) return;
    _insertDelta(PaeQuillCodec.htmlToDelta(t, keepImages: keepImages));
  }

  void insertMarkdown(String markdown, {bool keepImages = true}) {
    if (markdown.trim().isEmpty) return;
    insertHtml(PaeHtml.fromMarkdown(markdown), keepImages: keepImages);
  }

  /// Inserts an image block embed for [url] (`http(s):` or `data:image/`).
  void insertImageUrl(String url) {
    if (!PaeHtml.isRenderableImageSource(url)) return;
    _insertDelta(
      Delta()
        ..insert({PaeQuillCodec.imageEmbedType: url})
        ..insert('\n'),
    );
  }

  /// Stores [image] via [onImagePaste], or as a `data:` URI, and inserts it.
  @override
  Future<void> insertImage(PaeImage image) async {
    final handler = onImagePaste;
    final url = handler != null
        ? await handler(image.bytes, image.mimeType)
        : image.toDataUri();
    if (url == null || url.isEmpty) return;
    insertImageUrl(url);
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

  /// Rich paste from the system clipboard, decided by [PaePaster].
  /// Returns false only to let Quill paste its own internal copy (which keeps
  /// the Delta) or report that nothing was pasted.
  Future<bool> _handleClipboardPaste() async {
    var clip = await PaeClipboard.read();
    if (!clip.isAvailable) {
      final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
      clip = PaeClip(text: text);
    }

    final content = _paster.resolve(clip);
    final quillOwnCopy = switch (content) {
      PaeTextContent(:final text) =>
        clip.html == null && text == quillController.pastePlainText,
      PaeEmptyContent() => clip.html == null && clip.image == null,
      _ => false,
    };
    if (quillOwnCopy) {
      // Quill re-reads the clipboard with readText(), which the browser
      // rejects until the page has focus back from the permission prompt.
      await PaeClipboard.waitForFocus();
      return false;
    }

    switch (content) {
      case PaeHtmlContent(:final html):
        insertHtml(html);
      case PaeTextContent(:final text):
        insertText(text);
      case PaeImageContent(:final image):
        await insertImage(image);
      case PaeEmptyContent():
        break;
    }
    return true;
  }

  /// Same behaviour as Ctrl/Cmd+V in the editor.
  Future<bool> pasteFromClipboard() => quillController.clipboardPaste();

  /// Copies [html] as rich content plus its source as plain text.
  static Future<void> copyHtml(String html) async {
    if (await PaeClipboard.writeHtml(html)) return;
    await Clipboard.setData(ClipboardData(text: html));
  }

  @override
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

  /// Inserts [latex] as a formula embed at the cursor.
  ///
  /// Display mode is taken from [display], or inferred from `$$…$$` / `\[…\]`
  /// delimiters when [display] is null.
  void insertFormula(String latex, {bool? display}) {
    final snippet = PaeMath.parseSnippet(latex, display: display);
    if (snippet.latex.isEmpty) return;
    final sel = quillController.selection;
    final start = sel.isValid ? sel.start : 0;
    final end = sel.isValid ? sel.end : 0;
    quillController.replaceText(
      start,
      end - start,
      Embeddable(PaeQuillCodec.mathEmbedType, snippet.toEmbedValue()),
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
