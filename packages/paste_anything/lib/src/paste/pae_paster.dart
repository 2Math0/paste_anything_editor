import '../clipboard/pae_clip.dart';
import '../clipboard/pae_clipboard.dart';
import '../html/pae_html.dart';
import '../math/pae_math.dart';
import 'pae_content.dart';
import 'pae_target.dart';

/// Decides what a paste should insert and hands it to a [PaeTarget].
///
/// Priority: a bitmap with no other content, then rich HTML (except code
/// editor HTML, which is pasted as its text), then text that is HTML source,
/// LaTeX or Markdown, then plain text.
class PaePaster {
  const PaePaster({this.allowImages = false});

  /// Keeps pasted bitmaps and `<img>` in pasted HTML. Off by default.
  final bool allowImages;

  /// Reads the clipboard (or uses [clip]), resolves it and inserts the
  /// result into [target]. Returns what was inserted.
  Future<PaeContent> pasteInto(PaeTarget target, {PaeClip? clip}) async {
    final content = resolve(clip ?? await PaeClipboard.read());
    switch (content) {
      case PaeHtmlContent(:final html):
        await target.insertHtml(html);
      case PaeTextContent(:final text):
        await target.insertText(text);
      case PaeImageContent(:final image):
        await target.insertImage(image);
      case PaeEmptyContent():
        break;
    }
    return content;
  }

  /// What pasting [clip] should insert.
  PaeContent resolve(PaeClip clip) {
    final html = (clip.html?.trim().isEmpty ?? true) ? null : clip.html!;
    final plain = clip.text;
    final image = clip.image;

    if (image != null &&
        (html == null || !PaeHtml.hasVisibleContent(html))) {
      return allowImages ? PaeImageContent(image) : const PaeEmptyContent();
    }

    if (html != null) {
      if (!PaeHtml.hasVisibleContent(html, countImages: allowImages)) {
        return const PaeEmptyContent();
      }
      if (plain == null || !PaeHtml.isCodeEditorHtml(html)) {
        return PaeHtmlContent(PaeHtml.normalize(html, keepImages: allowImages));
      }
      return resolveText(plain);
    }

    if (plain == null || plain.isEmpty) return const PaeEmptyContent();
    return resolveText(plain);
  }

  /// What pasting plain [text] should insert: HTML source, LaTeX and
  /// Markdown become [PaeHtmlContent], anything else [PaeTextContent].
  PaeContent resolveText(String text) {
    if (text.isEmpty) return const PaeEmptyContent();
    if (PaeHtml.looksLikeHtml(text)) {
      return PaeHtmlContent(PaeHtml.normalize(text, keepImages: allowImages));
    }
    final markdown = PaeHtml.looksLikeMarkdown(text);
    if (PaeMath.containsLatex(text) && !markdown) {
      return PaeHtmlContent(PaeHtml.fromPlainText(text));
    }
    if (markdown) {
      return PaeHtmlContent(
        PaeHtml.normalize(PaeHtml.fromMarkdown(text), keepImages: allowImages),
      );
    }
    return PaeTextContent(text);
  }
}
