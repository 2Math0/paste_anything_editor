import 'dart:async';

import '../clipboard/pae_clip.dart';

/// Anything that can receive a paste: implement it on your own editor's
/// controller and call [PaePaster.pasteInto].
abstract interface class PaeTarget {
  /// Inserts clean HTML (see [PaeHtml.normalize]) at the cursor. Formulas
  /// arrive as `<span class="math-tex" data-latex="...">` spans.
  FutureOr<void> insertHtml(String html);

  /// Inserts plain text at the cursor.
  FutureOr<void> insertText(String text);

  /// Inserts a pasted bitmap, e.g. after uploading it or as
  /// [PaeImage.toDataUri]. Only called when images are allowed.
  FutureOr<void> insertImage(PaeImage image);
}
