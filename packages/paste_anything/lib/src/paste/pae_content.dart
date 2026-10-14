import '../clipboard/pae_clip.dart';

/// What a paste should insert, decided by [PaePaster.resolve].
sealed class PaeContent {
  const PaeContent();
}

/// Clean HTML from [PaeHtml.normalize]: rich clipboard HTML, HTML source
/// text, Markdown, or text with LaTeX.
final class PaeHtmlContent extends PaeContent {
  const PaeHtmlContent(this.html);

  final String html;
}

/// Plain text with nothing to convert.
final class PaeTextContent extends PaeContent {
  const PaeTextContent(this.text);

  final String text;
}

/// A clipboard bitmap (only when images are allowed).
final class PaeImageContent extends PaeContent {
  const PaeImageContent(this.image);

  final PaeImage image;
}

/// Nothing to insert: empty clipboard, markup without content, or an image
/// while images are not allowed.
final class PaeEmptyContent extends PaeContent {
  const PaeEmptyContent();
}
